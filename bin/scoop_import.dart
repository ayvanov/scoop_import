import 'dart:io' show File, Process, ProcessResult, stdout, exit, Platform;
import 'package:args/args.dart';

class Scoop {
  static Future<ProcessResult> run(List<String> args,
      {bool silent = false}) async {
    final arguments = ['scoop'];
    if (args.isNotEmpty) {
      arguments.addAll(args);
    }
    final process = await Process.run('powershell', arguments);
    if (process.exitCode == 0) {
      if (!silent) print(process.stdout);
    } else {
      if (!silent) print(process.stderr);
    }
    return process;
  }

  static Future<bool> isCanRun() async {
    final run = await Scoop.run(['info'], silent: true),
        error = run.stderr.toString();
    if (error.isNotEmpty) {
      if (error.contains("'powershell' is not recognized")) {
        print('Powershell is not installed.');
      }
      if (error.contains("'scoop' is not recognized")) {
        print('Scoop is not installed.');
      }
      return false;
    }
    return true;
  }

  static Future install(String app, {bool silent = false}) async {
    if (!silent) stdout.write('Installing ${app.split('/').last}...');
    final run = await Scoop.run(['install', app], silent: true),
        response = run.stdout.toString(),
        error = run.stderr.toString();
    if (!silent && response.isNotEmpty) {
      if (response.contains('is already installed')) {
        stdout.write('Skipped.\n');
      } else {
        stdout.write('Done.\n');
      }
    }
    if (error.isNotEmpty) {
      print(error);
    }
  }

  static Future bucket(String command, String bucket) async {
    if (command == 'add') {
      stdout.write('Adding $bucket bucket...');
    }
    final run = await Scoop.run(['bucket', command, bucket], silent: true),
        response = run.stdout.toString(),
        error = run.stderr.toString();
    if (response.isNotEmpty) {
      if (response.contains('bucket already exists')) {
        stdout.write('Skipped.\n');
      } else {
        stdout.write('Done.\n');
      }
    }
    if (error.isNotEmpty) {
      print(error);
    }
  }
}

void main(List<String> arguments) async {
  final canRun = await Scoop.isCanRun();
  if (!canRun) exit(1);

  var appsListFileName = '.scoop';
  final appsListFilePath =
      Platform.environment['USERPROFILE'].toString() + '\\$appsListFileName';
  var file;
  var fileExists = false;
  final argParser = ArgParser();
  final args = argParser.parse(arguments);

  if (args.rest.isNotEmpty) {
    file = File(args.rest.toList().first);
  } else {
    file = File(appsListFileName);
    fileExists = file.existsSync();
    if (!fileExists) {
      file = File(appsListFilePath);
    }
  }
  if (fileExists || file.existsSync()) {
    final buckets = <String>{};
    final apps = <String>[];
    final bytes = file.readAsBytesSync();
    final lines = String.fromCharCodes(bytes.buffer.asUint16List()).split('\n');
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

    if (buckets.isNotEmpty) {
      await Scoop.install('git', silent: true);
      for (var bucket in buckets) {
        await Scoop.bucket('add', bucket);
      }
    }

    if (apps.isNotEmpty) {
      for (var app in apps) {
        await Scoop.install(app);
      }
    } else {
      print('Nothing to import.');
    }
  } else {
    print('WARN: [file] is missing');
    print(
        'ERROR: Cannot find exported file in default locations: .\$appsListFileName or $appsListFilePath');
    print('Usage: scoop export > .scoop; Then: scoop-import [file]');
  }
}
