import 'package:collection/collection.dart';
import 'package:openapi_retrofit_generator/src/generator/model/json_serializer.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_import_dto_template.dart';
import 'package:openapi_retrofit_generator/src/parser/model/normalized_identifier.dart';
import 'package:openapi_retrofit_generator/src/parser/openapi_parser_core.dart';
import 'package:openapi_retrofit_generator/src/utils/base_utils.dart';
import 'package:openapi_retrofit_generator/src/utils/type_utils.dart';

String dartDartMappableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
  String? fallbackUnion,
  DartImportPathResolver? importPathResolver,
}) {
  // Use fallback union only if explicitly provided
  // Auto-fallback is disabled to avoid breaking existing tests
  final effectiveFallbackUnion = fallbackUnion;
  final originalClassName = dataClass.name.toPascal;
  final discriminator = dataClass.discriminator;
  final isUndiscriminatedUnion =
      dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false;

  final className = originalClassName;
  final classNameSnake = className.toSnake;

  // Handle undiscriminated unions with wrapper pattern (no MappableClass on base)
  if (isUndiscriminatedUnion) {
    return _generateUndiscriminatedUnionTemplate(
      dataClass,
      className,
      classNameSnake,
      importPathResolver,
    );
  }

  final isUnion = discriminator != null;

  // For dart_mappable, treat discriminated unions with complete mapping
  // to use the wrapper pattern instead of direct inheritance
  final shouldUseWrapperPattern =
      discriminator != null && _isCompleteDiscriminatorMapping(discriminator);

  // For discriminated union variants that should become standalone classes for wrapper pattern
  // We detect this by checking if this is a discriminator variant (has discriminatorValue)
  // and if the discriminator value matches the class name (indicating complete mapping)
  final isDiscriminatorVariant = dataClass.discriminatorValue != null;
  final hasCompleteMapping =
      isDiscriminatorVariant &&
      dataClass.discriminatorValue!.propertyValue == originalClassName;

  final parent = (isDiscriminatorVariant && hasCompleteMapping)
      ? null
      : dataClass.discriminatorValue?.parentClass;

  // Check if this is a simple data class that could be used in unions
  final isSimpleDataClass =
      !isUnion &&
      parent == null &&
      dataClass.parameters.isNotEmpty &&
      dataClass.discriminatorValue == null;

  // Generate additional classes for discriminated unions with complete mapping
  final additionalClasses = shouldUseWrapperPattern
      ? _generateWrapperClasses(dataClass, className, effectiveFallbackUnion)
      : '';

  final needsBase64Converter = _hasBase64Fields(dataClass.parameters);
  final base64ConverterClass = needsBase64Converter
      ? '\n${_base64ConverterClass()}'
      : '';
  final dartCoreImports = _getDartCoreImports(dataClass.parameters);

  return '''
${dartImportDtoTemplate(JsonSerializer.dartMappable)}
$dartCoreImports${dartImports(
    imports: _getAllImports(dataClass, isUnion: isUnion),
    importPathResolver: importPathResolver,
  )}
part '$classNameSnake.mapper.dart';

${descriptionComment(dataClass.description)}@MappableClass(${_getMappableClassAnnotation(dataClass, className, effectiveFallbackUnion)})
${_classModifier(isUnion: isUnion, isUndiscriminatedUnion: false)}class $className ${parent != null ? "extends $parent " : ""}with ${className}Mappable {
${_generateClassBody(dataClass, className, isUnion, isSimpleDataClass, effectiveFallbackUnion)}
}

$additionalClasses$base64ConverterClass''';
}

/// Generate undiscriminated union template with wrapper pattern
/// Generate undiscriminated union template
/// Uses plain class with _json field and conversion methods (no @MappableClass on base)
String _generateUndiscriminatedUnionTemplate(
  UniversalComponentClass dataClass,
  String className,
  String classNameSnake,
  DartImportPathResolver? importPathResolver,
) {
  final variants = dataClass.undiscriminatedUnionVariants!;

  // Generate conversion methods
  final conversionMethods = variants.keys
      .map((variantName) {
        final wrapperClassName = '$className${variantName.toPascal}';
        return '${indentation(2)}$wrapperClassName to${variantName.toPascal}() => ${wrapperClassName}Mapper.fromJson(_json);';
      })
      .join('\n');

  // Generate variant wrapper classes
  final wrapperClasses = _generateVariantWrapperClasses(className, variants);

  return '''
${dartImportDtoTemplate(JsonSerializer.dartMappable)}
${dartImports(imports: _getAllImports(dataClass, isUnion: true), importPathResolver: importPathResolver)}
part '$classNameSnake.mapper.dart';

${descriptionComment(dataClass.description)}class $className {
${indentation(2)}final Map<String, dynamic> _json;

${indentation(2)}const $className(this._json);

${indentation(2)}factory $className.fromJson(Map<String, dynamic> json) => $className(json);

${indentation(2)}Map<String, dynamic> toJson() => _json;

$conversionMethods
}

$wrapperClasses''';
}

/// Generate variant wrapper classes for undiscriminated unions
String _generateVariantWrapperClasses(
  String className,
  Map<String, Set<UniversalType>> variants,
) {
  final wrappersList = <String>[];

  for (final entry in variants.entries) {
    final variantName = entry.key;
    final properties = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';

    // Generate direct properties
    // Include @MappableField annotation only for actual renames (not case conversion)
    final directProperties = properties
        .map(
          (prop) =>
              '${_jsonKey(prop)}${indentation(2)}final ${prop.toSuitableType()} ${prop.name};',
        )
        .join('\n');

    // Generate constructor parameters
    final constructorParams = properties
        .map((prop) => '${indentation(4)}required this.${prop.name},')
        .join('\n');

    // Handle empty properties case
    final constructorSignature = properties.isEmpty
        ? '${indentation(2)}const $wrapperClassName();'
        : '''${indentation(2)}const $wrapperClassName({
$constructorParams
${indentation(2)}});''';

    wrappersList.add('''
@MappableClass()
class $wrapperClassName with ${wrapperClassName}Mappable {
$directProperties

$constructorSignature
}
''');
  }

  return wrappersList.join('\n');
}

String getParameters(UniversalComponentClass dataClass) {
  // if this class has discriminated values, don't populate the discriminator field
  // in the parent class
  final parameters = dataClass.parameters
      .where((it) => it.name != dataClass.discriminator?.propertyName)
      .toList();
  if (parameters.isNotEmpty) {
    return '{\n${_parametersToString(parameters)}\n${indentation(2)}}';
  } else {
    return '';
  }
}

String getFields(
  UniversalComponentClass dataClass, {
  bool isSimpleDataClass = false,
}) {
  // if this class has discriminated values, don't populate the discriminator field
  // in the parent class
  final parameters = dataClass.parameters
      .where((it) => it.name != dataClass.discriminator?.propertyName)
      .toList();
  if (parameters.isNotEmpty) {
    return '${_fieldsToString(parameters)}\n';
  } else {
    return '';
  }
}

String _fieldsToString(List<UniversalType> parameters) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .mapIndexed((i, e) {
        return '${_jsonKey(e)}${indentation(2)}final ${e.toSuitableType()} ${e.name};';
      })
      .join('\n');
}

String _parametersToString(List<UniversalType> parameters) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .mapIndexed(
        (i, e) =>
            '${indentation(4)}${_required(e)}this.${e.name}${getDefaultValue(e)},',
      )
      .join('\n');
}

/// if jsonKey is different from the name, add @MappableField annotation
String _jsonKey(UniversalType t) {
  final params = <String>[];

  if (t.jsonKey != null && t.name != t.jsonKey) {
    params.add("key: '${protectJsonKey(t.jsonKey)}'");
  }

  if ((t.format == 'binary' || t.format == 'byte') && t.type == 'string') {
    params.add('hook: const _Base64Hook()');
  }

  if (params.isEmpty) {
    return '';
  }

  return "${indentation(2)}@MappableField(${params.join(', ')})\n";
}

String getDefaultValue(UniversalType t) {
  if (t.defaultValue == null) {
    return '';
  }
  return ' = ${_defaultValue(t)}';
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) {
  if (t.defaultValue == null) {
    return '';
  }

  final defaultValueStr = t.defaultValue.toString();

  if (t.enumType != null) {
    if (defaultValueStr.startsWith('[') && defaultValueStr.endsWith(']')) {
      final values = defaultValueStr
          .substring(1, defaultValueStr.length - 1)
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .map((v) => '${t.type}.${protectDefaultEnum(v)?.toCamel}')
          .join(', ');
      return 'const [$values]';
    }
    return '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}';
  }

  final protectedValue = protectDefaultValue(t.defaultValue, type: t.type);

  // Add const prefix for collections (arrays/maps) to make them compile-time constants
  if (t.wrappingCollections.isNotEmpty && protectedValue != null) {
    if (protectedValue.startsWith('[') || protectedValue.startsWith('{')) {
      return 'const $protectedValue';
    }
  }

  return '$protectedValue';
}

String _classModifier({
  required bool isUnion,
  bool isUndiscriminatedUnion = false,
}) {
  return isUnion ? 'sealed ' : '';
}

String _generateClassBody(
  UniversalComponentClass dataClass,
  String className,
  bool isUnion,
  bool isSimpleDataClass, [
  String? fallbackUnion,
]) {
  if (!isUnion) {
    // Regular class generation
    return '''
${indentation(2)}const $className(${getParameters(dataClass)});

${getFields(dataClass, isSimpleDataClass: isSimpleDataClass)}
${indentation(2)}static $className fromJson(Map<String, dynamic> json) => ${className}Mapper.fromJson(json);
''';
  }

  // Discriminated unions - dart_mappable handles deserialization via discriminatorKey/discriminatorValue
  return '''
${indentation(2)}const $className();

${indentation(2)}static $className fromJson(Map<String, dynamic> json) => ${className}Mapper.fromJson(json);
''';
}

String _getMappableClassAnnotation(
  UniversalComponentClass dataClass,
  String className,
  String? fallbackUnion,
) {
  // For discriminated unions with complete mapping, use wrapper pattern
  if (dataClass.discriminator != null &&
      _isCompleteDiscriminatorMapping(dataClass.discriminator!)) {
    final subClasses = dataClass
        .discriminator!
        .discriminatorValueToRefMapping
        .keys
        .map((discriminatorKey) => '$className${discriminatorKey.toPascal}')
        .toList();
    if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
      subClasses.add('$className${fallbackUnion.toPascal}');
    }
    final formattedSubClasses = subClasses
        .map((sc) => '${indentation(2)}$sc')
        .join(',\n');
    return [
      "discriminatorKey: '${dataClass.discriminator!.propertyName}'",
      'includeSubClasses: [\n$formattedSubClasses\n]',
    ].join(', ');
  }

  // Original discriminated union logic (for incomplete mappings)
  if (dataClass.discriminator != null) {
    final subClasses = dataClass
        .discriminator!
        .discriminatorValueToRefMapping
        .keys
        .map((discriminatorKey) => '$className${discriminatorKey.toPascal}')
        .toList();
    if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
      subClasses.add('$className${fallbackUnion.toPascal}');
    }
    return [
      "discriminatorKey: '${dataClass.discriminator!.propertyName}'",
      'includeSubClasses: [${subClasses.join(', ')}]',
    ].join(', ');
  }
  // For discriminated union variants that use wrapper pattern, don't include discriminatorValue
  if (dataClass.discriminatorValue != null) {
    // Check if this is a complete mapping case (discriminator value matches class name)
    final isCompleteMapping =
        dataClass.discriminatorValue!.propertyValue == className;
    if (!isCompleteMapping) {
      return "discriminatorValue: '${dataClass.discriminatorValue!.propertyValue}'";
    }
  }
  // Check for undiscriminated unions - use includeSubClasses annotation
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    final subClasses = dataClass.undiscriminatedUnionVariants!.keys
        .map((variantName) => '$className${variantName.toPascal}')
        .toList();
    if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
      subClasses.add('$className${fallbackUnion.toPascal}');
    }
    return 'includeSubClasses: [${subClasses.join(', ')}]';
  }
  return '';
}

Set<String> _getAllImports(
  UniversalComponentClass dataClass, {
  required bool isUnion,
}) {
  final imports = Set<String>.from(dataClass.imports);

  // For undiscriminated unions, add imports for referenced variant classes only
  // Skip synthesized inline variants like variant2, variant4
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    for (final variantName in dataClass.undiscriminatedUnionVariants!.keys) {
      final lower = variantName.toLowerCase();
      final isInline = lower.startsWith('variant');
      final isSelf = variantName == dataClass.name;
      if (!isInline && !isSelf) {
        imports.add(variantName);
      }
    }
  }

  // For discriminated unions with complete mapping, add imports for $ref variants only
  // Inline variants are generated in the same file and don't need imports
  if (dataClass.discriminator != null &&
      _isCompleteDiscriminatorMapping(dataClass.discriminator!)) {
    for (final entry
        in dataClass.discriminator!.discriminatorValueToRefMapping.entries) {
      final variantName = entry.value;
      // Only add import if this variant is NOT in refProperties (meaning it's a $ref, not inline)
      // If it IS in refProperties, it's an inline object that will be generated in this file
      if (!dataClass.discriminator!.refProperties.containsKey(variantName)) {
        imports.add(variantName);
      }
    }
  }

  // Filter out circular imports: if this is a simple model class (not a union),
  // exclude any imports that would reference union classes that contain this model
  final isUnion =
      dataClass.discriminator != null ||
      (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false);

  if (!isUnion) {
    // Remove imports that would create circular dependencies
    // Only remove union imports that aren't actually used by this class

    // Get all the types used by this class parameters
    final usedTypes = dataClass.parameters.map((p) => p.type).toSet();

    imports.removeWhere((import) {
      final isUnionImport = import.toLowerCase().contains('union');
      final isUsedByClass =
          usedTypes.contains(import) ||
          usedTypes.any((type) => type.contains(import));

      // Remove union imports that aren't used by this class
      return isUnionImport && !isUsedByClass;
    });
  }

  return imports;
}

bool _isCompleteDiscriminatorMapping(Discriminator discriminator) {
  // A discriminator mapping is considered "complete" if it has explicit mappings
  // for all variants (as opposed to implicit mappings)
  return discriminator.discriminatorValueToRefMapping.isNotEmpty;
}

String _generateWrapperClasses(
  UniversalComponentClass dataClass,
  String className,
  String? fallbackUnion,
) {
  // Handle discriminated unions with complete mapping using wrapper pattern
  if (dataClass.discriminator != null &&
      _isCompleteDiscriminatorMapping(dataClass.discriminator!)) {
    final wrappers = _generateDiscriminatedWrapperClasses(
      dataClass,
      className,
      fallbackUnion,
    );
    return wrappers;
  }

  return '';
}

String _generateDiscriminatedWrapperClasses(
  UniversalComponentClass dataClass,
  String className,
  String? fallbackUnion,
) {
  final discriminator = dataClass.discriminator!;
  final wrappers = <String>[];

  // Generate wrapper classes for each discriminator variant
  for (final entry in discriminator.discriminatorValueToRefMapping.entries) {
    final discriminatorValue = entry.key; // e.g., "green_apple"
    final variantName = entry.value; // e.g., "Apple"
    final wrapperClassName =
        '$className${discriminatorValue.toPascal}'; // e.g., "FruitGreenApple"

    // Get the variant class properties from the discriminator's refProperties
    final variantProperties =
        discriminator.refProperties[variantName] ?? <UniversalType>[];

    // Include all properties (including discriminator property)
    final filteredProperties = variantProperties;

    // Generate direct properties instead of delegating getters
    // Include @MappableField annotation only for actual renames (not case conversion)
    final directProperties = filteredProperties
        .map(
          (prop) =>
              '${_jsonKey(prop)}${indentation(2)}final ${prop.toSuitableType()} ${prop.name};',
        )
        .join('\n');

    // Generate constructor parameters
    final constructorParams = filteredProperties
        .map((prop) => '${indentation(4)}required this.${prop.name},')
        .join('\n');

    // Handle empty properties case
    final constructorSignature = filteredProperties.isEmpty
        ? '${indentation(2)}const $wrapperClassName();'
        : '''${indentation(2)}const $wrapperClassName({
$constructorParams
${indentation(2)}});''';

    wrappers.add('''
@MappableClass(discriminatorValue: '$discriminatorValue')
class $wrapperClassName extends $className with ${wrapperClassName}Mappable {
$directProperties

$constructorSignature

}''');
  }

  // Add fallback wrapper if specified
  if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
    wrappers.add('''
@MappableClass(discriminatorValue: MappableClass.useAsDefault)
class $className${fallbackUnion.toPascal} extends $className with $className${fallbackUnion.toPascal}Mappable {
${indentation(2)}final Map<String, dynamic> json;

${indentation(2)}const $className${fallbackUnion.toPascal}(this.json);

${indentation(2)}static $className${fallbackUnion.toPascal} fromJson(Map<String, dynamic> json) =>
${indentation(6)}$className${fallbackUnion.toPascal}(json);
}''');
  }

  return wrappers.join('\n');
}

bool _hasBase64Fields(Set<UniversalType> parameters) {
  return parameters.any(
    (param) =>
        (param.format == 'binary' || param.format == 'byte') &&
        param.type == 'string',
  );
}

String _getDartCoreImports(Set<UniversalType> parameters) {
  final imports = <String>[];

  if (_hasBase64Fields(parameters)) {
    imports.add("import 'dart:convert';");
    imports.add("import 'dart:typed_data';");
  }

  return imports.isEmpty ? '' : '${imports.join('\n')}\n';
}

String _base64ConverterClass() {
  return '''
class _Base64Hook extends MappingHook {
  const _Base64Hook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) {
      return base64Decode(value);
    }
    return value;
  }

  @override
  Object? beforeEncode(Object? value) {
    if (value is Uint8List) {
      return base64Encode(value);
    }
    return value;
  }
}''';
}
