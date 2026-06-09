import 'package:args/args.dart';
import 'package:openapi_retrofit_generator/src/config/config_exception.dart';
import 'package:openapi_retrofit_generator/src/generator/config/generator_config.dart';
import 'package:openapi_retrofit_generator/src/generator/model/json_serializer.dart';
import 'package:openapi_retrofit_generator/src/parser/openapi_parser_core.dart';
import 'package:yaml/yaml.dart';

/// OpenAPI Generator Config
class OpenApiConfig {
  /// Creates a [OpenApiConfig].
  const OpenApiConfig({
    required this.outputDirectory,
    this.schemaPath,
    this.schemaUrl,
    this.name = 'api',
    this.jsonSerializer = JsonSerializer.jsonSerializable,
    this.rootClient = true,
    this.rootClientName = 'RestClient',
    this.clientPostfix,
    this.exportFile = false,
    this.putClientsInFolder = false,
    this.unknownEnumValue = true,
    this.markFilesAsGenerated = true,
    this.originalHttpResponse = false,
    this.defaultContentType = 'application/json',
    this.extrasParameterByDefault = false,
    this.dioOptionsParameterByDefault = false,
    this.pathMethodName = false,
    this.mergeClients = false,
    this.skippedParameters = const <String>[],
    this.generateValidator = false,
    this.useXNullable = true,
    this.fallbackUnion,
    this.excludeTags = const <String>[],
    this.includeTags = const <String>[],
    this.defaultClient = 'api',
    this.mergeOutputs = false,
    this.includeIfNull = false,
    this.outputLayout,
    this.modelClassification = const ModelClassification(),
  });

  /// Internal constructor of [OpenApiConfig]
  const OpenApiConfig._({
    required this.outputDirectory,
    required this.schemaPath,
    required this.schemaUrl,
    required this.name,
    required this.jsonSerializer,
    required this.rootClient,
    required this.rootClientName,
    required this.clientPostfix,
    required this.exportFile,
    required this.putClientsInFolder,
    required this.unknownEnumValue,
    required this.markFilesAsGenerated,
    required this.originalHttpResponse,
    required this.defaultContentType,
    required this.extrasParameterByDefault,
    required this.dioOptionsParameterByDefault,
    required this.pathMethodName,
    required this.mergeClients,
    required this.skippedParameters,
    required this.generateValidator,
    required this.useXNullable,
    required this.excludeTags,
    required this.includeTags,
    required this.defaultClient,
    required this.mergeOutputs,
    required this.includeIfNull,
    required this.outputLayout,
    required this.modelClassification,
    this.fallbackUnion,
  });

  /// Creates a [OpenApiConfig] from [YamlMap].
  factory OpenApiConfig.fromYaml(
    YamlMap yamlMap, {
    bool isRootConfig = false,
    OpenApiConfig? rootConfig,
  }) {
    final schemaPath =
        yamlMap['schema_path']?.toString() ?? rootConfig?.schemaPath;

    final schemaUrl =
        yamlMap['schema_url']?.toString() ?? rootConfig?.schemaUrl;
    if (schemaUrl != null) {
      final uri = Uri.tryParse(schemaUrl);
      if (uri == null) {
        throw const ConfigException(
          "Config parameter 'schema_url' must be valid URL.",
        );
      }
    }

    if (!isRootConfig && schemaPath == null && schemaUrl == null) {
      throw const ConfigException(
        "Config parameters 'schema_path' or 'schema_url' are required.",
      );
    }

    var outputDirectory =
        yamlMap['output_directory']?.toString() ?? rootConfig?.outputDirectory;

    // Normalize: treat null and empty string the same
    final hasOutputDirectory =
        outputDirectory != null && outputDirectory.isNotEmpty;

    // For non-root configs (schemas), output_directory is required either locally or from root
    if (!isRootConfig && !hasOutputDirectory) {
      throw ConfigException(
        "Config parameter 'output_directory' for ${schemaPath ?? schemaUrl ?? 'schema'} was not found.\n"
        "Add the 'output_directory' parameter under 'openapi_generator:' or set it for each schema.",
      );
    }

    // For root configs with schemes, output_directory is optional (defaults to empty)
    outputDirectory ??= '';

    final rawName = yamlMap['name']?.toString();
    final name = rawName == null || rawName.isEmpty
        ? (schemaPath ?? schemaUrl ?? '').split('/').last.split('.').first
        : rawName;

    final defaultContentType =
        yamlMap['default_content_type'] as String? ??
        rootConfig?.defaultContentType;
    final extrasParameterByDefault =
        yamlMap['extras_parameter_by_default'] as bool? ??
        rootConfig?.extrasParameterByDefault;
    final dioOptionsParameterByDefault =
        yamlMap['dio_options_parameter_by_default'] as bool? ??
        rootConfig?.dioOptionsParameterByDefault;
    final pathMethodName =
        yamlMap['path_method_name'] as bool? ?? rootConfig?.pathMethodName;
    final mergeClients =
        yamlMap['merge_clients'] as bool? ?? rootConfig?.mergeClients;

    final rawSkippedParameters = yamlMap['skipped_parameters'] as YamlList?;
    List<String>? skippedParameters;
    if (rawSkippedParameters != null) {
      skippedParameters = [];
      for (final p in rawSkippedParameters) {
        if (p is! String) {
          throw const ConfigException(
            "Config parameter 'skipped_parameters' values must be List of String.",
          );
        }
        skippedParameters.add(p);
      }
    } else if (rootConfig?.skippedParameters != null) {
      skippedParameters = List.from(rootConfig!.skippedParameters);
    }

    JsonSerializer? jsonSerializer;
    final rawJsonSerializer = yamlMap['json_serializer']?.toString();
    if (rawJsonSerializer != null) {
      jsonSerializer = JsonSerializer.fromString(rawJsonSerializer);
    } else if (rootConfig?.jsonSerializer != null) {
      jsonSerializer = rootConfig!.jsonSerializer;
    }

    final rootClient =
        yamlMap['root_client'] as bool? ?? rootConfig?.rootClient;
    final rootClientName =
        yamlMap['root_client_name'] as String? ?? rootConfig?.rootClientName;
    final clientPostfix =
        yamlMap['client_postfix'] as String? ?? rootConfig?.clientPostfix;
    final exportFile =
        yamlMap['export_file'] as bool? ?? rootConfig?.exportFile;
    final putClientsInFolder =
        yamlMap['put_clients_in_folder'] as bool? ??
        rootConfig?.putClientsInFolder;
    final unknownEnumValue =
        yamlMap['unknown_enum_value'] as bool? ?? rootConfig?.unknownEnumValue;
    final markFilesAsGenerated =
        yamlMap['mark_files_as_generated'] as bool? ??
        rootConfig?.markFilesAsGenerated;
    final originalHttpResponse =
        yamlMap['original_http_response'] as bool? ??
        rootConfig?.originalHttpResponse;

    final generateValidator =
        yamlMap['generate_validator'] as bool? ?? rootConfig?.generateValidator;

    final useXNullable =
        yamlMap['use_x_nullable'] as bool? ?? rootConfig?.useXNullable;

    final fallbackUnion =
        yamlMap['fallback_union'] as String? ?? rootConfig?.fallbackUnion;

    final excludedTagsYaml = yamlMap['exclude_tags'] as YamlList?;
    List<String>? excludedTags;
    if (excludedTagsYaml != null) {
      excludedTags = [];
      for (final t in excludedTagsYaml) {
        if (t is! String) {
          throw const ConfigException(
            "Config parameter 'exclude_tags' values must be List of String.",
          );
        }
        excludedTags.add(t);
      }
    } else if (rootConfig?.excludeTags != null) {
      excludedTags = List.from(rootConfig!.excludeTags);
    }

    final includedTagsYaml = yamlMap['include_tags'] as YamlList?;
    List<String>? includedTags;
    if (includedTagsYaml != null) {
      includedTags = [];
      for (final t in includedTagsYaml) {
        if (t is! String) {
          throw const ConfigException(
            "Config parameter 'include_tags' values must be List of String.",
          );
        }
        includedTags.add(t);
      }
    } else if (rootConfig?.includeTags != null) {
      includedTags = List.from(rootConfig!.includeTags);
    }

    final defaultClient =
        yamlMap['default_client'] as String? ?? rootConfig?.defaultClient;

    final mergeOutputs =
        yamlMap['merge_outputs'] as bool? ?? rootConfig?.mergeOutputs;

    final includeIfNull =
        yamlMap['include_if_null'] as bool? ?? rootConfig?.includeIfNull;

    final outputLayout =
        _parseOutputLayout(yamlMap['output_layout']) ??
        rootConfig?.outputLayout;

    final modelClassification =
        _parseModelClassification(yamlMap['model_classification']) ??
        rootConfig?.modelClassification;

    // Default config
    final dc = OpenApiConfig(name: name, outputDirectory: outputDirectory);

    return OpenApiConfig._(
      schemaPath: schemaPath,
      schemaUrl: schemaUrl,
      outputDirectory: outputDirectory,
      name: name,
      pathMethodName: pathMethodName ?? dc.pathMethodName,
      defaultContentType: defaultContentType ?? dc.defaultContentType,
      extrasParameterByDefault:
          extrasParameterByDefault ?? dc.extrasParameterByDefault,
      dioOptionsParameterByDefault:
          dioOptionsParameterByDefault ?? dc.dioOptionsParameterByDefault,
      mergeClients: mergeClients ?? dc.mergeClients,
      skippedParameters: skippedParameters ?? dc.skippedParameters,
      exportFile: exportFile ?? dc.exportFile,
      jsonSerializer: jsonSerializer ?? dc.jsonSerializer,
      rootClient: rootClient ?? dc.rootClient,
      rootClientName: rootClientName ?? dc.rootClientName,
      clientPostfix: clientPostfix?.trim() ?? dc.clientPostfix,
      putClientsInFolder: putClientsInFolder ?? dc.putClientsInFolder,
      unknownEnumValue: unknownEnumValue ?? dc.unknownEnumValue,
      markFilesAsGenerated: markFilesAsGenerated ?? dc.markFilesAsGenerated,
      originalHttpResponse: originalHttpResponse ?? dc.originalHttpResponse,
      generateValidator: generateValidator ?? dc.generateValidator,
      useXNullable: useXNullable ?? dc.useXNullable,
      fallbackUnion: fallbackUnion,
      mergeOutputs: mergeOutputs ?? dc.mergeOutputs,
      excludeTags: excludedTags ?? dc.excludeTags,
      includeTags: includedTags ?? dc.includeTags,
      defaultClient: defaultClient ?? dc.defaultClient,
      includeIfNull: includeIfNull ?? dc.includeIfNull,
      outputLayout: outputLayout ?? dc.outputLayout,
      modelClassification: modelClassification ?? dc.modelClassification,
    );
  }

  static OutputLayout? _parseOutputLayout(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! YamlMap) {
      throw const ConfigException(
        "Config parameter 'output_layout' must be a map.",
      );
    }

    String folder(String key, String defaultValue) {
      final rawValue = value[key];
      if (rawValue == null) {
        return defaultValue;
      }
      if (rawValue is! String || rawValue.trim().isEmpty) {
        throw ConfigException(
          "Config parameter 'output_layout.$key' must be a non-empty String.",
        );
      }
      return rawValue.trim();
    }

    return OutputLayout(
      clients: folder('clients', 'clients'),
      models: folder('models', 'models'),
      requests: folder('requests', 'requests'),
      responses: folder('responses', 'responses'),
      enums: folder('enums', 'enums'),
    );
  }

  static ModelClassification? _parseModelClassification(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! YamlMap) {
      throw const ConfigException(
        "Config parameter 'model_classification' must be a map.",
      );
    }

    return ModelClassification(
      requestSuffixes:
          _parseStringList(
            value['request_suffixes'],
            'model_classification.request_suffixes',
          ) ??
          const ModelClassification().requestSuffixes,
      responseSuffixes:
          _parseStringList(
            value['response_suffixes'],
            'model_classification.response_suffixes',
          ) ??
          const ModelClassification().responseSuffixes,
      overrides: _parseClassificationOverrides(value['overrides']),
    );
  }

  static List<String>? _parseStringList(Object? value, String configPath) {
    if (value == null) {
      return null;
    }
    if (value is! YamlList) {
      throw ConfigException("Config parameter '$configPath' must be a list.");
    }
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty)
          item.trim()
        else
          throw ConfigException(
            "Config parameter '$configPath' values must be non-empty String.",
          ),
    ];
  }

  static Map<String, String> _parseClassificationOverrides(Object? value) {
    if (value == null) {
      return const <String, String>{};
    }
    if (value is! YamlMap) {
      throw const ConfigException(
        "Config parameter 'model_classification.overrides' must be a map.",
      );
    }
    const allowedValues = {'models', 'requests', 'responses', 'enums'};
    final overrides = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key is! String ||
          entry.value is! String ||
          !allowedValues.contains(entry.value)) {
        throw const ConfigException(
          "Config parameter 'model_classification.overrides' values must be one of models, requests, responses, or enums.",
        );
      }
      overrides[(entry.key as String).trim()] = entry.value as String;
    }
    return overrides;
  }

  /// Creates a [OpenApiConfig] from [YamlMap] with CLI [argResults] overrides.
  factory OpenApiConfig.fromYamlWithOverrides(
    YamlMap yamlMap,
    ArgResults? argResults, {
    bool isRootConfig = false,
    OpenApiConfig? rootConfig,
  }) {
    // Apply CLI overrides to YAML map
    final mergedConfig = Map<String, dynamic>.from(yamlMap);

    if (argResults != null) {
      for (final option in argResults.options) {
        mergedConfig[option] = argResults[option];
      }
    }

    // Create YAML map from merged config
    final mergedYamlMap = YamlMap.wrap(mergedConfig);

    // Use existing fromYaml method with merged configuration
    return OpenApiConfig.fromYaml(
      mergedYamlMap,
      isRootConfig: isRootConfig,
      rootConfig: rootConfig,
    );
  }

  /// Path to local OpenAPI schema file.
  ///
  /// Supports both JSON (.json) and YAML (.yaml, .yml) formats.
  /// Can be absolute or relative to the config file location.
  ///
  /// At least one of [schemaPath] or [schemaUrl] must be provided.
  ///
  /// Example: `schemes/openapi.json`, `../shared/api.yaml`
  final String? schemaPath;

  /// URL to remote OpenAPI schema.
  ///
  /// Alternative to [schemaPath] - fetches schema from a web endpoint.
  /// Must be a valid HTTP/HTTPS URL.
  ///
  /// At least one of [schemaPath] or [schemaUrl] must be provided.
  ///
  /// Example: `https://api.example.com/swagger.json`
  final String? schemaUrl;

  /// API identifier used for naming folders and export files.
  ///
  /// If not specified, extracted from schema file name
  /// (e.g., `openapi.json` -> `openapi`).
  ///
  /// Used in:
  /// - Export file name: `<name>.dart`
  /// - Merged output file: `<name>.dart` (when [mergeOutputs] is true)
  /// - API folder organization
  ///
  /// Default: extracted from [schemaPath] or [schemaUrl]
  final String name;

  /// Directory where all generated files will be placed.
  ///
  /// **Required.** Can be absolute or relative path.
  /// All clients, models, and export files will be generated here.
  ///
  /// Example: `lib/api`, `lib/src/generated`
  final String outputDirectory;

  /// JSON serialization library to use for model generation.
  ///
  /// Available options:
  /// - [JsonSerializer.jsonSerializable]: Standard Dart JSON serialization (default)
  ///   Generates toJson/fromJson methods with @JsonSerializable annotation
  /// - [JsonSerializer.freezed]: Immutable data classes with Freezed package
  ///   Generates union types, copyWith, equality, toString
  /// - [JsonSerializer.dartMappable]: Type-safe mapping with dart_mappable package
  ///   Fast, code-generated mapping with type safety
  ///
  /// Default: [JsonSerializer.jsonSerializable]
  final JsonSerializer jsonSerializer;

  /// Suffix appended to all client class names.
  ///
  /// Examples:
  /// - `Client` -> `UserClient`, `PostClient`
  /// - `Api` -> `UserApi`, `PostApi`
  /// - `null` -> `User`, `Post` (no suffix)
  ///
  /// Default: null (no suffix)
  final String? clientPostfix;

  /// Generate a root client class that aggregates all API clients.
  ///
  /// When true, creates an interface and implementation with all clients as properties.
  ///
  /// Example: RestClient contains userClient, postClient, etc.
  ///
  /// Default: true
  final bool rootClient;

  /// Name for the generated root client class.
  ///
  /// Only used when [rootClient] is true.
  ///
  /// Default: `RestClient`
  final String rootClientName;

  /// Generate a barrel export file.
  ///
  /// When true, exports all generated clients and models from a single file.
  /// Simplifies imports: `import 'package:app/api.dart';`
  ///
  /// Only applies when [mergeOutputs] is false.
  ///
  /// Default: false
  final bool exportFile;

  /// Place all client files in a dedicated `clients/` subdirectory.
  ///
  /// When true: `output_directory/clients/user_client.dart`
  /// When false: `output_directory/user_client.dart`
  ///
  /// Default: false
  final bool putClientsInFolder;

  /// Add an `unknown` value to all generated enums.
  ///
  /// Provides backwards compatibility when server adds new enum values.
  /// Generated enum includes: `...<values>, unknown` (for unmapped values).
  ///
  /// Use case: Prevents deserialization errors on unknown enum values.
  ///
  /// Default: true
  final bool unknownEnumValue;

  /// Add generation comment to generated files.
  ///
  /// When true: Files start with `// Generated code - do not modify` comment
  /// When false: No generation comment added
  ///
  /// Default: true
  final bool markFilesAsGenerated;

  /// Wrap all response types with `HttpResponse<T>`.
  ///
  /// When true: Returns `HttpResponse<T>` containing response + headers + status
  /// When false: Returns only the response body (T)
  ///
  /// Use case: Access response headers, status codes, etc.
  ///
  /// Example: `HttpResponse<User>` instead of `User`
  ///
  /// Default: false
  final bool originalHttpResponse;

  /// Default Content-Type header for all requests.
  ///
  /// When an endpoint's content type differs from this, a @Headers annotation is added.
  ///
  /// Common values: `application/json`, `application/x-www-form-urlencoded`
  ///
  /// If the content type does not match the default, generates:
  /// `@Headers(<String, String>{'Content-Type': 'PARSED CONTENT TYPE'})`
  ///
  /// Default: `application/json`
  final String defaultContentType;

  /// Add `@Extras()` parameter to all generated methods.
  ///
  /// Enables passing custom data through Dio interceptors.
  /// Requires retrofit >=4.1.0.
  ///
  /// Generated code:
  /// ```dart
  /// @POST('/path/')
  /// Future<T> method({@Extras() Map<String, dynamic>? extras});
  /// ```
  ///
  /// Use case: Pass request-specific metadata to interceptors.
  ///
  /// Default: false
  final bool extrasParameterByDefault;

  /// Add `@DioOptions()` parameter to all generated methods.
  ///
  /// Allows per-request Dio configuration override.
  ///
  /// Generated code:
  /// ```dart
  /// @POST('/path/')
  /// Future<T> method({@DioOptions() RequestOptions? options});
  /// ```
  ///
  /// Use case: Override timeout, headers, etc. per request.
  ///
  /// Default: false
  final bool dioOptionsParameterByDefault;

  /// Determines how API method names are generated.
  ///
  /// When true: Use endpoint path for method name (e.g., `/users/{id}` -> `usersId`)
  /// When false: Use operationId from OpenAPI spec
  ///
  /// Recommendation: false (operationId is more semantic)
  ///
  /// Default: false
  final bool pathMethodName;

  /// Combine all API clients into a single client class.
  ///
  /// When true: All endpoints merged into one client (e.g., ApiClient)
  /// When false: Separate client per tag (e.g., UserClient, PostClient)
  ///
  /// Use case: Simple APIs or preference for monolithic client.
  ///
  /// Default: false
  final bool mergeClients;

  /// List of parameter names to exclude from generation.
  ///
  /// Parameters with these exact names (case-sensitive) will be skipped.
  ///
  /// Use case: Skip internal headers, auth tokens handled elsewhere.
  ///
  /// Example: `['X-Request-ID', 'Authorization', 'X-Custom-Header']`
  ///
  /// Default: [] (no exclusions)
  final List<String> skippedParameters;

  /// Generate validator function for Freezed classes.
  ///
  /// When true: Adds validation logic to Freezed data classes.
  /// Only applicable with [jsonSerializer] set to [JsonSerializer.freezed].
  ///
  /// Default: false
  final bool generateValidator;

  /// Respect `x-nullable` OpenAPI extension.
  ///
  /// When true: Fields marked with `x-nullable: true` become nullable (Type?)
  /// When false: x-nullable annotation is ignored
  ///
  /// Use case: OpenAPI 2.0 specs using x-nullable for nullability.
  ///
  /// Default: true
  final bool useXNullable;

  /// Fallback constructor name for discriminated unions.
  ///
  /// When set, adds fallbackUnion parameter to @Freezed annotation.
  /// Handles unknown discriminator values in oneOf/anyOf unions.
  ///
  /// Example values: `unknown`, `undefined`, `fallback`
  ///
  /// Generated: `@Freezed(fallbackUnion: 'unknown')`
  ///
  /// Use case: Graceful handling of new union variants from server.
  ///
  /// Only applicable with [jsonSerializer] set to [JsonSerializer.freezed]
  /// or [JsonSerializer.dartMappable].
  ///
  /// Default: null (no fallback union)
  final String? fallbackUnion;

  /// Exclude endpoints with specific OpenAPI tags.
  ///
  /// Endpoints tagged with these values will NOT be generated.
  ///
  /// Example: `['internal', 'deprecated', 'admin']`
  ///
  /// Note: Overridden by [includeTags] if both are set.
  ///
  /// Default: [] (no exclusions)
  final List<String> excludeTags;

  /// Include ONLY endpoints with specific OpenAPI tags.
  ///
  /// When set, only endpoints with these tags are generated.
  ///
  /// Example: `['public', 'v2']`
  ///
  /// **Note: This OVERRIDES [excludeTags] - includeTags takes precedence.**
  ///
  /// Default: [] (include all)
  final List<String> includeTags;

  /// Default client name for endpoints without any tags.
  ///
  /// Example: `api` -> `ApiClient` (with postfix) or `Api` (without), `misc` -> `MiscClient`
  ///
  /// Default: `api`
  final String defaultClient;

  /// Merge all generated code into a single output file.
  ///
  /// When true: All clients + models in one file (`<name>.dart`)
  /// When false: Separate files for each client and model
  ///
  /// Use case: Required for build_runner (1-to-1 input/output mapping).
  ///
  /// Default: false
  final bool mergeOutputs;

  /// Generate `@JsonKey(includeIfNull: ...)` annotations for nullable fields.
  ///
  /// When true: Nullable fields include includeIfNull in @JsonKey annotation
  /// When false: includeIfNull annotations are not generated
  ///
  /// Affects JSON serialization behavior for null values.
  ///
  /// Default: false
  final bool includeIfNull;

  /// Optional generated output layout.
  ///
  /// When omitted, the historical layout is preserved:
  /// clients follow [putClientsInFolder] and data classes go under `models/`.
  final OutputLayout? outputLayout;

  /// Name-based data-class classification rules used with [outputLayout].
  final ModelClassification modelClassification;

  /// Convert [OpenApiConfig] to [GeneratorConfig]
  GeneratorConfig toGeneratorConfig() {
    return GeneratorConfig(
      name: name,
      outputDirectory: outputDirectory,
      jsonSerializer: jsonSerializer,
      defaultContentType: defaultContentType,
      extrasParameterByDefault: extrasParameterByDefault,
      dioOptionsParameterByDefault: dioOptionsParameterByDefault,
      rootClient: rootClient,
      rootClientName: rootClientName,
      clientPostfix: clientPostfix,
      exportFile: exportFile,
      putClientsInFolder: putClientsInFolder,
      unknownEnumValue: unknownEnumValue,
      markFilesAsGenerated: markFilesAsGenerated,
      originalHttpResponse: originalHttpResponse,
      generateValidator: generateValidator,
      fallbackUnion: fallbackUnion,
      mergeOutputs: mergeOutputs,
      includeIfNull: includeIfNull,
      outputLayout: outputLayout,
      modelClassification: modelClassification,
    );
  }

  /// Convert [OpenApiConfig] to [ParserConfig]
  ParserConfig toParserConfig({
    required String fileContent,
    required bool isJson,
  }) {
    return ParserConfig(
      fileContent,
      isJson: isJson,
      name: name,
      defaultContentType: defaultContentType,
      pathMethodName: pathMethodName,
      mergeClients: mergeClients,
      skippedParameters: skippedParameters,
      useXNullable: useXNullable,
      excludeTags: excludeTags,
      includeTags: includeTags,
      defaultClient: defaultClient,
    );
  }
}
