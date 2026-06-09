import 'package:openapi_retrofit_generator/openapi_retrofit_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Empty data class', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: {},
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName();
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: {},
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName() = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Imports', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class',
        },
        parameters: {},
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'camel_class.dart';
import 'snake_class.dart';
import 'kebab_class.dart';
import 'pascal_class.dart';
import 'space_class.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName();
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class',
        },
        parameters: {},
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'camel_class.dart';
import 'snake_class.dart';
import 'kebab_class.dart';
import 'pascal_class.dart';
import 'space_class.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName() = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('uses output layout folders for data classes and imports', () async {
      final statusEnum = UniversalEnumClass(
        name: 'Status',
        type: 'string',
        items: {const UniversalEnumItem(name: 'active', jsonKey: 'active')},
      );
      const user = UniversalComponentClass(
        name: 'User',
        imports: {'Status'},
        parameters: {},
      );
      const createUserRequest = UniversalComponentClass(
        name: 'CreateUserRequest',
        imports: {'User', 'Status'},
        parameters: {},
      );
      const userResponse = UniversalComponentClass(
        name: 'UserResponse',
        imports: {'User'},
        parameters: {},
      );
      final dataClasses = [statusEnum, user, createUserRequest, userResponse];
      final fillController = FillController(
        config: const GeneratorConfig(
          name: '',
          outputDirectory: '.',
          outputLayout: OutputLayout(),
        ),
        dataClasses: dataClasses,
      );

      final enumFile = fillController.fillDtoContent(statusEnum);
      final modelFile = fillController.fillDtoContent(user);
      final requestFile = fillController.fillDtoContent(createUserRequest);
      final responseFile = fillController.fillDtoContent(userResponse);

      expect(enumFile.name, equals('enums/status.dart'));
      expect(modelFile.name, equals('models/user.dart'));
      expect(requestFile.name, equals('requests/create_user_request.dart'));
      expect(responseFile.name, equals('responses/user_response.dart'));
      expect(modelFile.content, contains("import '../enums/status.dart';"));
      expect(requestFile.content, contains("import '../models/user.dart';"));
      expect(requestFile.content, contains("import '../enums/status.dart';"));
      expect(responseFile.content, contains("import '../models/user.dart';"));
    });
  });

  group('Parameters', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            name: 'numberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'stringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'boolean',
            name: 'boolType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'object',
            name: 'objectType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'anotherType',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'dart:typed_data';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.intType,
    required this.numberType,
    required this.doubleNumberType,
    required this.floatNumberType,
    required this.stringType,
    required this.binaryStringType,
    required this.dateStringType,
    required this.dateTimeStringType,
    required this.boolType,
    required this.objectType,
    required this.anotherType,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final int intType;
  final num numberType;
  final double doubleNumberType;
  final double floatNumberType;
  final String stringType;
  @JsonKey(fromJson: _Base64Converter.staticFromJson,toJson: _Base64Converter.staticToJson)
  final Uint8List binaryStringType;
  final DateTime dateStringType;
  final DateTime dateTimeStringType;
  final bool boolType;
  final dynamic objectType;
  final Another anotherType;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}

class _Base64Converter implements JsonConverter<Uint8List, String> {
  const _Base64Converter();

  static const instance = _Base64Converter();

  static Uint8List staticFromJson(String json) => instance.fromJson(json);

  static String staticToJson(Uint8List object) => instance.toJson(object);

  @override
  Uint8List fromJson(String json) => base64Decode(json);

  @override
  String toJson(Uint8List object) => base64Encode(object);
}''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            name: 'numberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'stringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'boolean',
            name: 'boolType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'object',
            name: 'objectType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'anotherType',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import 'dart:typed_data';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    required int intType,
    required num numberType,
    required double doubleNumberType,
    required double floatNumberType,
    required String stringType,
    @JsonKey(fromJson: _Base64Converter.staticFromJson,toJson: _Base64Converter.staticToJson)
    required Uint8List binaryStringType,
    required DateTime dateStringType,
    required DateTime dateTimeStringType,
    required bool boolType,
    required dynamic objectType,
    required Another anotherType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}

class _Base64Converter implements JsonConverter<Uint8List, String> {
  const _Base64Converter();

  static const instance = _Base64Converter();

  static Uint8List staticFromJson(String json) => instance.fromJson(json);

  static String staticToJson(Uint8List object) => instance.toJson(object);

  @override
  Uint8List fromJson(String json) => base64Decode(json);

  @override
  String toJson(Uint8List object) => base64Encode(object);
}''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + dart_mappable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            name: 'numberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'stringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'boolean',
            name: 'boolType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'object',
            name: 'objectType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'anotherType',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.dartMappable,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import 'package:dart_mappable/dart_mappable.dart';
import 'dart:convert';
import 'dart:typed_data';

part 'class_name.mapper.dart';

@MappableClass()
class ClassName with ClassNameMappable {

  const ClassName({
    required this.intType,
    required this.numberType,
    required this.doubleNumberType,
    required this.floatNumberType,
    required this.stringType,
    required this.binaryStringType,
    required this.dateStringType,
    required this.dateTimeStringType,
    required this.boolType,
    required this.objectType,
    required this.anotherType,
  });

  final int intType;
  final num numberType;
  final double doubleNumberType;
  final double floatNumberType;
  final String stringType;
  @MappableField(hook: const _Base64Hook())
  final Uint8List binaryStringType;
  final DateTime dateStringType;
  final DateTime dateTimeStringType;
  final bool boolType;
  final dynamic objectType;
  final Another anotherType;

  static ClassName fromJson(Map<String, dynamic> json) => ClassNameMapper.fromJson(json);
}

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
}
''';
      expect(filledContent.content, equalsIgnoringWhitespace(expectedContents));
    });

    test('dart + dart_mappable with custom json key', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'string',
            name: 'imageUrl',
            jsonKey: 'imageURL',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.dartMappable,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import 'package:dart_mappable/dart_mappable.dart';

part 'class_name.mapper.dart';

@MappableClass()
class ClassName with ClassNameMappable {

  const ClassName({
    required this.imageUrl,
  });

  @MappableField(key: 'imageURL')
  final String imageUrl;

  static ClassName fromJson(Map<String, dynamic> json) => ClassNameMapper.fromJson(json);
}
''';
      expect(filledContent.content, equalsIgnoringWhitespace(expectedContents));
    });
  });

  group('Array type', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Another'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'list0',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'list1',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'list5',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'another.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.list0,
    required this.list1,
    required this.list5,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final List<int> list0;
  final List<List<String>> list1;
  final List<List<List<List<List<Another>>>>> list5;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Another'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'list0',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'list1',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'list5',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    required List<int> list0,
    required List<List<String>> list1,
    required List<List<List<List<List<Another>>>>> list5,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('JsonKey name', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            jsonKey: 'int_type',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.intType,
    required this.stringType,
    required this.boolType,
    required this.anotherType,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  @JsonKey(name: 'int_type')
  final int intType;
  final String stringType;
  @JsonKey(name: 'bool-type')
  final bool boolType;
  @JsonKey(name: 'another')
  final Another anotherType;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            jsonKey: 'int_type',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    @JsonKey(name: 'int_type')
    required int intType,
    required String stringType,
    @JsonKey(name: 'bool-type')
    required bool boolType,
    @JsonKey(name: 'another')
    required Another anotherType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('defaultValue', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Haha'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            defaultValue: '1',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
            isRequired: true,
          ),
          const UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            name: 'nullableType',
            defaultValue: '-1.1',
            nullable: true,
            isRequired: true,
          ),
          const UniversalType(
            type: 'Haha',
            name: 'enumType',
            defaultValue: 'HEHE',
            enumType: 'string',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'haha.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    this.intType = 1,
    this.stringType = 'str',
    this.boolType = false,
    this.nullableType = -1.1,
    this.enumType = Haha.hehe,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final int intType;
  final String stringType;
  final bool boolType;
  @JsonKey(includeIfNull: true)
  final num? nullableType;
  final Haha enumType;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Haha'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            defaultValue: '1',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
            isRequired: true,
          ),
          const UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
            isRequired: true,
          ),
          const UniversalType(
            type: 'number',
            name: 'nullableType',
            defaultValue: '-1.1',
            nullable: true,
            isRequired: true,
          ),
          const UniversalType(
            type: 'Haha',
            name: 'enumType',
            defaultValue: 'HEHE',
            enumType: 'string',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'haha.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    @Default(1)
    int intType,
    @Default('str')
    String stringType,
    @Default(false)
    bool boolType,
    @JsonKey(includeIfNull: true)
    @Default(-1.1)
    num? nullableType,
    @Default(Haha.hehe)
    Haha enumType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Required parameters', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Another'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'string',
            wrappingCollections: [UniversalCollections.nullableList],
            name: 'list',
            isRequired: false,
          ),
          const UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'Another',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'anotherList',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'another.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.anotherList,
    this.intType,
    this.list,
    this.another,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final int? intType;
  final List<String>? list;
  @JsonKey(includeIfNull: false)
  final Another? another;
  final List<List<Another>> anotherList;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Another'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'string',
            wrappingCollections: [UniversalCollections.nullableList],
            name: 'list',
            isRequired: false,
          ),
          const UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'Another',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'anotherList',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    required List<List<Another>> anotherList,
    @JsonKey(includeIfNull: false)
    int? intType,
    List<String>? list,
    @JsonKey(includeIfNull: false)
    Another? another,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Put required parameters first', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Another'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intNotRequired',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'integer',
            name: 'intRequired',
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'anotherNotRequired',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'list',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'another.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.intRequired,
    required this.list,
    this.intNotRequired,
    this.anotherNotRequired,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final int? intNotRequired;
  final int intRequired;
  @JsonKey(includeIfNull: false)
  final Another? anotherNotRequired;
  final List<Another> list;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {'Another'},
        parameters: {
          const UniversalType(
            type: 'integer',
            name: 'intNotRequired',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'integer',
            name: 'intRequired',
            isRequired: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'anotherNotRequired',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'Another',
            name: 'list',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    required int intRequired,
    required List<Another> list,
    @JsonKey(includeIfNull: false)
    int? intNotRequired,
    @JsonKey(includeIfNull: false)
    Another? anotherNotRequired,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Enum', () {
    group('dart + json_serializable', () {
      test('without toJson()', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames({
              'itemOne',
              'ItemTwo',
              'item_three',
              'ITEM-FOUR',
              'пятый',
            }),
          ),
          UniversalEnumClass(
            name: 'KeywordsName',
            type: 'string',
            items: UniversalEnumItem.listFromNames({'FALSE', 'for', 'do'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameStringWithLeadingNumbers',
            type: 'string',
            items: UniversalEnumItem.listFromNames({
              '1itemOne',
              '2ItemTwo',
              '3item_three',
              '4ITEM-FOUR',
              '5иллегалчарактер',
              '6 item six',
            }),
          ),
        ];

        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '.',
            unknownEnumValue: false,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }
        const expectedContent0 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1(1),
  @JsonValue(2)
  value2(2),
  @JsonValue(3)
  value3(3);

  const EnumName(this.json);

  final int? json;

  String toJson() => json?.toString() ?? 'null';

  @override
  String toString() => json?.toString() ?? super.toString();
}
''';

        const expectedContent1 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne('itemOne'),
  @JsonValue('ItemTwo')
  itemTwo('ItemTwo'),
  @JsonValue('item_three')
  itemThree('item_three'),
  @JsonValue('ITEM-FOUR')
  itemFour('ITEM-FOUR'),
  /// Incorrect name has been replaced. Original name: `пятый`.
  @JsonValue('пятый')
  undefined0('пятый');

  const EnumNameString(this.json);

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();
}
''';
        const expectedContent2 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum KeywordsName {
  /// The name has been replaced because it contains a keyword. Original name: `FALSE`.
  @JsonValue('FALSE')
  valueFalse('FALSE'),
  /// The name has been replaced because it contains a keyword. Original name: `for`.
  @JsonValue('for')
  valueFor('for'),
  /// The name has been replaced because it contains a keyword. Original name: `do`.
  @JsonValue('do')
  valueDo('do');

  const KeywordsName(this.json);

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();
}
''';

        const expectedContent3 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumNameStringWithLeadingNumbers {
  @JsonValue('1itemOne')
  value1itemOne('1itemOne'),
  @JsonValue('2ItemTwo')
  value2ItemTwo('2ItemTwo'),
  @JsonValue('3item_three')
  value3itemThree('3item_three'),
  @JsonValue('4ITEM-FOUR')
  value4itemFour('4ITEM-FOUR'),
  /// Incorrect name has been replaced. Original name: `5иллегалчарактер`.
  @JsonValue('5иллегалчарактер')
  undefined0('5иллегалчарактер'),
  @JsonValue('6 item six')
  value6ItemSix('6 item six');

  const EnumNameStringWithLeadingNumbers(this.json);

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();
}
''';

        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
        expect(files[2].content, expectedContent2);
        expect(files[3].content, expectedContent3);
      });

      test('with toJson() in enums', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames({
              'itemOne',
              'ItemTwo',
              'item_three',
              'ITEM-FOUR',
            }),
          ),
        ];

        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '.',
            unknownEnumValue: false,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }
        const expectedContent0 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1(1),
  @JsonValue(2)
  value2(2),
  @JsonValue(3)
  value3(3);

  const EnumName(this.json);

  final int? json;

  String toJson() => json?.toString() ?? 'null';

  @override
  String toString() => json?.toString() ?? super.toString();
}
''';

        const expectedContent1 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne('itemOne'),
  @JsonValue('ItemTwo')
  itemTwo('ItemTwo'),
  @JsonValue('item_three')
  itemThree('item_three'),
  @JsonValue('ITEM-FOUR')
  itemFour('ITEM-FOUR');

  const EnumNameString(this.json);

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();
}
''';

        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
      });
    });

    group('dart + freezed', () {
      test('without toJson()', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames({
              'itemOne',
              'ItemTwo',
              'item_three',
              'ITEM-FOUR',
            }),
          ),
          UniversalEnumClass(
            name: 'KeywordsName',
            type: 'string',
            items: UniversalEnumItem.listFromNames({'FALSE', 'for', 'do'}),
          ),
        ];
        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '.',
            jsonSerializer: JsonSerializer.freezed,
            unknownEnumValue: false,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }
        const expectedContent0 = '''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1(1),
  @JsonValue(2)
  value2(2),
  @JsonValue(3)
  value3(3);

  const EnumName(this.json);

  final int? json;

  String toJson() => json?.toString() ?? 'null';

  @override
  String toString() => json?.toString() ?? super.toString();
}
''';

        const expectedContent1 = '''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne('itemOne'),
  @JsonValue('ItemTwo')
  itemTwo('ItemTwo'),
  @JsonValue('item_three')
  itemThree('item_three'),
  @JsonValue('ITEM-FOUR')
  itemFour('ITEM-FOUR');

  const EnumNameString(this.json);

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();
}
''';
        const expectedContent2 = '''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum KeywordsName {
  /// The name has been replaced because it contains a keyword. Original name: `FALSE`.
  @JsonValue('FALSE')
  valueFalse('FALSE'),
  /// The name has been replaced because it contains a keyword. Original name: `for`.
  @JsonValue('for')
  valueFor('for'),
  /// The name has been replaced because it contains a keyword. Original name: `do`.
  @JsonValue('do')
  valueDo('do');

  const KeywordsName(this.json);

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();
}
''';
        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
        expect(files[2].content, expectedContent2);
      });

      test('with toJson()', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames({
              'itemOne',
              'ItemTwo',
              'item_three',
              'ITEM-FOUR',
              'Item five',
            }),
          ),
        ];
        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '.',
            jsonSerializer: JsonSerializer.freezed,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }

        const expectedContent0 = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1(1),
  @JsonValue(2)
  value2(2),
  @JsonValue(3)
  value3(3),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumName(this.json);

  factory EnumName.fromJson(int json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final int? json;

  String toJson() => json?.toString() ?? 'null';

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<EnumName> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
''';

        const expectedContent1 = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne('itemOne'),
  @JsonValue('ItemTwo')
  itemTwo('ItemTwo'),
  @JsonValue('item_three')
  itemThree('item_three'),
  @JsonValue('ITEM-FOUR')
  itemFour('ITEM-FOUR'),
  @JsonValue('Item five')
  itemFive('Item five'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumNameString(this.json);

  factory EnumNameString.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<EnumNameString> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
''';
        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
      });
    });
  });

  group('Enum negative values', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalEnumClass(
        name: 'EnumName',
        type: 'int',
        items: UniversalEnumItem.listFromNames({'-2', '-1', '0', '1'}),
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final file = fillController.fillDtoContent(dataClass);

      const expectedContent = r'''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(-2)
  valueMinus2(-2),
  @JsonValue(-1)
  valueMinus1(-1),
  @JsonValue(0)
  value0(0),
  @JsonValue(1)
  value1(1),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumName(this.json);

  factory EnumName.fromJson(int json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final int? json;

  String toJson() => json?.toString() ?? 'null';

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<EnumName> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
''';

      expect(file.content, expectedContent);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalEnumClass(
        name: 'EnumName',
        type: 'int',
        items: UniversalEnumItem.listFromNames({'-2', '-1', '0', '1'}),
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final file = fillController.fillDtoContent(dataClass);

      const expectedContent = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(-2)
  valueMinus2(-2),
  @JsonValue(-1)
  valueMinus1(-1),
  @JsonValue(0)
  value0(0),
  @JsonValue(1)
  value1(1),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumName(this.json);

  factory EnumName.fromJson(int json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final int? json;

  String toJson() => json?.toString() ?? 'null';

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<EnumName> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
''';

      expect(file.content, expectedContent);
    });
  });

  group('Typedef data class', () {
    test('dart', () async {
      final dataClasses = [
        UniversalComponentClass(
          name: 'Date',
          imports: const {},
          parameters: {
            const UniversalType(
              type: 'string',
              format: 'date',
              isRequired: true,
            ),
          },
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'BooleanList',
          imports: const {},
          parameters: {
            const UniversalType(
              type: 'boolean',
              wrappingCollections: [UniversalCollections.list],
              isRequired: true,
            ),
          },
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'AnotherValue',
          imports: const {'Another'},
          parameters: {const UniversalType(type: 'Another', isRequired: true)},
          typeDef: true,
        ),
      ];
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = '''
typedef Date = DateTime;
''';
      const expectedContent1 = '''
typedef BooleanList = List<bool>;
''';
      const expectedContent2 = '''
import 'another.dart';
export 'another.dart';

typedef AnotherValue = Another;
''';
      expect(files[0].content, expectedContent0);
      expect(files[1].content, expectedContent1);
      expect(files[2].content, expectedContent2);
    });
  });

  group('nullable', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'string',
            wrappingCollections: [
              UniversalCollections.nullableList,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.listNullableItem,
            ],
            name: 'list1',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'list2',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(type: 'string', name: 'list3', isRequired: true),
          const UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'list5',
            isRequired: true,
            nullable: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.list3,
    required this.list5,
    this.list1,
    this.list2,
    this.list4,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final List<List<List<List<String?>>>>? list1;
  @JsonKey(includeIfNull: false)
  final String? list2;
  final String list3;
  @JsonKey(includeIfNull: false)
  final String? list4;
  @JsonKey(includeIfNull: true)
  final String? list5;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        parameters: {
          const UniversalType(
            type: 'string',
            wrappingCollections: [
              UniversalCollections.nullableList,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.listNullableItem,
            ],
            name: 'list1',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'list2',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(type: 'string', name: 'list3', isRequired: true),
          const UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
            nullable: true,
          ),
          const UniversalType(
            type: 'string',
            name: 'list5',
            isRequired: true,
            nullable: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
          includeIfNull: true,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    required String list3,
    @JsonKey(includeIfNull: true)
    required String? list5,
    @JsonKey(includeIfNull: false)
    List<List<List<List<String?>>>>? list1,
    @JsonKey(includeIfNull: false)
    String? list2,
    @JsonKey(includeIfNull: false)
    String? list4,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('description', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        description: 'Test class',
        parameters: {
          const UniversalType(
            type: 'string',
            description: 'Some string',
            name: 'stringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'Default value',
            name: 'defaultType',
            defaultValue: 'str',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'JsonKey here',
            name: 'jsonKeyValue',
            jsonKey: 'json_key_value',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'Mega mind',
            name: 'megaMind',
            jsonKey: 'mega_MIND',
            isRequired: true,
          ),
          const UniversalType(
            type: 'object',
            description: '',
            name: 'emptyDescription',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'List of data\nThis data is a list',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

/// Test class
@JsonSerializable()
class ClassName {
  const ClassName({
    required this.stringType,
    required this.jsonKeyValue,
    required this.megaMind,
    required this.emptyDescription,
    required this.list,
    this.defaultType = 'str',
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  /// Some string
  final String stringType;
  /// Default value
  final String defaultType;
  /// JsonKey here
  @JsonKey(name: 'json_key_value')
  final String jsonKeyValue;
  /// Mega mind
  @JsonKey(name: 'mega_MIND')
  final String megaMind;
  final dynamic emptyDescription;
  /// List of data.
  /// This data is a list.
  final List<String> list;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: const {},
        description: 'Test class',
        parameters: {
          const UniversalType(
            type: 'string',
            description: 'Some string',
            name: 'stringType',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'Default value',
            name: 'defaultType',
            defaultValue: 'str',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'JsonKey here',
            name: 'jsonKeyValue',
            jsonKey: 'json_key_value',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'Mega mind',
            name: 'megaMind',
            jsonKey: 'mega_MIND',
            isRequired: true,
          ),
          const UniversalType(
            type: 'object',
            description: '',
            name: 'emptyDescription',
            isRequired: true,
          ),
          const UniversalType(
            type: 'string',
            description: 'List of data\nThis data is a list',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: true,
          ),
        },
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

/// Test class
@Freezed()
abstract class ClassName with _$ClassName {
  const factory ClassName({
    /// Some string
    required String stringType,
    /// JsonKey here
    @JsonKey(name: 'json_key_value')
    required String jsonKeyValue,
    /// Mega mind
    @JsonKey(name: 'mega_MIND')
    required String megaMind,
    required dynamic emptyDescription,
    /// List of data.
    /// This data is a list.
    required List<String> list,
    /// Default value
    @Default('str')
    String defaultType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Union types', () {
    UniversalComponentClass buildUnionDataClass() => UniversalComponentClass(
      name: 'AnimalUnion',
      imports: const {'cat', 'dog'},
      parameters: const {},
      undiscriminatedUnionVariants: {
        'Cat': {
          const UniversalType(type: 'int', name: 'mewCount', isRequired: true),
        },
        'Dog': {
          const UniversalType(
            type: 'String',
            name: 'barkSound',
            isRequired: true,
          ),
        },
      },
    );

    test('dart_mappable unions use sealed naming', () {
      const controller = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '.',
          jsonSerializer: JsonSerializer.dartMappable,
        ),
      );

      final generated = controller.fillDtoContent(buildUnionDataClass());

      expect(generated.name, 'models/animal_union.dart');

      const expectedContents = r'''
import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'dog.dart';
import 'cat.dart';
import 'dog.dart';

part 'animal_union.mapper.dart';

class AnimalUnion {
  final Map<String, dynamic> _json;

  const AnimalUnion(this._json);

  factory AnimalUnion.fromJson(Map<String, dynamic> json) => AnimalUnion(json);

  Map<String, dynamic> toJson() => _json;

  AnimalUnionCat toCat() => AnimalUnionCatMapper.fromJson(_json);
  AnimalUnionDog toDog() => AnimalUnionDogMapper.fromJson(_json);
}

@MappableClass()
class AnimalUnionCat with AnimalUnionCatMappable {
  final int mewCount;

  const AnimalUnionCat({
    required this.mewCount,
  });
}

@MappableClass()
class AnimalUnionDog with AnimalUnionDogMappable {
  final String barkSound;

  const AnimalUnionDog({
    required this.barkSound,
  });
}
''';
      expect(generated.content, expectedContents);
    });

    test('json_serializable unions use sealed naming', () {
      const controller = FillController(
        config: GeneratorConfig(name: '', outputDirectory: '.'),
      );

      final generated = controller.fillDtoContent(buildUnionDataClass());

      expect(generated.name, 'models/animal_union.dart');

      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';


part 'animal_union.g.dart';

class AnimalUnion {
  final Map<String, dynamic> _json;
  
  const AnimalUnion(this._json);
  
  factory AnimalUnion.fromJson(Map<String, dynamic> json) => AnimalUnion(json);
  
  Map<String, dynamic> toJson() => _json;
  
  AnimalUnionCat toCat() => AnimalUnionCat.fromJson(_json);
  AnimalUnionDog toDog() => AnimalUnionDog.fromJson(_json);
}

@JsonSerializable()
class AnimalUnionCat {
  final int mewCount;

  const AnimalUnionCat({
    required this.mewCount,
  });
  
  factory AnimalUnionCat.fromJson(Map<String, dynamic> json) =>
      _$AnimalUnionCatFromJson(json);
      
  Map<String, dynamic> toJson() => _$AnimalUnionCatToJson(this);
}

@JsonSerializable()
class AnimalUnionDog {
  final String barkSound;

  const AnimalUnionDog({
    required this.barkSound,
  });
  
  factory AnimalUnionDog.fromJson(Map<String, dynamic> json) =>
      _$AnimalUnionDogFromJson(json);
      
  Map<String, dynamic> toJson() => _$AnimalUnionDogToJson(this);
}
''';
      expect(generated.content, expectedContents);
    });
  });
}
