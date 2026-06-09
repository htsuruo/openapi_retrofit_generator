# OpenAPI Retrofit Generator

[![pub version](https://img.shields.io/pub/v/openapi_retrofit_generator?logo=dart)](https://pub.dev/packages/openapi_retrofit_generator)
[![Tests](https://github.com/westito/openapi_retrofit_generator/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/westito/openapi_retrofit_generator/actions/workflows/tests.yml)

> **Note**: This package is a complete rework of [swagger_parser](https://pub.dev/packages/swagger_parser) with enhanced features, improved architecture, and better maintainability.

**Generate type-safe Dart REST clients from OpenAPI/Swagger specifications**

Automatically create Retrofit-based REST clients and immutable data models from your API definition files. Save hours of boilerplate coding and eliminate manual typing errors.

### Platform Support

**✅ All Platforms Supported:** Web, Mobile (iOS/Android), Desktop (Windows/macOS/Linux)

This is a **code generator** (dev dependency) that creates platform-agnostic Dart code. While pub.dev may not list platform badges (since the generator itself only runs during development), the **generated REST clients work on all Dart platforms** including Flutter Web, thanks to Dio's universal HTTP support. Your generated API clients are fully compatible with any platform your Dart/Flutter app targets.

## Why OpenAPI Retrofit Generator?

- **Full Spec Support**: OpenAPI 2.0 (Swagger), 3.0, and 3.1
- **Extensively Tested**: Validated with 358 distinct OpenAPI schemas across all 3 serializers in comprehensive end-to-end tests
- **Format Flexible**: Works with JSON and YAML schemas
- **Remote & Local**: Generate from URLs or local files
- **Multiple Serializers**: Choose from `json_serializable`, `freezed`, or `dart_mappable`
- **Type Safe**: Strongly-typed models with null safety
- **Multi-Schema**: Handle multiple API definitions in one project
- **Retrofit Integration**: Built on battle-tested [Retrofit](https://pub.dev/packages/retrofit) + [Dio](https://pub.dev/packages/dio)

## Quick Start

### 1. Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.9.0
  retrofit: ^4.9.0
  json_annotation: ^4.9.0

dev_dependencies:
  openapi_retrofit_generator: ^2.0.0
  build_runner: ^2.10.0
  json_serializable: ^6.11.0
  retrofit_generator: ^10.1.0
```

### 2. Configure

Create `openapi_generator.yaml` in your project root:

```yaml
openapi_generator:
  schema_path: api/openapi.yaml       # Path to your OpenAPI file
  output_directory: lib/api           # Where to generate code
  json_serializer: json_serializable  # Choose: json_serializable, freezed, or dart_mappable
```

### 3. Generate

Run the generator:

```bash
dart run openapi_retrofit_generator
dart run build_runner build -d
```

### 4. Use

```dart
import 'package:dio/dio.dart';
import 'api/export.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  final client = RestClient(dio);

  // Type-safe API calls
  final users = await client.users.listUsers();
  final user = await client.users.getUser(userId: '123');
  
  print('Found ${users.length} users');
  print('User: ${user.name}');
}
```

## What Gets Generated?

From a Pet Store OpenAPI spec, you get:

```
lib/api/
├── pets/
│   └── pets_client.dart        # @RestApi() class with all endpoints
├── models/
│   ├── pet.dart                 # Data class with toJson/fromJson
│   ├── create_pet_request.dart
│   └── pet_status.dart          # Enum for status values
├── rest_client.dart             # Root client aggregating all APIs
└── export.dart                   # Barrel export for easy imports
```

**Example Generated Client:**

```dart
@RestApi()
abstract class PetsClient {
  factory PetsClient(Dio dio) = _PetsClient;

  @GET('/pets')
  Future<List<Pet>> listPets(@Query('limit') int? limit);

  @POST('/pets')
  Future<Pet> createPet(@Body() CreatePetRequest body);

  @GET('/pets/{id}')
  Future<Pet> getPet(@Path('id') String petId);
}
```

**Example Generated Model:**

```dart
@JsonSerializable()
class Pet {
  final String id;
  final String name;
  final PetStatus status;
  
  const Pet({
    required this.id,
    required this.name,
    required this.status,
  });
  
  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);
  Map<String, dynamic> toJson() => _$PetToJson(this);
}
```

## Serialization Options

Choose the serializer that best fits your project:

### json_serializable (Default)

Standard Dart JSON serialization with `@JsonSerializable`:

```yaml
dependencies:
  json_annotation: ^4.9.0
dev_dependencies:
  json_serializable: ^6.11.0
```

### freezed

Immutable data classes with union types and copyWith:

```yaml
dependencies:
  freezed_annotation: ^3.1.0
dev_dependencies:
  freezed: ^3.2.0

openapi_generator:
  json_serializer: freezed
```

### dart_mappable

Fast, type-safe mapping:

```yaml
dependencies:
  dart_mappable: ^4.6.0
dev_dependencies:
  dart_mappable_builder: ^4.6.0

openapi_generator:
  json_serializer: dart_mappable
```

**Required:** When using `dart_mappable`, you must create a `build.yaml` file in your project root with the following configuration:

```yaml
global_options:
  dart_mappable_builder:
    runs_before:
      - retrofit_generator
    options:
      renameMethods:
        fromJson: fromJsonString   # Can be any name except "fromJson"
        toJson: toJsonString       # Can be any name except "toJson"
        fromMap: fromJson          # Must be exactly "fromJson"
        toMap: toJson              # Must be exactly "toJson"
```

This configuration is automatically validated before generation to ensure compatibility with Retrofit.

## Configuration

### Basic Configuration (Single Schema)

Create `openapi_generator.yaml` or add to `pubspec.yaml`:

```yaml
openapi_generator:
  # ============ REQUIRED ============
  # Input: Choose ONE of these
  schema_path: api/openapi.yaml              # Path to local OpenAPI file
  # OR
  # schema_url: https://api.example.com/openapi.json  # URL to remote OpenAPI file
  
  # Output: Must specify where to generate
  output_directory: lib/api                  # Where to generate code
  
  # ============ OPTIONAL ============
  name: my_api                               # API identifier (defaults to schema filename)
  json_serializer: json_serializable         # Serializer (default: json_serializable)
  root_client: true                          # Generate root client (default: true)
  root_client_name: RestClient               # Root client name (default: RestClient)
  client_postfix: Client                     # Client suffix (default: null)
```

**Required:** `schema_path` OR `schema_url`, and `output_directory`  
**Everything else is optional** with sensible defaults.

### Common Options

```yaml
openapi_generator:
  # ... basic config above ...
  
  # Code organization
  merge_clients: false                       # Combine all endpoints into one client
  put_clients_in_folder: true                # Place clients in /clients subdirectory
  export_file: true                          # Generate barrel export file
  
  # Enum handling
  unknown_enum_value: true                   # Add 'unknown' to enums for forward compatibility
  
  # HTTP options
  original_http_response: false              # Return HttpResponse<T> instead of T
  extras_parameter_by_default: false         # Add @Extras() to all methods
  
  # Tag filtering
  include_tags: [public, v2]                 # Only generate these tags
  exclude_tags: [internal, deprecated]       # Skip these tags
  default_client: api                        # Name for untagged endpoints
```

### Output Layout

By default, generated data classes are written to `models/`, and clients follow
the existing `put_clients_in_folder` behavior. To split generated files by
purpose, configure `output_layout`:

```yaml
openapi_generator:
  schema_path: api/openapi.yaml
  output_directory: lib/api

  output_layout:
    clients: clients                         # REST clients
    models: models                           # Regular component models
    requests: requests                       # Request DTOs
    responses: responses                     # Response DTOs
    enums: enums                             # Enum DTOs
```

When `output_layout` is set, generated imports are resolved relative to the new
file locations. For example, a request DTO can import a shared model from
`../models/user.dart`, and a client can import request/response DTOs from their
configured folders.

Data classes are classified by name:

- `UniversalEnumClass` values are written to the `enums` folder.
- Class names ending with `Input`, `Request`, or `Payload` are written to the
  `requests` folder.
- Class names ending with `Response` or `Page` are written to the `responses`
  folder.
- All other data classes are written to the `models` folder.

You can customize the suffixes or force exact class names into a specific
category with `model_classification`:

```yaml
openapi_generator:
  schema_path: api/openapi.yaml
  output_directory: lib/api

  output_layout:
    clients: clients
    models: models
    requests: requests
    responses: responses
    enums: enums

  model_classification:
    request_suffixes: [Input, Request, Payload]
    response_suffixes: [Response, Page]
    overrides:
      SearchResult: models
      TokenResponse: responses
      Role: enums
```

Override values must be one of `models`, `requests`, `responses`, or `enums`.

### Multiple API Schemas

Generate clients for multiple APIs in one project:

```yaml
openapi_generator:
  # ============ REQUIRED (ROOT) ============
  # Must provide default output directory for all schemas
  output_directory: lib/api
  
  # ============ OPTIONAL (ROOT) ============
  # These settings apply to all schemas as defaults
  json_serializer: json_serializable
  client_postfix: Client
  
  # ============ REQUIRED (SCHEMES) ============
  schemes:
    # Each schema MUST have schema_path OR schema_url
    - schema_path: api/v1.yaml           # REQUIRED: input source
      name: api_v1                       # OPTIONAL: defaults to filename
      root_client_name: ApiV1Client      # OPTIONAL: overrides for this schema
      # Inherits: output_directory, json_serializer, client_postfix from root
      
    - schema_url: https://petstore.swagger.io/v2/swagger.json  # REQUIRED
      name: petstore                     # OPTIONAL
      json_serializer: freezed           # OPTIONAL: overrides root default
      client_postfix: Service            # OPTIONAL: overrides root default
      output_directory: lib/petstore     # OPTIONAL: overrides root default
```

**Multi-schema rules:**
- **Root level:** `output_directory` is required (provides default for all schemas)
- **Schema level:** Each schema requires `schema_path` OR `schema_url`
- **Inheritance:** All root settings become defaults; each schema can override any option

## Advanced Usage

### Command Line Arguments

Override config file options via command line:

```bash
# Custom config file
dart run openapi_retrofit_generator -f my_config.yaml

# Override output directory
dart run openapi_retrofit_generator --output_directory lib/generated

# Override schema source
dart run openapi_retrofit_generator --schema_path api/openapi.yaml
dart run openapi_retrofit_generator --schema_url https://api.example.com/openapi.json

# Override serializer
dart run openapi_retrofit_generator --json_serializer freezed

# Help
dart run openapi_retrofit_generator -help
```

### Using Freezed

For `freezed` serializer, create `build.yaml` in your project root:

```yaml
global_options:
  freezed:
    runs_before:
      - json_serializable
  json_serializable:
    runs_before:
      - retrofit_generator
```

Then run:

```bash
dart run openapi_retrofit_generator
dart run build_runner build -d
```

### Using dart_mappable

For `dart_mappable` serializer, you **must** create `build.yaml` in your project root:

```yaml
global_options:
  dart_mappable_builder:
    runs_before:
      - retrofit_generator
    options:
      renameMethods:
        fromJson: fromJsonString   # Can be any name except "fromJson"
        toJson: toJsonString       # Can be any name except "toJson"
        fromMap: fromJson          # Must be exactly "fromJson"
        toMap: toJson              # Must be exactly "toJson"
```

This configuration is automatically validated before generation. The generator will throw an error if:
- `build.yaml` is missing
- `fromMap` is not renamed to `fromJson`
- `toMap` is not renamed to `toJson`
- `fromJson` is not renamed (or still named `fromJson`)
- `toJson` is not renamed (or still named `toJson`)

Then run:

```bash
dart run openapi_retrofit_generator
dart run build_runner build -d
```

### Interceptors & Authentication

Add interceptors to your Dio instance for auth, logging, etc.:

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

// Auth interceptor
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    options.headers['Authorization'] = 'Bearer $token';
    return handler.next(options);
  },
));

// Logging
dio.interceptors.add(LogInterceptor(responseBody: true));

final client = RestClient(dio);
```

### Error Handling

```dart
try {
  final user = await client.users.getUser(userId: '123');
} on DioException catch (e) {
  if (e.response?.statusCode == 404) {
    print('User not found');
  } else if (e.type == DioExceptionType.connectionTimeout) {
    print('Connection timeout');
  } else {
    print('Error: ${e.message}');
  }
}
```

### Streaming Responses

The generator supports streaming endpoints for Server-Sent Events (SSE) and binary streaming. Streaming is automatically detected based on:

1. **`text/event-stream`** content type - for SSE endpoints
2. **`application/octet-stream`** content type - for binary streaming
3. **`x-streaming: true`** extension property on the operation

**Response Type Logic:**
- `Stream<String>` - Default for `text/event-stream` and `x-streaming`
- `Stream<Uint8List>` - For `application/octet-stream` or when `format: binary` is specified

**Example OpenAPI spec:**

```yaml
paths:
  /events:
    get:
      operationId: getEvents
      responses:
        '200':
          content:
            text/event-stream:
              schema:
                type: string
  
  /stream/binary:
    get:
      operationId: streamBinary
      responses:
        '200':
          content:
            application/octet-stream:
              schema:
                type: string
                format: binary
  
  /chat:
    post:
      operationId: chat
      x-streaming: true
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ChatResponse'
```

**Generated code:**

```dart
@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio) = _ApiClient;

  // text/event-stream -> Stream<String> (default)
  @GET('/events')
  @DioResponseType(ResponseType.stream)
  Stream<String> getEvents();

  // application/octet-stream -> Stream<Uint8List>
  @GET('/stream/binary')
  @DioResponseType(ResponseType.stream)
  Stream<Uint8List> streamBinary();

  // x-streaming -> Stream<String> (default)
  @POST('/chat')
  @DioResponseType(ResponseType.stream)
  Stream<String> chat();
}
```

**Usage example:**

```dart
// SSE text stream
final eventStream = client.api.getEvents();
await for (final event in eventStream) {
  print('Received: $event');
}

// Binary stream
final binaryStream = client.api.streamBinary();
await for (final chunk in binaryStream) {
  // Process Uint8List chunks
  processChunk(chunk);
}
```

## Complete Configuration Reference

For all available configuration options, see:
- [example/openapi_generator.yaml](example/openapi_generator.yaml) - Fully documented example
- [example/README.md](example/README.md) - Working example project

### Key Options

| Option | Default | Description |
|--------|---------|-------------|
| `schema_path` | - | Path to local OpenAPI file |
| `schema_url` | - | URL to remote OpenAPI file |
| `output_directory` | - | Where to generate code (required) |
| `json_serializer` | `json_serializable` | Serializer: `json_serializable`, `freezed`, `dart_mappable` |
| `root_client` | `true` | Generate root client aggregating all APIs |
| `client_postfix` | `null` | Suffix for client classes (e.g., `Client`, `Api`) |
| `merge_clients` | `false` | Combine all endpoints into one client |
| `unknown_enum_value` | `true` | Add `unknown` to enums for compatibility |
| `include_tags` | `[]` | Only generate endpoints with these tags |
| `exclude_tags` | `[]` | Skip endpoints with these tags |
| `default_client` | `api` | Name for endpoints without tags |
| `skipped_parameters` | `[]` | Parameter names to exclude |
| `original_http_response` | `false` | Return `HttpResponse<T>` with headers |
| `extras_parameter_by_default` | `false` | Add `@Extras()` to all methods |
| `output_layout` | `null` | Split generated clients, models, requests, responses, and enums into configured folders |
| `model_classification` | default suffix rules | Customize request/response suffixes and exact class-name category overrides |

## Examples

Check out the [example](example/) directory for a complete working example:

```bash
cd example
dart run openapi_retrofit_generator
dart run build_runner build -d
dart run lib/main.dart
```

## Troubleshooting

### Build Runner Issues

If you encounter issues with `build_runner`, try:

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Generation Errors

Enable verbose output to debug issues:

```bash
dart run openapi_retrofit_generator --verbose
```

### Type Errors

Ensure your OpenAPI spec is valid:
- Use `required` fields correctly
- Define proper types (`string`, `integer`, `object`, etc.)
- Add `nullable: true` for optional fields in OpenAPI 3.0+

## Migration from swagger_parser

This package is a complete rework of `swagger_parser`. To migrate:

1. Update `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     openapi_retrofit_generator: ^2.0.0  # was: swagger_parser
   ```

2. Update config file name and key:
   - Rename `swagger_parser` config key to `openapi_generator` in your YAML files
   - The config file is now `openapi_generator.yaml` (was `swagger_parser.yaml`)

3. Remove deprecated configuration options:
   - **Truly removed** (no longer available):
     - `language: kotlin` - Only Dart generation is supported
     - `replacement_rules` - Replaced by improved automatic naming with conflict resolution. Use proper component names in your OpenAPI schema
   - **Auto-handled** (no longer needed, just delete them):
     - `use_freezed3`, `use_multipart_file`, `enums_to_json`, `enums_parent_prefix`, `dart_mappable_convenient_when`

4. Review default changes:
   - `use_x_nullable` now defaults to `true` (was `false`)
   - `export_file` now defaults to `false` (was `true`)

5. Regenerate your code:
   ```bash
   dart run openapi_retrofit_generator
   dart run build_runner build -d
   ```

**Most configurations will work with minimal changes.** See the [complete changelog](CHANGELOG.md#200) for details.

## Contributing

Contributions are welcome! Here's how you can help:

- **Report bugs**: Open an issue with reproduction steps
- **Request features**: Describe your use case and proposed solution
- **Submit PRs**: Add features, fix bugs, or improve documentation
- **Write tests**: Supplement [E2E tests](test/e2e/) with new scenarios

Before contributing, please:
1. Check existing issues and PRs
2. Follow the existing code style
3. Add tests for new features
4. Update documentation as needed

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

This package is a complete rework of [swagger_parser](https://pub.dev/packages/swagger_parser) ([GitHub](https://github.com/Carapacik/swagger_parser)) originally created by [Carapacik](https://github.com/Carapacik). We've rebuilt the architecture from the ground up while preserving and enhancing all the features that made swagger_parser great.

## Resources

- [Retrofit Documentation](https://pub.dev/packages/retrofit)
- [Dio Documentation](https://pub.dev/packages/dio)
- [OpenAPI Specification](https://swagger.io/specification/)
- [json_serializable](https://pub.dev/packages/json_serializable)
- [Freezed](https://pub.dev/packages/freezed)
- [dart_mappable](https://pub.dev/packages/dart_mappable)
