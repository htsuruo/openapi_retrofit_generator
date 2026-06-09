import 'package:openapi_retrofit_generator/openapi_retrofit_generator.dart';
import 'package:openapi_retrofit_generator/src/config/config_processor.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('OpenApiConfig', () {
    group('Constructor', () {
      test('should create config with required parameters', () {
        const config = OpenApiConfig(outputDirectory: 'lib/api');

        expect(config.outputDirectory, equals('lib/api'));
        expect(config.schemaPath, isNull);
        expect(config.schemaUrl, isNull);
        expect(config.name, equals('api'));
        expect(config.jsonSerializer, equals(JsonSerializer.jsonSerializable));
        expect(config.rootClient, isTrue);
        expect(config.rootClientName, equals('RestClient'));
        expect(config.clientPostfix, isNull);
        expect(config.exportFile, isFalse);
        expect(config.putClientsInFolder, isFalse);
        expect(config.unknownEnumValue, isTrue);
        expect(config.markFilesAsGenerated, isTrue);
        expect(config.originalHttpResponse, isFalse);
        expect(config.defaultContentType, equals('application/json'));
        expect(config.extrasParameterByDefault, isFalse);
        expect(config.dioOptionsParameterByDefault, isFalse);
        expect(config.pathMethodName, isFalse);
        expect(config.mergeClients, isFalse);
        expect(config.skippedParameters, isEmpty);
        expect(config.generateValidator, isFalse);
        expect(config.useXNullable, isTrue);
        expect(config.fallbackUnion, isNull);
        expect(config.excludeTags, isEmpty);
        expect(config.includeTags, isEmpty);
        expect(config.defaultClient, 'api');
        expect(config.includeIfNull, isFalse);
      });
    });

    group('fromYaml factory constructor', () {
      group('Valid configurations', () {
        test('should create config from minimal YAML as root config', () {
          final yamlMap = YamlMap.wrap({'output_directory': 'lib/api'});

          final config = OpenApiConfig.fromYaml(yamlMap, isRootConfig: true);

          expect(config.outputDirectory, equals('lib/api'));
          expect(config.name, equals(''));
          expect(config.schemaPath, isNull);
          expect(config.schemaUrl, isNull);
        });

        test(
          'should generate name from schema_path when name not provided',
          () {
            final yamlMap = YamlMap.wrap({
              'schema_path': 'api/petstore.yaml',
              'output_directory': 'lib/api',
            });

            final config = OpenApiConfig.fromYaml(yamlMap);

            expect(config.name, equals('petstore'));
          },
        );

        test('should generate name from schema_url when name not provided', () {
          final yamlMap = YamlMap.wrap({
            'schema_url': 'https://api.example.com/user-service.json',
            'output_directory': 'lib/api',
          });

          final config = OpenApiConfig.fromYaml(yamlMap);

          expect(config.name, equals('user-service'));
        });

        test('should handle empty name by using schema path', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/custom.yaml',
            'output_directory': 'lib/api',
            'name': '',
          });

          final config = OpenApiConfig.fromYaml(yamlMap);

          expect(config.name, equals('custom'));
        });

        test('should trim client_postfix', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': 'lib/api',
            'client_postfix': '  Service  ',
          });

          final config = OpenApiConfig.fromYaml(yamlMap);

          expect(config.clientPostfix, equals('Service'));
        });

        test('should parse output layout and model classification', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': 'lib/api',
            'output_layout': {
              'clients': 'rest_clients',
              'models': 'entities',
              'requests': 'inputs',
              'responses': 'outputs',
              'enums': 'options',
            },
            'model_classification': {
              'request_suffixes': ['Input'],
              'response_suffixes': ['Result'],
              'overrides': {'SpecialModel': 'models', 'SpecialEnum': 'enums'},
            },
          });

          final config = OpenApiConfig.fromYaml(yamlMap);

          expect(config.outputLayout?.clients, equals('rest_clients'));
          expect(config.outputLayout?.models, equals('entities'));
          expect(config.outputLayout?.requests, equals('inputs'));
          expect(config.outputLayout?.responses, equals('outputs'));
          expect(config.outputLayout?.enums, equals('options'));
          expect(config.modelClassification.requestSuffixes, equals(['Input']));
          expect(
            config.modelClassification.responseSuffixes,
            equals(['Result']),
          );
          expect(
            config.modelClassification.overrides,
            equals({'SpecialModel': 'models', 'SpecialEnum': 'enums'}),
          );
        });
      });

      group('Root config inheritance', () {
        test('should inherit output_directory from root config', () {
          const rootConfig = OpenApiConfig(outputDirectory: 'lib/shared');

          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/user.yaml',
            'name': 'user_api',
          });

          final config = OpenApiConfig.fromYaml(
            yamlMap,
            rootConfig: rootConfig,
          );

          expect(config.outputDirectory, equals('lib/shared'));
          expect(config.schemaPath, equals('api/user.yaml'));
          expect(config.name, equals('user_api'));
        });

        test(
          'should override root config output_directory with local value',
          () {
            const rootConfig = OpenApiConfig(outputDirectory: 'lib/shared');

            final yamlMap = YamlMap.wrap({
              'schema_path': 'api/user.yaml',
              'output_directory': 'lib/custom',
            });

            final config = OpenApiConfig.fromYaml(
              yamlMap,
              rootConfig: rootConfig,
            );

            expect(config.outputDirectory, equals('lib/custom'));
          },
        );
      });

      group('Output directory combinations', () {
        test('should accept valid output_directory for root config', () {
          final yamlMap = YamlMap.wrap({'output_directory': 'lib/api'});

          final config = OpenApiConfig.fromYaml(yamlMap, isRootConfig: true);

          expect(config.outputDirectory, equals('lib/api'));
        });

        test(
          'should accept output_directory for non-root config with schema_path',
          () {
            final yamlMap = YamlMap.wrap({
              'schema_path': 'api/openapi.yaml',
              'output_directory': 'lib/api',
            });

            final config = OpenApiConfig.fromYaml(yamlMap);

            expect(config.outputDirectory, equals('lib/api'));
            expect(config.schemaPath, equals('api/openapi.yaml'));
          },
        );

        test(
          'should accept output_directory for non-root config with schema_url',
          () {
            final yamlMap = YamlMap.wrap({
              'schema_url': 'https://api.example.com/openapi.json',
              'output_directory': 'lib/api',
            });

            final config = OpenApiConfig.fromYaml(yamlMap);

            expect(config.outputDirectory, equals('lib/api'));
            expect(
              config.schemaUrl,
              equals('https://api.example.com/openapi.json'),
            );
          },
        );

        test('should use inherited output_directory when local is null', () {
          const rootConfig = OpenApiConfig(outputDirectory: 'lib/shared');

          final yamlMap = YamlMap.wrap({'schema_path': 'api/user.yaml'});

          final config = OpenApiConfig.fromYaml(
            yamlMap,
            rootConfig: rootConfig,
          );

          expect(config.outputDirectory, equals('lib/shared'));
        });

        test('should accept empty string output_directory for root config', () {
          final yamlMap = YamlMap.wrap({'output_directory': ''});

          final config = OpenApiConfig.fromYaml(yamlMap, isRootConfig: true);

          expect(config.outputDirectory, equals(''));
        });

        test(
          'should throw when output_directory is null and no root config for non-root config',
          () {
            final yamlMap = YamlMap.wrap({'schema_path': 'api/openapi.yaml'});

            expect(
              () => OpenApiConfig.fromYaml(yamlMap),
              throwsA(isA<ConfigException>()),
            );
          },
        );

        test(
          'should throw when output_directory is empty string with no root config for non-root config',
          () {
            final yamlMap = YamlMap.wrap({
              'schema_path': 'api/openapi.yaml',
              'output_directory': '',
            });

            expect(
              () => OpenApiConfig.fromYaml(yamlMap),
              throwsA(isA<ConfigException>()),
            );
          },
        );

        test('should handle dot as output_directory', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': '.',
          });

          final config = OpenApiConfig.fromYaml(yamlMap);

          expect(config.outputDirectory, equals('.'));
        });

        test('should handle relative path as output_directory', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': '../generated',
          });

          final config = OpenApiConfig.fromYaml(yamlMap);

          expect(config.outputDirectory, equals('../generated'));
        });

        test('should handle absolute path as output_directory', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': '/absolute/path/lib/api',
          });

          final config = OpenApiConfig.fromYaml(yamlMap);

          expect(config.outputDirectory, equals('/absolute/path/lib/api'));
        });
      });
    });

    group('Error handling', () {
      test(
        'should throw ConfigException when neither schema_path nor schema_url provided for non-root config',
        () {
          final yamlMap = YamlMap.wrap({'output_directory': 'lib/api'});

          expect(
            () => OpenApiConfig.fromYaml(yamlMap),
            throwsA(
              isA<ConfigException>().having(
                (e) => e.message,
                'message',
                equals(
                  "Config parameters 'schema_path' or 'schema_url' are required.",
                ),
              ),
            ),
          );
        },
      );

      test(
        'should throw ConfigException when output_directory missing for non-root config',
        () {
          final yamlMap = YamlMap.wrap({'schema_path': 'api/openapi.yaml'});

          expect(
            () => OpenApiConfig.fromYaml(yamlMap),
            throwsA(
              isA<ConfigException>().having(
                (e) => e.message,
                'message',
                contains(
                  "Config parameter 'output_directory' for api/openapi.yaml was not found",
                ),
              ),
            ),
          );
        },
      );

      test(
        'should throw ConfigException when output_directory is empty string for non-root config',
        () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': '',
          });

          expect(
            () => OpenApiConfig.fromYaml(yamlMap),
            throwsA(
              isA<ConfigException>().having(
                (e) => e.message,
                'message',
                contains(
                  "Config parameter 'output_directory' for api/openapi.yaml was not found",
                ),
              ),
            ),
          );
        },
      );

      test(
        'should throw ConfigException for invalid skipped_parameters type',
        () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': 'lib/api',
            'skipped_parameters': [123, 'valid'],
          });

          expect(
            () => OpenApiConfig.fromYaml(yamlMap),
            throwsA(
              isA<ConfigException>().having(
                (e) => e.message,
                'message',
                equals(
                  "Config parameter 'skipped_parameters' values must be List of String.",
                ),
              ),
            ),
          );
        },
      );

      test('should throw ConfigException for invalid exclude_tags type', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'exclude_tags': ['valid', 123],
        });

        expect(
          () => OpenApiConfig.fromYaml(yamlMap),
          throwsA(
            isA<ConfigException>().having(
              (e) => e.message,
              'message',
              equals(
                "Config parameter 'exclude_tags' values must be List of String.",
              ),
            ),
          ),
        );
      });

      test('should throw ConfigException for invalid include_tags type', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'include_tags': [123],
        });

        expect(
          () => OpenApiConfig.fromYaml(yamlMap),
          throwsA(
            isA<ConfigException>().having(
              (e) => e.message,
              'message',
              equals(
                "Config parameter 'include_tags' values must be List of String.",
              ),
            ),
          ),
        );
      });
    });

    group('Edge cases', () {
      test('should handle null values in YAML gracefully', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'name': null,
          'client_postfix': null,
          'fallback_union': null,
          'skipped_parameters': null,
          'exclude_tags': null,
          'include_tags': null,
        });

        final config = OpenApiConfig.fromYaml(yamlMap);

        expect(config.name, equals('openapi'));
        expect(config.clientPostfix, isNull);
        expect(config.fallbackUnion, isNull);
        expect(config.skippedParameters, isEmpty);
        expect(config.excludeTags, isEmpty);
        expect(config.includeTags, isEmpty);
      });

      test('should handle empty lists in YAML', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'skipped_parameters': <String>[],
          'exclude_tags': <String>[],
          'include_tags': <String>[],
        });

        final config = OpenApiConfig.fromYaml(yamlMap);

        expect(config.skippedParameters, isEmpty);
        expect(config.excludeTags, isEmpty);
        expect(config.includeTags, isEmpty);
      });
    });
  });

  group('fromYamlWithOverrides factory constructor', () {
    test('should apply CLI overrides to YAML config', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'name': 'original_name',
        'root_client': true,
      });

      final argResults = parseConfigGeneratorArguments([
        '--schema_path',
        'foo/bar.yaml',
        '--output_directory',
        'lib/foo',
      ]);

      final config = OpenApiConfig.fromYamlWithOverrides(yamlMap, argResults);

      expect(config.outputDirectory, equals('lib/foo'));
      expect(config.schemaPath, equals('foo/bar.yaml'));
      expect(config.name, equals('original_name'));
      expect(config.rootClient, isTrue);
    });

    test('should work with null argResults', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'name': 'test_name',
      });

      final config = OpenApiConfig.fromYamlWithOverrides(yamlMap, null);

      expect(config.name, equals('test_name'));
      expect(config.outputDirectory, equals('lib/api'));
      expect(config.schemaPath, equals('api/openapi.yaml'));
    });

    test('should support all constructor parameters', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
      });

      const rootConfig = OpenApiConfig(outputDirectory: 'lib/shared');

      final config = OpenApiConfig.fromYamlWithOverrides(
        yamlMap,
        null,
        rootConfig: rootConfig,
      );

      expect(config.schemaPath, equals('api/openapi.yaml'));
      expect(config.outputDirectory, equals('lib/api'));
    });
  });

  group('toGeneratorConfig method', () {
    test('should handle null values correctly', () {
      const swpConfig = OpenApiConfig(outputDirectory: 'lib/api');

      final generatorConfig = swpConfig.toGeneratorConfig();

      expect(generatorConfig.clientPostfix, isNull);
      expect(generatorConfig.fallbackUnion, isNull);
    });
  });

  group('toParserConfig method', () {
    test('should convert OpenApiConfig to ParserConfig correctly', () {
      final swpConfig = OpenApiConfig(
        outputDirectory: 'lib/api',
        name: 'my_api',
        defaultContentType: 'application/xml',
        pathMethodName: true,
        mergeClients: true,
        skippedParameters: ['id', 'timestamp'],
        useXNullable: true,
        excludeTags: ['internal'],
        includeTags: ['public'],
        defaultClient: 'common',
      );

      const fileContent = '{"openapi": "3.0.0"}';
      const isJson = true;

      final parserConfig = swpConfig.toParserConfig(
        fileContent: fileContent,
        isJson: isJson,
      );

      expect(parserConfig.fileContent, equals(fileContent));
      expect(parserConfig.isJson, equals(isJson));
      expect(parserConfig.name, equals('my_api'));
      expect(parserConfig.defaultContentType, equals('application/xml'));
      expect(parserConfig.pathMethodName, isTrue);
      expect(parserConfig.mergeClients, isTrue);
      expect(parserConfig.skippedParameters, equals(['id', 'timestamp']));
      expect(parserConfig.useXNullable, isTrue);
      expect(parserConfig.excludeTags, equals(['internal']));
      expect(parserConfig.includeTags, equals(['public']));
      expect(parserConfig.defaultClient, equals('common'));
    });

    test('should handle YAML file content', () {
      const swpConfig = OpenApiConfig(outputDirectory: 'lib/api');
      const fileContent = 'openapi: 3.0.0';
      const isJson = false;

      final parserConfig = swpConfig.toParserConfig(
        fileContent: fileContent,
        isJson: isJson,
      );

      expect(parserConfig.fileContent, equals(fileContent));
      expect(parserConfig.isJson, isFalse);
    });
  });

  group('Enum parsing', () {
    test('should parse json serializer from string', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'json_serializer': 'dart_mappable',
      });

      final config = OpenApiConfig.fromYaml(yamlMap);

      expect(config.jsonSerializer, equals(JsonSerializer.dartMappable));
    });

    test('should handle unknown enum values gracefully', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'language': 'unknown_language',
      });

      // This should not throw but use default or handle gracefully
      expect(
        () => OpenApiConfig.fromYaml(yamlMap),
        isNot(throwsA(isA<ConfigException>())),
      );
    });
  });

  group('Include If Null Configuration', () {
    test('should default includeIfNull to false', () {
      const config = OpenApiConfig(outputDirectory: 'lib/api');
      expect(config.includeIfNull, isFalse);
    });

    test('should parse includeIfNull from YAML when set to true', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'include_if_null': true,
      });

      final config = OpenApiConfig.fromYaml(yamlMap);
      expect(config.includeIfNull, isTrue);
    });

    test('should parse includeIfNull from YAML when set to false', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'include_if_null': false,
      });

      final config = OpenApiConfig.fromYaml(yamlMap);
      expect(config.includeIfNull, isFalse);
    });

    test('should inherit includeIfNull from root config', () {
      const rootConfig = OpenApiConfig(
        outputDirectory: 'lib/shared',
        includeIfNull: true,
      );

      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/user.yaml',
        'name': 'user_api',
      });

      final config = OpenApiConfig.fromYaml(yamlMap, rootConfig: rootConfig);
      expect(config.includeIfNull, isTrue);
    });

    test('should override root config includeIfNull with local value', () {
      const rootConfig = OpenApiConfig(
        outputDirectory: 'lib/shared',
        includeIfNull: true,
      );

      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/user.yaml',
        'include_if_null': false,
      });

      final config = OpenApiConfig.fromYaml(yamlMap, rootConfig: rootConfig);
      expect(config.includeIfNull, isFalse);
    });

    test('should pass includeIfNull to GeneratorConfig', () {
      const swpConfig = OpenApiConfig(
        outputDirectory: 'lib/api',
        includeIfNull: true,
      );

      final generatorConfig = swpConfig.toGeneratorConfig();
      expect(generatorConfig.includeIfNull, isTrue);
    });
  });

  group('ConfigProcessor', () {
    group('parseConfig with schemes', () {
      const processor = ConfigProcessor();

      test('should parse single schema without schemes', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'name': 'my_api',
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(1));
        expect(configs[0].schemaPath, equals('api/openapi.yaml'));
        expect(configs[0].outputDirectory, equals('lib/api'));
        expect(configs[0].name, equals('my_api'));
      });

      test('should parse multiple schemas with schemes', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
          'schemes': [
            {'schema_path': 'api/users.yaml', 'name': 'users'},
            {'schema_path': 'api/posts.yaml', 'name': 'posts'},
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(2));
        expect(configs[0].schemaPath, equals('api/users.yaml'));
        expect(configs[0].name, equals('users'));
        expect(configs[0].outputDirectory, equals('lib/api'));
        expect(configs[1].schemaPath, equals('api/posts.yaml'));
        expect(configs[1].name, equals('posts'));
        expect(configs[1].outputDirectory, equals('lib/api'));
      });

      test('should inherit root config settings in schemes', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/shared',
          'json_serializer': 'freezed',
          'client_postfix': 'Client',
          'schemes': [
            {'schema_path': 'api/users.yaml', 'name': 'users'},
            {
              'schema_path': 'api/posts.yaml',
              'name': 'posts',
              'json_serializer': 'dart_mappable',
            },
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(2));
        expect(configs[0].jsonSerializer, equals(JsonSerializer.freezed));
        expect(configs[0].clientPostfix, equals('Client'));
        expect(configs[0].outputDirectory, equals('lib/shared'));
        expect(configs[1].jsonSerializer, equals(JsonSerializer.dartMappable));
        expect(configs[1].clientPostfix, equals('Client'));
        expect(configs[1].outputDirectory, equals('lib/shared'));
      });

      test('should allow schema to override root config', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/shared',
          'json_serializer': 'json_serializable',
          'schemes': [
            {
              'schema_path': 'api/users.yaml',
              'output_directory': 'lib/users',
              'json_serializer': 'freezed',
            },
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(1));
        expect(configs[0].outputDirectory, equals('lib/users'));
        expect(configs[0].jsonSerializer, equals(JsonSerializer.freezed));
      });

      test('should parse schema_url in schemes', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
          'schemes': [
            {
              'schema_url': 'https://api.example.com/users.json',
              'name': 'users',
            },
            {
              'schema_url': 'https://api.example.com/posts.json',
              'name': 'posts',
            },
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(2));
        expect(
          configs[0].schemaUrl,
          equals('https://api.example.com/users.json'),
        );
        expect(
          configs[1].schemaUrl,
          equals('https://api.example.com/posts.json'),
        );
      });

      test('should handle mix of schema_path and schema_url in schemes', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
          'schemes': [
            {'schema_path': 'api/users.yaml', 'name': 'users'},
            {
              'schema_url': 'https://api.example.com/posts.json',
              'name': 'posts',
            },
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(2));
        expect(configs[0].schemaPath, equals('api/users.yaml'));
        expect(configs[0].schemaUrl, isNull);
        expect(configs[1].schemaPath, isNull);
        expect(
          configs[1].schemaUrl,
          equals('https://api.example.com/posts.json'),
        );
      });
    });

    group('parseConfig error handling', () {
      const processor = ConfigProcessor();

      test(
        'should throw when neither schema_path, schema_url, nor schemes provided',
        () {
          final yamlMap = YamlMap.wrap({'output_directory': 'lib/api'});

          expect(
            () => processor.parseConfig(yamlMap),
            throwsA(
              isA<ConfigException>().having(
                (e) => e.message,
                'message',
                equals(
                  "Config parameter 'schema_path', 'schema_url' or 'schemes' is required.",
                ),
              ),
            ),
          );
        },
      );

      test('should throw when schemes used with schema_path', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'schemes': [
            {'schema_path': 'api/users.yaml'},
          ],
        });

        expect(
          () => processor.parseConfig(yamlMap),
          throwsA(
            isA<ConfigException>().having(
              (e) => e.message,
              'message',
              equals(
                "Config parameter 'schema_path' or 'schema_url' can't be used with 'schemes'.",
              ),
            ),
          ),
        );
      });

      test('should throw when schemes used with schema_url', () {
        final yamlMap = YamlMap.wrap({
          'schema_url': 'https://api.example.com/openapi.json',
          'output_directory': 'lib/api',
          'schemes': [
            {'schema_path': 'api/users.yaml'},
          ],
        });

        expect(
          () => processor.parseConfig(yamlMap),
          throwsA(
            isA<ConfigException>().having(
              (e) => e.message,
              'message',
              equals(
                "Config parameter 'schema_path' or 'schema_url' can't be used with 'schemes'.",
              ),
            ),
          ),
        );
      });

      test('should throw when schemes contains non-map values', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
          'schemes': ['api/users.yaml', 'api/posts.yaml'],
        });

        expect(
          () => processor.parseConfig(yamlMap),
          throwsA(
            isA<ConfigException>().having(
              (e) => e.message,
              'message',
              equals("Config parameter 'schemes' must be list of maps."),
            ),
          ),
        );
      });

      test('should return empty list when schemes is empty', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
          'schemes': <Map<String, dynamic>>[],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, isEmpty);
      });

      test(
        'should throw when schema in schemes missing schema_path and schema_url',
        () {
          final yamlMap = YamlMap.wrap({
            'output_directory': 'lib/api',
            'schemes': [
              {'name': 'users'},
            ],
          });

          expect(
            () => processor.parseConfig(yamlMap),
            throwsA(isA<ConfigException>()),
          );
        },
      );
    });

    group('parseConfig with CLI overrides', () {
      const processor = ConfigProcessor();

      test('should apply CLI overrides to single schema', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'name': 'original',
        });

        final argResults = parseConfigGeneratorArguments([
          '--output_directory',
          'lib/overridden',
        ]);

        final configs = processor.parseConfig(yamlMap, argResults);

        expect(configs, hasLength(1));
        expect(configs[0].outputDirectory, equals('lib/overridden'));
        expect(configs[0].name, equals('original'));
      });

      test(
        'should apply CLI overrides to root config which affects schemes inheritance',
        () {
          final yamlMap = YamlMap.wrap({
            'output_directory': 'lib/api',
            'json_serializer': 'json_serializable',
            'schemes': [
              {'schema_path': 'api/users.yaml', 'name': 'users'},
            ],
          });

          final argResults = parseConfigGeneratorArguments([
            '--json_serializer',
            'freezed',
          ]);

          final configs = processor.parseConfig(yamlMap, argResults);

          expect(configs, hasLength(1));
          expect(configs[0].name, equals('users'));
          expect(configs[0].jsonSerializer, equals(JsonSerializer.freezed));
        },
      );
    });

    group('parseConfig complex scenarios', () {
      const processor = ConfigProcessor();

      test('should handle multiple schemes with different serializers', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
          'json_serializer': 'json_serializable',
          'schemes': [
            {
              'schema_path': 'api/users.yaml',
              'name': 'users',
              'json_serializer': 'freezed',
            },
            {
              'schema_path': 'api/posts.yaml',
              'name': 'posts',
              'json_serializer': 'dart_mappable',
            },
            {'schema_path': 'api/comments.yaml', 'name': 'comments'},
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(3));
        expect(configs[0].jsonSerializer, equals(JsonSerializer.freezed));
        expect(configs[1].jsonSerializer, equals(JsonSerializer.dartMappable));
        expect(
          configs[2].jsonSerializer,
          equals(JsonSerializer.jsonSerializable),
        );
      });

      test('should handle schemes with different output directories', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/shared',
          'schemes': [
            {'schema_path': 'api/users.yaml', 'output_directory': 'lib/users'},
            {'schema_path': 'api/posts.yaml', 'output_directory': 'lib/posts'},
            {'schema_path': 'api/comments.yaml'},
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(3));
        expect(configs[0].outputDirectory, equals('lib/users'));
        expect(configs[1].outputDirectory, equals('lib/posts'));
        expect(configs[2].outputDirectory, equals('lib/shared'));
      });

      test('should handle schemes with all configuration options', () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
          'json_serializer': 'json_serializable',
          'root_client': true,
          'client_postfix': 'Client',
          'schemes': [
            {
              'schema_path': 'api/users.yaml',
              'name': 'users',
              'output_directory': 'lib/users',
              'json_serializer': 'freezed',
              'root_client': false,
              'client_postfix': 'Service',
            },
          ],
        });

        final configs = processor.parseConfig(yamlMap);

        expect(configs, hasLength(1));
        expect(configs[0].outputDirectory, equals('lib/users'));
        expect(configs[0].jsonSerializer, equals(JsonSerializer.freezed));
        expect(configs[0].rootClient, isFalse);
        expect(configs[0].clientPostfix, equals('Service'));
      });
    });
  });
}
