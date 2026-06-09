import 'package:collection/collection.dart';
import 'package:openapi_retrofit_generator/src/generator/model/json_serializer.dart';
import 'package:openapi_retrofit_generator/src/parser/model/normalized_identifier.dart';
import 'package:openapi_retrofit_generator/src/parser/openapi_parser_core.dart';
import 'package:openapi_retrofit_generator/src/utils/base_utils.dart';
import 'package:openapi_retrofit_generator/src/utils/type_utils.dart';

/// Provides template for generating dart typedefs using JSON serializable
String dartTypeDefTemplate(
  UniversalComponentClass dataClass, {
  JsonSerializer? jsonSerializer,
  DartImportPathResolver? importPathResolver,
}) {
  final className = dataClass.name.toPascal;
  final type = dataClass.parameters.firstOrNull;
  final import = dataClass.imports.firstOrNull;
  if (type == null) {
    return '';
  }

  final importPath = import == null
      ? ''
      : importPathResolver?.call(import) ??
            '${_getImportFileName(import)}.dart';

  return '${import != null ? "import '$importPath';\nexport '$importPath';\n\n" : ''}'
      '${descriptionComment(dataClass.description)}'
      'typedef $className = ${_renameTypeForSerializer(type.toSuitableType(), jsonSerializer)};\n';
}

String _getImportFileName(String? import) {
  if (import == null) return '';
  return import.toSnake;
}

String _renameTypeForSerializer(String type, JsonSerializer? jsonSerializer) {
  return type;
}
