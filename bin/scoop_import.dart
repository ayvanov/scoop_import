import 'dart:io' show Process, File;
import 'package:args/args.dart';

Future runScoop(List<String> args) async {
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
        final split = line.split(' ');
        if (split.length == 3) {
          final bucket = split[2].substring(1, split[2].length - 2);
          final app = split[0];
          final skip = [1058995764, 872292574].contains(split[0][0].hashCode);
          if (!skip) {
            if (bucket != 'main') {
              apps.add([bucket, app].join('/'));
              buckets.add(bucket);
            } else {
              apps.add(app);
            }
          }
        }
      }
    }
    if (buckets.isNotEmpty) {
      //TODO check if installed
      await runScoop(['install', 'git']);
      for (var bucket in buckets) {
        //TODO check if added
        await runScoop(['bucket', 'add', bucket]);
      }
    }
    if (apps.isNotEmpty) {
      for (var app in apps) {
        //TODO check if installed
        await runScoop(['install', app]);
      }
    }
  }
}
