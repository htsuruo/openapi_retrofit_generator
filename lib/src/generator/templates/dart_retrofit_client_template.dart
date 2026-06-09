import 'package:collection/collection.dart';
import 'package:openapi_retrofit_generator/src/generator/model/json_serializer.dart';
import 'package:openapi_retrofit_generator/src/parser/model/normalized_identifier.dart';
import 'package:openapi_retrofit_generator/src/parser/openapi_parser_core.dart';
import 'package:openapi_retrofit_generator/src/parser/utils/dart_keywords.dart';
import 'package:openapi_retrofit_generator/src/utils/base_utils.dart';
import 'package:openapi_retrofit_generator/src/utils/type_utils.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required UniversalRestClient restClient,
  required String name,
  required String defaultContentType,
  required JsonSerializer jsonSerializer,
  bool extrasParameterByDefault = false,
  bool dioOptionsParameterByDefault = false,
  bool originalHttpResponse = false,
  bool mergeClients = false,
  String? fileName,
  DartImportPathResolver? importPathResolver,
}) {
  final dioImport = "import 'package:dio/dio.dart' hide Headers;";

  // When using dartMappable with merged clients, we need TWO retrofit imports:
  // 1. With 'as retrofit' prefix to use retrofit.Field
  // 2. With 'hide Field' to use other annotations without prefix
  final needFieldPrefix =
      jsonSerializer == JsonSerializer.dartMappable && mergeClients;
  final retrofitImports = needFieldPrefix
      ? "import 'package:retrofit/retrofit.dart' as retrofit;\nimport 'package:retrofit/retrofit.dart' hide Field;\nimport 'package:retrofit/error_logger.dart';"
      : "import 'package:retrofit/retrofit.dart';\nimport 'package:retrofit/error_logger.dart';";

  final sb = StringBuffer('''
${_convertImport(restClient)}$dioImport
$retrofitImports
${dartImports(imports: restClient.imports, pathPrefix: '../models/', importPathResolver: importPathResolver)}
part '${fileName ?? name.toSnake}.g.dart';

@RestApi()
abstract class $name {
  factory $name(Dio dio, {String? baseUrl}) = _$name;
''');
  for (final request in restClient.requests) {
    sb.write(
      _toClientRequest(
        request,
        defaultContentType,
        needFieldPrefix: needFieldPrefix,
        originalHttpResponse: originalHttpResponse,
        extrasParameterByDefault: extrasParameterByDefault,
        dioOptionsParameterByDefault: dioOptionsParameterByDefault,
      ),
    );
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(
  UniversalRequest request,
  String defaultContentType, {
  required bool needFieldPrefix,
  required bool originalHttpResponse,
  required bool extrasParameterByDefault,
  required bool dioOptionsParameterByDefault,
}) {
  var responseType = request.returnType == null
      ? 'void'
      : request.returnType!.toSuitableType();

  // Check if this is a binary response (file download)
  final isBinaryResponse =
      request.returnType?.format == 'binary' ||
      (request.returnType?.type == 'string' &&
          request.returnType?.format == 'binary');

  // For non-binary responses, if type is Uint8List, use String instead
  // (Retrofit doesn't support Uint8List serialization for regular responses)
  if (!isBinaryResponse && responseType.startsWith('Uint8List')) {
    responseType = responseType.replaceFirst('Uint8List', 'String');
  }

  // For binary responses, we need to use HttpResponse<List<int>> and add @DioResponseType
  final finalResponseType = isBinaryResponse
      ? 'HttpResponse<List<int>>'
      : (originalHttpResponse ? 'HttpResponse<$responseType>' : responseType);

  // Add @DioResponseType(ResponseType.bytes) for binary responses - after @GET
  final dioResponseTypeAnnotation = isBinaryResponse
      ? '\n  @DioResponseType(ResponseType.bytes)'
      : '';

  final sb = StringBuffer('''

  ${descriptionComment(request.description, tabForFirstLine: false, tab: '  ', end: '  ')}${request.isDeprecated ? "@Deprecated('This method is marked as deprecated')\n  " : ''}${_contentTypeHeader(request, defaultContentType)}@${request.requestType.name.toUpperCase()}('${request.route}')$dioResponseTypeAnnotation
  Future<$finalResponseType> ${request.name}(''');
  if (request.parameters.isNotEmpty ||
      extrasParameterByDefault ||
      dioOptionsParameterByDefault) {
    sb.write('{\n');
  }

  final uniqueParameters = <String, UniversalRequestType>{};
  for (final param in request.parameters) {
    final key = param.type.name ?? '';
    if (!uniqueParameters.containsKey(key)) {
      uniqueParameters[key] = param;
    }
  }

  final sortedByRequired = List<UniversalRequestType>.from(
    uniqueParameters.values.sorted((a, b) => a.type.compareTo(b.type)),
  );
  for (final parameter in sortedByRequired) {
    sb.write(
      '${_toParameter(parameter, request.isMultiPart, needFieldPrefix)}\n',
    );
  }
  if (extrasParameterByDefault) {
    sb.write(_addExtraParameter());
  }
  if (dioOptionsParameterByDefault) {
    sb.write(_addDioOptionsParameter());
  }
  if (request.parameters.isNotEmpty ||
      extrasParameterByDefault ||
      dioOptionsParameterByDefault) {
    sb.write('  });\n');
  } else {
    sb.write(');\n');
  }
  return sb.toString();
}

String _convertImport(UniversalRestClient restClient) =>
    restClient.requests.any(
      (r) => r.parameters.any((e) => e.parameterType.isPart),
    )
    ? "import 'dart:convert';\n"
    : '';

String _addExtraParameter() {
  return '    @Extras() Map<String, dynamic>? extras,\n';
}

String _addDioOptionsParameter() {
  return '    @DioOptions() RequestOptions? options,\n';
}

String _toParameter(
  UniversalRequestType parameter,
  bool multiPart,
  bool needFieldPrefix,
) {
  var parameterType = parameter.type.toSuitableType(multiPart: multiPart);
  if (parameter.parameterType.isBody &&
      (parameterType == 'Object' || parameterType == 'Object?')) {
    parameterType = 'dynamic';
  }

  // Retrofit doesn't support Uint8List serialization, use List<int> instead
  if (parameterType.startsWith('Uint8List')) {
    parameterType = parameterType.replaceFirst('Uint8List', 'List<int>');
  }

  // Reserved words cannot be used as keyword arguments
  var keywordArguments =
      (parameter.type.name ?? parameter.name ?? 'param').toCamel;
  if (reservedFieldNames.contains(keywordArguments)) {
    keywordArguments = '${keywordArguments}Param';
  }

  final deprecatedAnnotation = parameter.deprecated
      ? "    @Deprecated('This is marked as deprecated')\n"
      : '';

  // When using dartMappable with merged clients, prefix Field with retrofit. to avoid conflict
  final annotationType = parameter.parameterType.type;
  final annotationPrefix = (needFieldPrefix && annotationType == 'Field')
      ? 'retrofit.'
      : '';

  return '$deprecatedAnnotation    @$annotationPrefix$annotationType'
      "(${parameter.name != null && !parameter.parameterType.isBody ? "${parameter.parameterType.isPart ? 'name: ' : ''}${_startWith$(parameter.name!) ? 'r' : ''}'${parameter.name}'" : ''}) "
      '${_required(parameter.type)}'
      '$parameterType '
      '$keywordArguments${_defaultValue(parameter.type)},';
}

String _contentTypeHeader(UniversalRequest request, String defaultContentType) {
  if (request.isMultiPart) {
    return '@MultiPart()\n  ';
  }
  if (request.isFormUrlEncoded) {
    return '@FormUrlEncoded()\n  ';
  }
  if (request.contentType != defaultContentType) {
    return "@Headers(<String, String>{'Content-Type': '${request.contentType}'})\n  ";
  }
  return '';
}

/// return required if isRequired
String _required(UniversalType t) => t.isRequired ? 'required ' : '';

/// return defaultValue if have and not required
String _defaultValue(UniversalType t) {
  if (t.isRequired) {
    return '';
  }

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

bool _startWith$(String name) => name.isNotEmpty && name.startsWith(r'$');
