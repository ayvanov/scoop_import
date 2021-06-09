import 'dart:io' show Process, File;
import 'package:args/args.dart';

void runScoop(List<String> args) async {
  final process = await Process.run('powershell', ['scoop', ...args]);
  if (process.exitCode == 0) {
    print(process.stdout);
  } else {
    print(process.stderr);
  }
}

void main(List<String> arguments) async {
  final argParser = ArgParser();
  final args = argParser.parse(arguments);
  if (args.rest.isNotEmpty) {
    final path = args.rest.toList().first;
    final file = File(path);
    final buckets = <String>{};
    final apps = <String>[];
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      final lines =
          String.fromCharCodes(bytes.buffer.asUint16List()).split('\n');
      for (var line in lines) {
        final lineArr = line.split(' ');
        if (lineArr.length == 3) {
          final bucket = lineArr[2].substring(1, lineArr[2].length - 2);
          apps.add([bucket, lineArr[0]].join('/'));
          buckets.add(bucket);
        }
      }
    }
    if (buckets.isNotEmpty) {
      for (var bucket in buckets) {
        runScoop(['install', 'git']);
        runScoop(['bucket', 'add', bucket]);
      }
    }
    if (apps.isNotEmpty) {
      for (var app in apps) {
        runScoop(['install', app]);
      }
    }
  }
}
