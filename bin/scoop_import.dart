import 'package:http/http.dart' as http;
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
  final userHome = Platform.environment['USERPROFILE'].toString();
  final appsListFilePath = userHome + '\\$appsListFileName';
  var file;
  var fileExists = false;
  var lines = <String>[];
  final argParser = ArgParser();
  final restArgs = argParser.parse(arguments).rest;

  if (restArgs.isNotEmpty) {
    var uri = Uri.parse(restArgs.first);
    if (['http', 'https'].contains(uri.scheme.toLowerCase())) {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        print('ERROR: ${response.reasonPhrase}');
        exit(1);
      }
      print('Using remote file: ${uri.pathSegments.last}');
      if (response.contentLength! > 0) {
        final contentType = response.headers.entries.singleWhere((element) {
          return element.key == 'content-type';
        });
        if (contentType.value.contains('application/octet-stream')) {
          lines = String.fromCharCodes(response.bodyBytes.buffer.asUint16List())
              .split('\n');
        } else if (contentType.value.contains('text/plain')) {
          lines = response.body.split('\n');
        }
      } else {
        print('Remote file is empty.');
      }
    } else {
      file = File(restArgs.first);
      fileExists = file.existsSync();
      if (!fileExists) {
        print('ERROR: File does not exists: ${restArgs.first}');
        exit(1);
      }
    }
  } else {
    file = File(appsListFileName);
    fileExists = file.existsSync();
    if (!fileExists) {
      file = File(appsListFilePath);
      fileExists = file.existsSync();
      if (fileExists) {
        print('Using $appsListFilePath file');
      }
    } else {
      print('Using $appsListFileName file');
    }
  }
  if (lines.isEmpty && fileExists) {
    final bytes = file.readAsBytesSync();
    lines = String.fromCharCodes(bytes.buffer.asUint16List()).split('\n');
  }
  if (lines.isNotEmpty) {
    final buckets = <String>{};
    final apps = <String>[];

    for (var line in lines) {
      final split = line.split(' ');
      if (split.length == 3) {
        final bucket = split.last.trim().replaceAll(RegExp('\\[|\\]'), '');
        var app = split.first.trim().replaceAll(RegExp('[^a-zA-Z0-9-_]'), '');
        if (bucket != 'main') {
          var uri = Uri.parse(bucket);
          if (['http', 'https'].contains(uri.scheme.toLowerCase())) {
            apps.add(bucket);
          } else {
            apps.add([bucket, app].join('/'));
            buckets.add(bucket);
          }
        } else {
          apps.add(app);
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
    print('Usage: scoop-import [file|url]');
    print('WARN: [file|url] is missing');
    print(
        'ERROR: Cannot find $appsListFileName file in current folder or in $userHome');
    print('Example usage: scoop export > .scoop; Then: scoop-import');
  }
}
