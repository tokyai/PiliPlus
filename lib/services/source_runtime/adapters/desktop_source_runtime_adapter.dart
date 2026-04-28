import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';
import 'package:path/path.dart' as path;

class DesktopSourceRuntimeAdapter implements SourceRuntimeAdapter {
  static const Duration _defaultProbeTimeout = Duration(seconds: 8);

  @override
  bool get supportsNativeBridge => true;

  @override
  Future<SourceRuntimeResult> probe(SourceEngine engine) async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    final command = _resolveCommand(engine);
    try {
      final output = await Process.run(
        command.command,
        engine.probeArgs,
        runInShell: false,
      ).timeout(_defaultProbeTimeout);
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      return SourceRuntimeResult(
        success: output.exitCode == 0,
        stdout: output.stdout.toString(),
        stderr: output.stderr.toString(),
        elapsedMs: elapsed,
        exitCode: output.exitCode,
        isStub: false,
        message: output.exitCode == 0
            ? '${engine.title} runtime probe passed (${command.source}).'
            : '${engine.title} runtime probe failed (${command.source}).',
      );
    } on ProcessException catch (error) {
      return SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: error.message,
        elapsedMs: DateTime.now().millisecondsSinceEpoch - startedAt,
        exitCode: -1,
        isStub: false,
        message: '${engine.title} command was not found: ${command.command}',
      );
    } on Exception catch (error) {
      return SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: error.toString(),
        elapsedMs: DateTime.now().millisecondsSinceEpoch - startedAt,
        exitCode: -1,
        isStub: false,
        message: '${engine.title} runtime probe timed out or failed.',
      );
    }
  }

  @override
  Future<SourceRuntimeResult> execute(SourceRuntimeRequest request) async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    final plan = _buildExecutionPlan(request);
    if (plan == null) {
      return SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: '',
        elapsedMs: DateTime.now().millisecondsSinceEpoch - startedAt,
        exitCode: -1,
        isStub: true,
        message:
            '${request.engine.title} execute is routed through dedicated bridge. '
            'Use /jarTest or /goProxyTest for this engine.',
      );
    }

    try {
      final output = await Process.run(
        plan.command,
        plan.args,
        runInShell: false,
      ).timeout(request.timeout);
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      return SourceRuntimeResult(
        success: output.exitCode == 0,
        stdout: output.stdout.toString(),
        stderr: output.stderr.toString(),
        elapsedMs: elapsed,
        exitCode: output.exitCode,
        isStub: false,
        message: output.exitCode == 0
            ? '${request.engine.title} execute completed (${plan.source}).'
            : '${request.engine.title} execute failed (${plan.source}).',
      );
    } on ProcessException catch (error) {
      return SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: error.message,
        elapsedMs: DateTime.now().millisecondsSinceEpoch - startedAt,
        exitCode: -1,
        isStub: false,
        message:
            '${request.engine.title} command was not found: ${plan.command}',
      );
    } on Exception catch (error) {
      return SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: error.toString(),
        elapsedMs: DateTime.now().millisecondsSinceEpoch - startedAt,
        exitCode: -1,
        isStub: false,
        message: '${request.engine.title} execute timed out or failed.',
      );
    }
  }

  _ResolvedCommand _resolveCommand(SourceEngine engine) {
    final fallback = _ResolvedCommand(
      command: engine.probeCommand,
      source: 'system:${engine.probeCommand}',
    );

    final relativeCandidates = switch (engine) {
      SourceEngine.python => const <String>[
        'data/python/python.exe',
        'data/python/python',
      ],
      SourceEngine.nodeJs || SourceEngine.catJs => const <String>[
        'data/nodejs/node.exe',
        'data/nodejs/node',
      ],
      SourceEngine.php => const <String>[
        'data/php/php.exe',
        'data/php/php',
      ],
      _ => const <String>[],
    };
    if (relativeCandidates.isEmpty) return fallback;

    for (final root in _runtimeRoots()) {
      for (final relPath in relativeCandidates) {
        final fullPath = path.normalize(path.join(root, relPath));
        if (File(fullPath).existsSync()) {
          return _ResolvedCommand(
            command: fullPath,
            source: 'bundled:$fullPath',
          );
        }
      }
    }
    return fallback;
  }

  _ExecutionPlan? _buildExecutionPlan(SourceRuntimeRequest request) {
    final command = _resolveCommand(request.engine);
    final useCodeMode = request.options['executeAsCode'] == true;
    final payload = request.payload;

    switch (request.engine) {
      case SourceEngine.python:
        if (useCodeMode) {
          return _ExecutionPlan(
            command: command.command,
            args: <String>['-c', payload],
            source: command.source,
          );
        }
        return _ExecutionPlan(
          command: command.command,
          args: <String>[
            '-c',
            'import base64,sys;print(base64.b64decode(sys.argv[1]).decode("utf-8"))',
            base64Encode(utf8.encode(payload)),
          ],
          source: command.source,
        );
      case SourceEngine.nodeJs:
      case SourceEngine.catJs:
        if (useCodeMode) {
          return _ExecutionPlan(
            command: command.command,
            args: <String>['-e', payload],
            source: command.source,
          );
        }
        return _ExecutionPlan(
          command: command.command,
          args: <String>[
            '-e',
            'console.log(Buffer.from(process.argv[1], "base64").toString("utf8"))',
            base64Encode(utf8.encode(payload)),
          ],
          source: command.source,
        );
      case SourceEngine.php:
        if (useCodeMode) {
          return _ExecutionPlan(
            command: command.command,
            args: <String>['-r', payload],
            source: command.source,
          );
        }
        return _ExecutionPlan(
          command: command.command,
          args: <String>[
            '-r',
            r'echo base64_decode($argv[1]) . PHP_EOL;',
            base64Encode(utf8.encode(payload)),
          ],
          source: command.source,
        );
      case SourceEngine.jar:
      case SourceEngine.goProxy:
        return null;
    }
  }

  List<String> _runtimeRoots() {
    final roots = <String>{};

    void add(String candidate) {
      if (candidate.isEmpty) return;
      roots.add(path.normalize(candidate));
    }

    add(Directory.current.path);
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    add(exeDir);
    add(path.dirname(exeDir));

    return roots.toList(growable: false);
  }
}

class _ResolvedCommand {
  const _ResolvedCommand({
    required this.command,
    required this.source,
  });

  final String command;
  final String source;
}

class _ExecutionPlan {
  const _ExecutionPlan({
    required this.command,
    required this.args,
    required this.source,
  });

  final String command;
  final List<String> args;
  final String source;
}
