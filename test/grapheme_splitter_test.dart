import 'dart:io';
import 'package:path/path.dart' show dirname, join, normalize;
import 'package:test/test.dart';
import '../lib/grapheme_splitter.dart';

String _scriptPath() {
  var script = Platform.script.toString();
  if (script.startsWith("file://")) {
    script = script.substring(7);
  } else {
    final idx = script.indexOf("file:/");
    script = script.substring(idx + 5);
  }
  return script;
}

int zeroFillRightShift(int n, int amount) {
  return (n & 0xffffffff) >> amount;
}

String ucs2encode(Iterable<int> array) {
  return array.map((value) {
    String output = '';
    if (value > 0xFFFF) {
      value -= 0x10000;
      int newCode = zeroFillRightShift(value, 10) & 0x3FF | 0xD800;
      output += String.fromCharCode(newCode);
      value = 0xDC00 | value & 0x3FF;
    }
    output += String.fromCharCode(value);
    return output;
  }).join('');
}

class _InputExpected {
  final String input;
  final Iterable<String> expected;

  _InputExpected(this.input, this.expected);
}

_InputExpected testDataFromLine(String line) {
  RegExp splitter = new RegExp(r"\s*[×÷]\s*");
  RegExp expectedSplitter = new RegExp(r"\s*÷\s*");
  RegExp expectedInnerSplitter = new RegExp(r"\s*×\s*");
  final codePoints =
      line.split(splitter).map((c) => int.tryParse(c, radix: 16) ?? 0).toList();
  final input = ucs2encode(codePoints);
  final expected = line.split(expectedSplitter).map((sequence) {
    final otherCodePoints = sequence
        .split(expectedInnerSplitter)
        .map((c) => int.tryParse(c, radix: 16) ?? 0)
        .toList();
    return ucs2encode(otherCodePoints);
  }).toList();

  return _InputExpected(input, expected);
}

void main() {
  group("grapheme splitter", () {
    final currentDirectory = dirname(_scriptPath());
    final jsonPath = normalize(join(currentDirectory, "GraphemeBreakTest.txt"));
    final testData = new File(jsonPath)
        .readAsStringSync()
        .split("\n")
        .where(
            (line) => line != null && line.length > 0 && !line.startsWith("#"))
        .map((line) => line.split("#")[0])
        .map(testDataFromLine);

    test("splitGraphemes returns properly split list from string", () {
      final splitter = new GraphemeSplitter();
      testData.forEach((inputExpected) {
        final input = inputExpected.input;
        final expected = inputExpected.expected;
        final result = splitter.splitGraphemes(input);
        expect(result, equals(expected));
      });
    });

    test('iterateGraphemes returns properly split iterator from string',
        () {
      final splitter = new GraphemeSplitter();
      testData.forEach((inputExpected) {
        final input = inputExpected.input;
        final expected = inputExpected.expected;
        final result = splitter.iterateGraphemes(input).toList();
        expect(result, equals(expected));
      });
    });

    test('countGraphemes returns the correct number of graphemes in string',
        () {
      final splitter = new GraphemeSplitter();
      testData.forEach((inputExpected) {
        final input = inputExpected.input;
        final expected = inputExpected.expected;
        final result = splitter.countGraphemes(input);
        expect(result, equals(expected.length));
      });
    });
  });
}
