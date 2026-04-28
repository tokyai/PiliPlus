import 'dart:io';

import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';

class DesktopSourceRuntimeAdapter implements SourceRuntimeAdapter {
  @override
  bool get supportsNativeBridge => true;

  @override
  Future<SourceRuntimeResult> probe(SourceEngine engine) async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    try {
      final output = await Process.run(
        engine.probeCommand,
        engine.probeArgs,
        runInShell: false,
      ).timeout(const Duration(seconds: 8));
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      return SourceRuntimeResult(
        success: output.exitCode == 0,
        stdout: output.stdout.toString(),
        stderr: output.stderr.toString(),
        elapsedMs: elapsed,
        exitCode: output.exitCode,
        isStub: false,
        message: output.exitCode == 0
            ? '${engine.title} runtime probe passed.'
            : '${engine.title} runtime probe failed.',
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
            '${engine.title} command was not found: ${engine.probeCommand}',
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
    const elapsed = 1;
    return SourceRuntimeResult(
      success: true,
      stdout:
          'Desktop adapter execute stub.\n'
          'engine=${request.engine.key}\n'
          'payload=${request.payload}',
      stderr: '',
      elapsedMs: elapsed,
      exitCode: 0,
      isStub: true,
      message:
          'Execution pipeline placeholder only. '
          'Phase 3 will bind real Node/Python/PHP process orchestration.',
    );
  }
}
