import 'package:openapi_retrofit_generator/src/generator/model/json_serializer.dart';

/// Generated output layout for REST clients and data classes.
class OutputLayout {
  /// Creates an [OutputLayout].
  const OutputLayout({
    this.clients = 'clients',
    this.models = 'models',
    this.requests = 'requests',
    this.responses = 'responses',
    this.enums = 'enums',
  });

  /// Folder for generated REST clients.
  final String clients;

  /// Folder for regular component models.
  final String models;

  /// Folder for request DTOs.
  final String requests;

  /// Folder for response DTOs.
  final String responses;

  /// Folder for enum DTOs.
  final String enums;
}

/// Name-based classification rules for generated data classes.
class ModelClassification {
  /// Creates a [ModelClassification].
  const ModelClassification({
    this.requestSuffixes = const ['Input', 'Request', 'Payload'],
    this.responseSuffixes = const ['Response', 'Page'],
    this.overrides = const <String, String>{},
  });

  /// Suffixes treated as request DTOs.
  final List<String> requestSuffixes;

  /// Suffixes treated as response DTOs.
  final List<String> responseSuffixes;

  /// Exact class-name overrides.
  ///
  /// Values must be one of `models`, `requests`, `responses`, or `enums`.
  final Map<String, String> overrides;
}

/// The configuration that the Generator uses
class GeneratorConfig {
  /// Creates a  [GeneratorConfig].
  const GeneratorConfig({
    required this.name,
    required this.outputDirectory,
    this.jsonSerializer = JsonSerializer.jsonSerializable,
    this.defaultContentType = 'application/json',
    this.rootClient = true,
    this.extrasParameterByDefault = false,
    this.dioOptionsParameterByDefault = false,
    this.rootClientName = 'RestClient',
    this.clientPostfix,
    this.exportFile = true,
    this.putClientsInFolder = false,
    this.unknownEnumValue = true,
    this.markFilesAsGenerated = false,
    this.originalHttpResponse = false,
    this.generateValidator = false,
    this.fallbackUnion,
    this.mergeOutputs = false,
    this.includeIfNull = false,
    this.outputLayout,
    this.modelClassification = const ModelClassification(),
  });

  /// API identifier used for naming folders and export files.
  ///
  /// Used in:
  /// - Export file name: `<name>.dart`
  /// - Merged output file: `<name>.dart` (when [mergeOutputs] is true)
  /// - API folder organization
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
  /// - [JsonSerializer.freezed]: Immutable data classes with Freezed package
  /// - [JsonSerializer.dartMappable]: Type-safe mapping with dart_mappable package
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
  /// Default: true
  final bool rootClient;

  /// Name for the generated root client class.
  ///
  /// Only used when [rootClient] is true.
  ///
  /// Default: `RestClient`
  final String? rootClientName;

  /// Generate a barrel export file.
  ///
  /// When true, exports all generated clients and models from a single file.
  /// Only applies when [mergeOutputs] is false.
  ///
  /// Default: true
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
  ///
  /// Default: true
  final bool unknownEnumValue;

  /// Add generation comment to generated files.
  ///
  /// When true: Files start with generation comment
  /// When false: No generation comment added
  ///
  /// Default: false
  final bool markFilesAsGenerated;

  /// Wrap all response types with `HttpResponse<T>`.
  ///
  /// When true: Returns `HttpResponse<T>` containing response + headers + status
  /// When false: Returns only the response body (T)
  ///
  /// Default: false
  final bool originalHttpResponse;

  /// Default Content-Type header for all requests.
  ///
  /// When an endpoint's content type differs from this, a @Headers annotation is added.
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
  /// Default: false
  final bool dioOptionsParameterByDefault;

  /// Generate validator function for Freezed classes.
  ///
  /// When true: Adds validation logic to Freezed data classes.
  /// Only applicable with [jsonSerializer] set to [JsonSerializer.freezed].
  ///
  /// Default: false
  final bool generateValidator;

  /// Fallback constructor name for discriminated unions.
  ///
  /// Handles unknown discriminator values in oneOf/anyOf unions.
  ///
  /// Example: `@Freezed(fallbackUnion: 'unknown')`
  ///
  /// Only applicable with [jsonSerializer] set to [JsonSerializer.freezed]
  /// or [JsonSerializer.dartMappable].
  ///
  /// Default: null (no fallback union)
  final String? fallbackUnion;

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
  /// Default: false
  final bool includeIfNull;

  /// Optional generated output layout.
  ///
  /// When null, the historical layout is preserved.
  final OutputLayout? outputLayout;

  /// Name-based classification rules used when [outputLayout] is set.
  final ModelClassification modelClassification;
}
