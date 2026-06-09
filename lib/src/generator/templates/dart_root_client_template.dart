import 'package:openapi_retrofit_generator/src/parser/model/normalized_identifier.dart';
import 'package:openapi_retrofit_generator/src/parser/openapi_parser_core.dart';
import 'package:openapi_retrofit_generator/src/parser/utils/dart_keywords.dart';
import 'package:openapi_retrofit_generator/src/utils/base_utils.dart';

String dartRootClientTemplate({
  required OpenApiInfo openApiInfo,
  required String name,
  required Set<String> clientsNames,
  required String postfix,
  required bool putClientsInFolder,
  required bool markFileAsGenerated,
  Map<String, String>? clientsNameMap,
  String? clientFolderName,
}) {
  if (clientsNames.isEmpty) {
    return '';
  }

  final className = name.toPascal;

  final title = openApiInfo.title;
  final summary = openApiInfo.summary;
  final description = openApiInfo.description;
  final version = openApiInfo.apiVersion;
  final fullDescription = switch ((summary, description)) {
    (null, null) => null,
    (_, null) => summary,
    (null, _) => description,
    (_, _) => '$summary\n\n$description',
  };

  final comment =
      '${title ?? ''}${version != null ? ' `v$version`' : ''}${fullDescription != null ? '\n\n$fullDescription' : ''}';

  return '''
import 'package:dio/dio.dart' hide Headers;
${_clientsImport(clientsNames, postfix, putClientsInFolder: putClientsInFolder, clientsNameMap: clientsNameMap, clientFolderName: clientFolderName)}
${descriptionComment(comment)}class $className {
  $className(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '${openApiInfo.apiVersion ?? ''}';

${_privateFields(clientsNames, postfix)}

${_getters(clientsNames, postfix)}
}
''';
}

String _clientsImport(
  Set<String> imports,
  String postfix, {
  required bool putClientsInFolder,
  Map<String, String>? clientsNameMap,
  String? clientFolderName,
}) {
  return '\n${imports.map((import) {
    final snakeName = clientsNameMap?[import] ?? import.toSnake;
    final folderName = clientFolderName ?? (putClientsInFolder ? 'clients' : snakeName);
    return "import '$folderName/${snakeName}_${postfix.toSnake}.dart';";
  }).join('\n')}\n';
}

String _getFieldName(String name) {
  final camelName = name.toCamel;
  return reservedFieldNames.contains(camelName)
      ? '${camelName}Client'
      : camelName;
}

String _privateFields(Set<String> names, String postfix) => names
    .map((n) => '  ${n.toPascal + postfix.toPascal}? _${_getFieldName(n)};')
    .join('\n');

String _getters(Set<String> names, String postfix) => names
    .map((n) {
      final fieldName = _getFieldName(n);
      return '  ${n.toPascal + postfix.toPascal} get $fieldName => '
          '_$fieldName ??= ${n.toPascal + postfix.toPascal}(_dio, baseUrl: _baseUrl);';
    })
    .join('\n\n');
