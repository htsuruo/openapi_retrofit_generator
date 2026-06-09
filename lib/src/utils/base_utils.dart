import 'package:openapi_retrofit_generator/src/parser/model/normalized_identifier.dart';

const _primitiveTypes = {
  'int',
  'double',
  'num',
  'String',
  'bool',
  'DateTime',
  'Object',
  'dynamic',
  'void',
  'MultipartFile',
  'Uint8List',
};

/// Resolves a parser import name to a Dart import path.
typedef DartImportPathResolver = String Function(String import);

/// Provides imports as String from list of imports
String dartImports({
  required Set<String> imports,
  String? pathPrefix,
  DartImportPathResolver? importPathResolver,
}) {
  if (imports.isEmpty) {
    return '';
  }
  final filteredImports = imports.where(
    (import) => !_primitiveTypes.contains(import),
  );
  if (filteredImports.isEmpty) {
    return '';
  }
  return '\n${filteredImports.map((import) {
    final path = importPathResolver?.call(import) ?? '${pathPrefix ?? ''}${import.toSnake}.dart';
    return "import '$path';";
  }).join('\n')}\n';
}

String indentation(int length) => ' ' * length;

/// Provides description
String descriptionComment(
  String? description, {
  bool tabForFirstLine = true,
  String tab = '',
  String end = '',
}) {
  if (description == null || description.isEmpty) {
    return '';
  }

  final lineStart = RegExp('^(.*)', multiLine: true);

  final result = description.replaceAllMapped(
    lineStart,
    (m) =>
        '${!tabForFirstLine && m.start == 0 ? '' : tab}///${m[1]!.trim().isEmpty ? '' : ' '}${m.start == 0 && m.end == description.length ? m[1] : addDot(m[1])}',
  );

  return '$result\n$end';
}

/// Add dot to string if not exist
/// https://dart.dev/effective-dart/documentation#do-format-comments-like-sentences
String? addDot(String? text) =>
    text != null && text.trim().isNotEmpty && !_punctuationRegExp.hasMatch(text)
    ? '$text.'
    : text;

/// RegExp for punctuation marks in the end of string
final _punctuationRegExp = RegExp(r'[.!?]$');

/// Replace all not english letters in text
String? replaceNotEnglishLetter(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  final lettersRegex = RegExp('[^a-zA-Z]');
  return text.replaceAll(lettersRegex, ' ');
}

String formatNumber(int number) => number.toString().replaceAllMapped(
  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]} ',
);

String generatedFileComment() => '$_generatedCodeComment$_ignoreLintsComment\n';

const _generatedCodeComment = '''
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
''';

const _ignoreLintsComment = '''
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import
''';
