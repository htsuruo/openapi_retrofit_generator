import 'package:openapi_retrofit_generator/src/generator/config/generator_config.dart';
import 'package:openapi_retrofit_generator/src/generator/model/generated_file.dart';
import 'package:openapi_retrofit_generator/src/generator/model/json_serializer.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_dart_mappable_dto_template.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_enum_dto_template.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_export_file_template.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_freezed_dto_template.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_json_serializable_dto_template.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_retrofit_client_template.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_root_client_template.dart';
import 'package:openapi_retrofit_generator/src/generator/templates/dart_typedef_template.dart';
import 'package:openapi_retrofit_generator/src/parser/model/normalized_identifier.dart';
import 'package:openapi_retrofit_generator/src/parser/openapi_parser_core.dart';
import 'package:openapi_retrofit_generator/src/utils/base_utils.dart';
import 'package:path/path.dart' as p;

/// Handles generating files
final class FillController {
  /// Constructor that accepts configuration parameters with default values to create files
  const FillController({
    required this.config,
    this.info = const OpenApiInfo(schemaVersion: OAS.v3_1),
    this.dataClasses = const [],
  });

  /// Api info
  final OpenApiInfo info;

  /// Config
  final GeneratorConfig config;

  /// All data classes in this generation run.
  final List<UniversalDataClass> dataClasses;

  /// Return [GeneratedFile] generated from given [UniversalDataClass]
  GeneratedFile fillDtoContent(UniversalDataClass dataClass) {
    final fileName = _resolveDtoFileName(dataClass);
    return GeneratedFile(
      name: fileName,
      content: _dtoFileContent(
        dataClass,
        jsonSerializer: config.jsonSerializer,
        unknownEnumValue: config.unknownEnumValue,
        markFilesAsGenerated: config.markFilesAsGenerated,
        generateValidator: config.generateValidator,
        includeIfNull: config.includeIfNull,
        fallbackUnion: config.fallbackUnion,
        importPathResolver: _importPathResolver(fileName),
      ),
    );
  }

  String _dtoFileContent(
    UniversalDataClass dataClass, {
    required JsonSerializer jsonSerializer,
    required bool unknownEnumValue,
    required bool markFilesAsGenerated,
    required bool generateValidator,
    required bool includeIfNull,
    String? fallbackUnion,
    DartImportPathResolver? importPathResolver,
  }) {
    if (dataClass is UniversalEnumClass) {
      return dartEnumDtoTemplate(
        dataClass,
        jsonSerializer: jsonSerializer,
        unknownEnumValue: unknownEnumValue,
        markFileAsGenerated: markFilesAsGenerated,
      );
    } else if (dataClass is UniversalComponentClass) {
      if (dataClass.typeDef) {
        return dartTypeDefTemplate(
          dataClass,
          jsonSerializer: jsonSerializer,
          importPathResolver: importPathResolver,
        );
      }
      return switch (jsonSerializer) {
        JsonSerializer.freezed => dartFreezedDtoTemplate(
          dataClass,
          generateValidator: generateValidator,
          includeIfNull: includeIfNull,
          fallbackUnion: fallbackUnion,
          importPathResolver: importPathResolver,
        ),
        JsonSerializer.jsonSerializable => dartJsonSerializableDtoTemplate(
          dataClass,
          markFileAsGenerated: markFilesAsGenerated,
          includeIfNull: includeIfNull,
          fallbackUnion: fallbackUnion,
          importPathResolver: importPathResolver,
        ),
        JsonSerializer.dartMappable => dartDartMappableDtoTemplate(
          dataClass,
          markFileAsGenerated: markFilesAsGenerated,
          fallbackUnion: fallbackUnion,
          importPathResolver: importPathResolver,
        ),
      };
    }
    throw ArgumentError('Unknown type exception');
  }

  String _resolveDtoFileName(UniversalDataClass dataClass) =>
      '${_resolveDtoFolderName(dataClass)}/${dataClass.name.toSnake}.dart';

  String _resolveDtoFolderName(UniversalDataClass dataClass) {
    final outputLayout = config.outputLayout;
    if (outputLayout == null) {
      return 'models';
    }

    return switch (_classifyDataClass(dataClass)) {
      'requests' => outputLayout.requests,
      'responses' => outputLayout.responses,
      'enums' => outputLayout.enums,
      _ => outputLayout.models,
    };
  }

  String _classifyDataClass(UniversalDataClass dataClass) {
    final className = dataClass.name.toPascal;
    final override = config.modelClassification.overrides[className];
    if (override != null) {
      return override;
    }
    if (dataClass is UniversalEnumClass) {
      return 'enums';
    }
    if (_endsWithAny(className, config.modelClassification.requestSuffixes)) {
      return 'requests';
    }
    if (_endsWithAny(className, config.modelClassification.responseSuffixes)) {
      return 'responses';
    }
    return 'models';
  }

  bool _endsWithAny(String value, Iterable<String> suffixes) =>
      suffixes.any(value.endsWith);

  DartImportPathResolver _importPathResolver(String fromFileName) {
    final dataClassFileNames = {
      for (final dataClass in dataClasses)
        dataClass.name.toPascal: _resolveDtoFileName(dataClass),
    };

    return (import) {
      final targetFileName =
          dataClassFileNames[import.toPascal] ??
          'models/${import.toSnake}.dart';
      return p.posix.relative(
        targetFileName,
        from: p.posix.dirname(fromFileName),
      );
    };
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRestClientContent(UniversalRestClient restClient) {
    final postfix = config.clientPostfix ?? 'Client';
    final fileName = '${restClient.name}_$postfix'.toSnake;
    final folderName =
        config.outputLayout?.clients ??
        (config.putClientsInFolder ? 'clients' : restClient.name.toSnake);
    final clientFileName = '$folderName/$fileName.dart';

    return GeneratedFile(
      name: clientFileName,
      content: dartRetrofitClientTemplate(
        restClient: restClient,
        name: restClient.name.toPascal + postfix.toPascal,
        defaultContentType: config.defaultContentType,
        jsonSerializer: config.jsonSerializer,
        mergeClients: config.mergeOutputs,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
        fileName: fileName,
        importPathResolver: _importPathResolver(clientFileName),
      ),
    );
  }

  /// Return [GeneratedFile] root client generated from given clients
  GeneratedFile fillRootClient(Iterable<UniversalRestClient> clients) {
    final rootClientName = config.rootClientName ?? 'RestClient';
    final postfix = config.clientPostfix ?? 'Client';
    final clientsNames = clients.map((c) => c.name.toPascal).toSet();
    // Create a map from Pascal names to snake names
    final clientsNameMap = <String, String>{
      for (final client in clients) client.name.toPascal: client.name.toSnake,
    };

    return GeneratedFile(
      name: '${rootClientName.toSnake}.dart',
      content: dartRootClientTemplate(
        openApiInfo: info,
        name: rootClientName,
        clientsNames: clientsNames,
        postfix: postfix.toPascal,
        putClientsInFolder: config.putClientsInFolder,
        markFileAsGenerated: config.markFilesAsGenerated,
        clientsNameMap: clientsNameMap,
        clientFolderName: config.outputLayout?.clients,
      ),
    );
  }

  /// Return [GeneratedFile] with all exports from all files
  GeneratedFile fillExportFile({
    required List<GeneratedFile> restClients,
    required List<GeneratedFile> dataClasses,
    required GeneratedFile? rootClient,
  }) {
    return GeneratedFile(
      name: 'export.dart',
      content: dartExportFileTemplate(
        restClients: restClients,
        dataClasses: dataClasses,
        rootClient: rootClient,
      ),
    );
  }

  GeneratedFile fillMergedOutputs(List<GeneratedFile> outputs) {
    final dartImports = <String>{};
    final packageImports = <String, List<String>>{};
    final lines = <String>[];
    for (final output in outputs) {
      for (final line in output.content.split('\n')) {
        if (line == '') {
          if (lines.isNotEmpty && lines.last != '') {
            lines.add('');
          }
        } else if (line.startsWith('import')) {
          // Separate Dart and package imports in Dart and ignore local imports
          if (line.startsWith("import 'package:")) {
            final packageKey = _extractPackageKey(line);
            final importLine = line;

            final existing = packageImports[packageKey] ?? [];
            if (!existing.contains(importLine)) {
              packageImports.putIfAbsent(packageKey, () => []).add(importLine);
            }
          } else if (line.startsWith("import 'dart:")) {
            dartImports.add(line);
          }
        } else if (line.startsWith('export')) {
          // ignore export lines in Dart (they reference files that are now merged)
        } else if (line.startsWith('part ')) {
          // ignore part lines in Dart
        } else {
          lines.add(line);
        }
      }
    }
    final buffer = StringBuffer(generatedFileComment());

    if (dartImports.isNotEmpty) {
      for (final import in dartImports.toList()..sort()) {
        buffer.writeln(import);
      }
      buffer.writeln();
    }

    if (packageImports.isNotEmpty) {
      final allImports = packageImports.values.expand((list) => list).toList()
        ..sort();
      for (final import in allImports) {
        buffer.writeln(import);
      }
      buffer.writeln();
    }

    if (config.jsonSerializer == JsonSerializer.freezed) {
      buffer.writeln("part '${config.name}.freezed.dart';");
    } else if (config.jsonSerializer == JsonSerializer.dartMappable) {
      buffer.writeln("part '${config.name}.mapper.dart';");
    }
    buffer
      ..writeln("part '${config.name}.g.dart';")
      ..writeln();

    for (final line in lines) {
      buffer.writeln(line);
    }
    return GeneratedFile(
      name: '${config.name}.dart',
      content: buffer.toString(),
    );
  }

  List<GeneratedFile> addGeneratedFileComments(List<GeneratedFile> files) {
    final comment = generatedFileComment();
    return files
        .map(
          (file) => GeneratedFile(
            name: file.name,
            content: '$comment${file.content}',
          ),
        )
        .toList();
  }

  String _extractPackageKey(String importLine) {
    final match = RegExp(r"import '([^']+)'").firstMatch(importLine);
    return match?.group(1) ?? importLine;
  }
}
