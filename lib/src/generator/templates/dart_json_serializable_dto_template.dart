import 'package:collection/collection.dart';
import 'package:openapi_retrofit_generator/src/parser/model/normalized_identifier.dart';
import 'package:openapi_retrofit_generator/src/parser/openapi_parser_core.dart';
import 'package:openapi_retrofit_generator/src/utils/base_utils.dart';
import 'package:openapi_retrofit_generator/src/utils/type_utils.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
  required bool includeIfNull,
  String? fallbackUnion,
  DartImportPathResolver? importPathResolver,
}) {
  final originalClassName = dataClass.name.toPascal;

  // Check if this is a union type
  final isUnion =
      dataClass.discriminator != null ||
      (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false);

  final className = originalClassName;
  final classNameSnake = className.toSnake;

  if (isUnion) {
    return _generateUnionTemplate(
      dataClass,
      className,
      includeIfNull,
      fallbackUnion,
      importPathResolver,
    );
  }

  final base64Types = _getBase64FieldTypes(dataClass.parameters);
  final needsBase64Converter =
      base64Types.hasScalar ||
      base64Types.hasNullable ||
      base64Types.hasList ||
      base64Types.hasListNullable;
  final base64ConverterClass = needsBase64Converter
      ? '\n${_base64ConverterClass(hasScalar: base64Types.hasScalar, hasNullable: base64Types.hasNullable, hasList: base64Types.hasList, hasListNullable: base64Types.hasListNullable)}'
      : '';
  final dartCoreImports = _getDartCoreImports(dataClass.parameters);

  return '''
import 'package:json_annotation/json_annotation.dart';
$dartCoreImports${dartImports(imports: _filterUnionImportsForNonUnion(dataClass), importPathResolver: importPathResolver)}
part '$classNameSnake.g.dart';

${descriptionComment(dataClass.description)}@JsonSerializable()
class $className {
  const $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(dataClass.parameters, includeIfNull)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, Object?> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters, includeIfNull)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, Object?> toJson() => _\$${className}ToJson(this);
}
$base64ConverterClass''';
}

String _generateUnionTemplate(
  UniversalComponentClass dataClass,
  String className,

  bool includeIfNull,
  String? fallbackUnion,
  DartImportPathResolver? importPathResolver,
) {
  // Check if this is a discriminated union
  if (dataClass.discriminator != null) {
    return _generateDiscriminatedUnionTemplate(
      dataClass,
      className,
      includeIfNull,
      fallbackUnion,
      importPathResolver,
    );
  }

  // Handle undiscriminated unions
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    return _generateUndiscriminatedUnionTemplate(
      dataClass,
      className,
      includeIfNull,
      fallbackUnion,
      importPathResolver,
    );
  }

  // Fallback to simple map wrapper for unknown union types
  return _generateSimpleMapWrapper(dataClass, className, importPathResolver);
}

String _generateDiscriminatedUnionTemplate(
  UniversalComponentClass dataClass,
  String className,

  bool includeIfNull,
  String? fallbackUnion,
  DartImportPathResolver? importPathResolver,
) {
  final discriminator = dataClass.discriminator!;

  // Generate sealed base class
  final baseClass =
      '''
@JsonSerializable(createFactory: false)
sealed class $className {
  const $className();
  
  factory $className.fromJson(Map<String, dynamic> json) =>
      ${_deserializerExtensionName(className)}.tryDeserialize(json);
  
  Map<String, dynamic> toJson();
}''';

  // Collect additional imports from wrapper class properties
  final collectedImports = <String>{};

  // Generate wrapper classes first (they are referenced by the extension)
  final wrappers = _generateDiscriminatedWrapperClasses(
    className,
    discriminator,
    includeIfNull,
    fallbackUnion,
    collectedImports,
  );

  // Generate public extension-based deserializer
  final deserializerExtension = _generateDiscriminatorExtension(
    className,
    discriminator,
    fallbackUnion,
  );

  // Merge collected imports with base imports
  final allImports = {
    ..._importsForDiscriminatedUnion(dataClass, fallbackUnion),
    ...collectedImports,
  };

  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: allImports, importPathResolver: importPathResolver)}

part '${className.toSnake}.g.dart';

${descriptionComment(dataClass.description)}$baseClass

$deserializerExtension

$wrappers
''';
}

String _generateUndiscriminatedUnionTemplate(
  UniversalComponentClass dataClass,
  String className,
  bool includeIfNull, [
  String? fallbackUnion,
  DartImportPathResolver? importPathResolver,
]) {
  final variants = dataClass.undiscriminatedUnionVariants!;

  // Generate conversion methods
  final conversionMethods = variants.keys
      .map((variantName) {
        final wrapperClassName = '$className${variantName.toPascal}';
        return '''
  $wrapperClassName to${variantName.toPascal}() => $wrapperClassName.fromJson(_json);''';
      })
      .join('\n');

  // Generate base class
  final baseClass =
      '''
class $className {
  final Map<String, dynamic> _json;
  
  const $className(this._json);
  
  factory $className.fromJson(Map<String, dynamic> json) => $className(json);
  
  Map<String, dynamic> toJson() => _json;
  
$conversionMethods
}''';

  // Collect additional imports from wrapper class properties
  final collectedImports = <String>{};

  // Generate wrapper classes
  final wrappers = _generateUndiscriminatedWrapperClasses(
    className,
    variants,
    includeIfNull,
    collectedImports,
    fallbackUnion,
  );

  // Merge collected imports with base imports
  final allImports = {
    ..._importsForUndiscriminatedUnion(dataClass),
    ...collectedImports,
  };

  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: allImports, importPathResolver: importPathResolver)}

part '${className.toSnake}.g.dart';

${descriptionComment(dataClass.description)}$baseClass

$wrappers
''';
}

String _generateSimpleMapWrapper(
  UniversalComponentClass dataClass,
  String className,
  DartImportPathResolver? importPathResolver,
) {
  // Generate list of possible variants for documentation
  final variants = <String>[];

  if (dataClass.discriminator != null) {
    variants.addAll(
      dataClass.discriminator!.discriminatorValueToRefMapping.values,
    );
  }

  if (dataClass.undiscriminatedUnionVariants != null) {
    variants.addAll(dataClass.undiscriminatedUnionVariants!.keys);
  }

  final variantsList = variants.isNotEmpty
      ? variants.join(', ')
      : 'multiple possible types';

  final discriminatorComment = dataClass.discriminator != null
      ? "\n  /// Check the '${dataClass.discriminator!.propertyName}' field to determine which variant."
      : '\n  /// Use try-catch or manual inspection to determine the actual type.';

  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _filterUnionImports(dataClass), importPathResolver: importPathResolver)}
part '${className.toSnake}.g.dart';

${descriptionComment(dataClass.description)}@JsonSerializable()
class $className {
  const $className(this.data);
  
  /// Raw JSON data for union type.
  /// This can be one of: $variantsList$discriminatorComment
  final Map<String, dynamic> data;
  
  factory $className.fromJson(Map<String, dynamic> json) => $className(json);
  
  Map<String, dynamic> toJson() => data;
}
''';
}

String _generateDiscriminatorExtension(
  String className,
  Discriminator discriminator,
  String? fallbackUnion,
) {
  final discriminatorKey = discriminator.propertyName;
  final variants = discriminator.discriminatorValueToRefMapping;

  // Build default mapping literal: { WrapperType: 'DiscriminatorValue', ... }
  final mappingEntries = variants.entries
      .map((entry) {
        final discriminatorKey = entry.key;
        final discriminatorValue = entry.key;
        final wrapperClassName = '$className${discriminatorKey.toPascal}';
        return "      $wrapperClassName: '$discriminatorValue',";
      })
      .join('\n');

  // Build switch cases using guarded mapping
  final switchCases = variants.entries
      .map((entry) {
        final discriminatorKey = entry.key;
        final wrapperClassName = '$className${discriminatorKey.toPascal}';
        return '''      _ when value == effective[$wrapperClassName] => $wrapperClassName.fromJson(json),''';
      })
      .join('\n');

  final fallbackCase = (fallbackUnion != null && fallbackUnion.isNotEmpty)
      ? '      _ => $className${fallbackUnion.toPascal}.fromJson(json),'
      : "      _ => throw FormatException('Unknown discriminator value \"\${json[key]}\" for $className'),";

  return '''
extension ${_deserializerExtensionName(className)} on $className {
  static $className tryDeserialize(
    Map<String, dynamic> json, {
    String key = '$discriminatorKey',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
$mappingEntries
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
$switchCases
$fallbackCase
    };
  }
}''';
}

String _generateDiscriminatedWrapperClasses(
  String className,
  Discriminator discriminator,

  bool includeIfNull,
  String? fallbackUnion,
  Set<String> collectedImports,
) {
  final wrappers = discriminator.discriminatorValueToRefMapping.entries
      .map((entry) {
        final discriminatorKey = entry.key;
        final variantName = entry.value;
        final wrapperClassName = '$className${discriminatorKey.toPascal}';
        final properties =
            discriminator.refProperties[variantName] ?? <UniversalType>{};

        // Generate direct properties and collect imports
        // Include @JsonKey annotation when jsonKey differs from name
        final directProperties = properties
            .map((prop) {
              final typeStr = _jsonSerializableSuitableType(prop);
              // Extract type names for imports (handles List<Foo>, Map<String, Bar>, etc.)
              _extractAndAddTypeImports(typeStr, collectedImports);
              return '${_jsonKeyForWrapper(prop)}  final $typeStr ${prop.name};';
            })
            .join('\n');

        // Generate constructor parameters
        final constructorParams = properties
            .map((prop) => '    required this.${prop.name},')
            .join('\n');

        // Handle empty properties case
        final constructorSignature = properties.isEmpty
            ? 'const $wrapperClassName();'
            : '''const $wrapperClassName({
$constructorParams
  });''';

        return '''
@JsonSerializable()
class $wrapperClassName extends $className {
$directProperties

  $constructorSignature
  
  factory $wrapperClassName.fromJson(Map<String, dynamic> json) =>
      _\$${wrapperClassName}FromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _\$${wrapperClassName}ToJson(this);
}''';
      })
      .join('\n');

  // Add fallback wrapper class if configured
  final fallbackWrapper = _generateFallbackWrapper(className, fallbackUnion);

  return wrappers + fallbackWrapper;
}

void _extractAndAddTypeImports(String typeStr, Set<String> imports) {
  // Extract all custom type names from the type string
  // Handles: Foo, List<Foo>, Map<String, Foo>, Foo?, List<Foo>?, etc.
  final customTypePattern = RegExp(r'\b([A-Z][A-Za-z0-9_]*)\b');
  final matches = customTypePattern.allMatches(typeStr);

  for (final match in matches) {
    final typeName = match.group(1)!;
    // Skip Dart built-in types
    if (typeName != 'String' &&
        typeName != 'List' &&
        typeName != 'Map' &&
        typeName != 'Set' &&
        typeName != 'Object') {
      imports.add(typeName);
    }
  }
}

String _generateUndiscriminatedWrapperClasses(
  String className,
  Map<String, Set<UniversalType>> variants,

  bool includeIfNull,
  Set<String> collectedImports, [
  String? fallbackUnion,
]) {
  final wrappers = variants.entries
      .map((entry) {
        final variantName = entry.key;
        final properties = entry.value;
        final wrapperClassName = '$className${variantName.toPascal}';

        // Generate direct properties and collect imports
        // Include @JsonKey annotation when jsonKey differs from name
        final directProperties = properties
            .map((prop) {
              final typeStr = _jsonSerializableSuitableType(prop);
              // Extract type names for imports
              _extractAndAddTypeImports(typeStr, collectedImports);
              return '${_jsonKeyForWrapper(prop)}  final $typeStr ${prop.name};';
            })
            .join('\n');

        // Generate constructor parameters
        final constructorParams = properties
            .map((prop) => '    required this.${prop.name},')
            .join('\n');

        // Handle empty properties case
        final constructorSignature = properties.isEmpty
            ? 'const $wrapperClassName();'
            : '''const $wrapperClassName({
$constructorParams
  });''';

        return '''
@JsonSerializable()
class $wrapperClassName {
$directProperties

  $constructorSignature
  
  factory $wrapperClassName.fromJson(Map<String, dynamic> json) =>
      _\$${wrapperClassName}FromJson(json);
      
  Map<String, dynamic> toJson() => _\$${wrapperClassName}ToJson(this);
}''';
      })
      .join('\n\n');

  return wrappers;
}

String _generateFallbackWrapper(String className, String? fallbackUnion) {
  if (fallbackUnion == null || fallbackUnion.isEmpty) {
    return '';
  }

  final fallbackClassName = '$className${fallbackUnion.toPascal}';

  return '''

@JsonSerializable(createFactory: false)
class $fallbackClassName extends $className {
  final Map<String, dynamic> json;
  
  const $fallbackClassName(this.json);
  
  factory $fallbackClassName.fromJson(Map<String, dynamic> json) => 
      $fallbackClassName(json);
      
  @override
  Map<String, dynamic> toJson() => json;
}''';
}

String _parametersInClass(
  Set<UniversalType> parameters,
  bool includeIfNull,
) => parameters.mapIndexed((i, e) {
  // Filter out auto-generated descriptions (normalization messages, conflict resolutions, etc.)
  final shouldShowDescription =
      e.description != null &&
      !e.description!.contains('Normalized from:') &&
      !e.description!.contains('The name has been replaced') &&
      !e.description!.contains('Name not received') &&
      !e.description!.contains('Incorrect name has been replaced');

  final description = shouldShowDescription ? e.description : null;

  return '\n${descriptionComment(description, tab: '  ')}'
      '${_jsonKey(e, includeIfNull)}  final ${_jsonSerializableSuitableType(e)} ${e.name};';
}).join();

String _jsonSerializableSuitableType(UniversalType type) {
  var result = type.toSuitableType();

  if (!type.isRequired &&
      type.defaultValue == null &&
      !result.endsWith('?') &&
      !result.contains('dynamic')) {
    result = '$result?';
  }

  return result;
}

String _parametersInConstructor(
  Set<UniversalType> parameters,
  bool includeIfNull,
) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .map((e) => '\n    ${_required(e)}this.${e.name}${_defaultValue(e)},')
      .join();
}

/// Simplified JsonKey for wrapper classes - only handles name mapping
String _jsonKeyForWrapper(UniversalType t) {
  if (t.jsonKey != null && t.name != t.jsonKey) {
    return "  @JsonKey(name: '${protectJsonKey(t.jsonKey)}')\n";
  }
  return '';
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t, bool includeIfNull) {
  final buffer = StringBuffer();

  final jsonKeyParams = <String, String?>{};

  if (includeIfNull) {
    if (t.isRequired && (t.nullable || t.referencedNullable)) {
      jsonKeyParams['includeIfNull'] = 'true';
    } else if (!t.isRequired && (t.nullable || t.referencedNullable)) {
      jsonKeyParams['includeIfNull'] = 'false';
    }
  }

  if (t.jsonKey != null && t.name != t.jsonKey) {
    jsonKeyParams['name'] = "'${protectJsonKey(t.jsonKey)}'";
  }

  if ((t.format == 'binary' || t.format == 'byte') || t.type == 'Uint8List') {
    final isNullable = !t.isRequired && t.defaultValue == null;
    final isList =
        t.wrappingCollections.isNotEmpty &&
        t.wrappingCollections.first.collectionPrefix.startsWith('List<');

    if (isList) {
      if (isNullable) {
        jsonKeyParams['fromJson'] =
            '_Base64Converter.staticFromJsonListNullable';
        jsonKeyParams['toJson'] = '_Base64Converter.staticToJsonListNullable';
      } else {
        jsonKeyParams['fromJson'] = '_Base64Converter.staticFromJsonList';
        jsonKeyParams['toJson'] = '_Base64Converter.staticToJsonList';
      }
    } else {
      if (isNullable) {
        jsonKeyParams['fromJson'] = '_Base64Converter.staticFromJsonNullable';
        jsonKeyParams['toJson'] = '_Base64Converter.staticToJsonNullable';
      } else {
        jsonKeyParams['fromJson'] = '_Base64Converter.staticFromJson';
        jsonKeyParams['toJson'] = '_Base64Converter.staticToJson';
      }
    }
  }

  if (jsonKeyParams.isNotEmpty) {
    buffer.write(
      "  @JsonKey(${jsonKeyParams.entries.map((e) => '${e.key}: ${e.value}').join(',')})\n",
    );
  }

  return buffer.toString();
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
      return ' = const [$values]';
    }
    return ' = ${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}';
  }

  return ' = '
      '${t.wrappingCollections.isNotEmpty ? 'const ' : ''}'
      '${protectDefaultValue(t.defaultValue, type: t.type)}';
}

/// Filters imports for json_serializable union files
///
/// Exclude all imports since wrapper classes no longer implement variant interfaces.
/// Property type imports will be collected separately by _extractAndAddTypeImports.
Set<String> _filterUnionImports(UniversalComponentClass dataClass) {
  // Return empty set - all necessary imports will be collected from property types
  return {};
}

/// Imports for discriminated unions: only include types used in variant properties.
/// Since wrapper classes no longer implement variant interfaces, we don't need those imports.
Set<String> _importsForDiscriminatedUnion(
  UniversalComponentClass dataClass,
  String? fallbackUnion,
) {
  // Start with empty set - imports will be collected from property types during wrapper generation
  return {};
}

/// Imports for undiscriminated unions: only include types used in variant properties.
/// Since wrapper classes no longer implement variant interfaces, we don't need those imports.
Set<String> _importsForUndiscriminatedUnion(UniversalComponentClass dataClass) {
  // Start with empty set - imports will be collected from property types during wrapper generation
  return {};
}

/// Filters out union imports for regular (non-union) classes
Set<String> _filterUnionImportsForNonUnion(UniversalComponentClass dataClass) {
  final filteredImports = <String>{};

  // If this class has a discriminatorValue, it means it's part of a union and
  // shouldn't import the union file (to avoid circular dependencies)
  final shouldFilterUnionImports = dataClass.discriminatorValue != null;

  for (final import in dataClass.imports) {
    // If this is a model that's part of a union, skip union imports
    // Otherwise, allow all imports (including union imports for classes that use unions)
    final shouldSkip =
        shouldFilterUnionImports && import.toLowerCase().contains('union');

    if (!shouldSkip) {
      filteredImports.add(import);
    }
  }

  return filteredImports;
}

String _deserializerExtensionName(String className) =>
    className.endsWith('Union')
    ? '${className}Deserializer'
    : '${className}UnionDeserializer';

({bool hasScalar, bool hasNullable, bool hasList, bool hasListNullable})
_getBase64FieldTypes(Set<UniversalType> parameters) {
  bool hasScalar = false;
  bool hasNullable = false;
  bool hasList = false;
  bool hasListNullable = false;

  for (final param in parameters) {
    if ((param.format == 'binary' || param.format == 'byte') ||
        param.type == 'Uint8List') {
      final isNullable = !param.isRequired && param.defaultValue == null;
      final isList =
          param.wrappingCollections.isNotEmpty &&
          param.wrappingCollections.first.collectionPrefix.startsWith('List<');

      if (isList) {
        if (isNullable) {
          hasListNullable = true;
        } else {
          hasList = true;
        }
      } else {
        if (isNullable) {
          hasNullable = true;
        } else {
          hasScalar = true;
        }
      }
    }
  }

  return (
    hasScalar: hasScalar,
    hasNullable: hasNullable,
    hasList: hasList,
    hasListNullable: hasListNullable,
  );
}

String _getDartCoreImports(Set<UniversalType> parameters) {
  final imports = <String>[];

  final base64Types = _getBase64FieldTypes(parameters);
  final hasAnyBase64 =
      base64Types.hasScalar ||
      base64Types.hasNullable ||
      base64Types.hasList ||
      base64Types.hasListNullable;

  if (hasAnyBase64) {
    imports.add("import 'dart:convert';");
    imports.add("import 'dart:typed_data';");
  }

  return imports.isEmpty ? '' : '${imports.join('\n')}\n';
}

String _base64ConverterClass({
  required bool hasScalar,
  required bool hasNullable,
  required bool hasList,
  required bool hasListNullable,
}) {
  final methods = <String>[];

  methods.add('  const _Base64Converter();');
  methods.add('');
  methods.add('  static const instance = _Base64Converter();');

  if (hasScalar) {
    methods.add('');
    methods.add(
      '  static Uint8List staticFromJson(String json) => instance.fromJson(json);',
    );
    methods.add('');
    methods.add(
      '  static String staticToJson(Uint8List object) => instance.toJson(object);',
    );
  }

  if (hasNullable) {
    methods.add('');
    methods.add(
      '  static Uint8List? staticFromJsonNullable(String? json) => json == null ? null : instance.fromJson(json);',
    );
    methods.add('');
    methods.add(
      '  static String? staticToJsonNullable(Uint8List? object) => object == null ? null : instance.toJson(object);',
    );
  }

  if (hasList) {
    methods.add('');
    methods.add(
      '  static List<Uint8List> staticFromJsonList(List<dynamic> json) => json.map((e) => instance.fromJson(e as String)).toList();',
    );
    methods.add('');
    methods.add(
      '  static List<String> staticToJsonList(List<Uint8List> object) => object.map((e) => instance.toJson(e)).toList();',
    );
  }

  if (hasListNullable) {
    methods.add('');
    methods.add(
      '  static List<Uint8List>? staticFromJsonListNullable(List<dynamic>? json) => json?.map((e) => instance.fromJson(e as String)).toList();',
    );
    methods.add('');
    methods.add(
      '  static List<String>? staticToJsonListNullable(List<Uint8List>? object) => object?.map((e) => instance.toJson(e)).toList();',
    );
  }

  return '''
class _Base64Converter implements JsonConverter<Uint8List, String> {
${methods.join('\n')}

  @override
  Uint8List fromJson(String json) => base64Decode(json);

  @override
  String toJson(Uint8List object) => base64Encode(object);
}''';
}
