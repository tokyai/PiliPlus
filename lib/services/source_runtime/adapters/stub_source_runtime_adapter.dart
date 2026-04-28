import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';

class StubSourceRuntimeAdapter implements SourceRuntimeAdapter {
  const StubSourceRuntimeAdapter({
    required this.reason,
  });

  final String reason;

  @override
  bool get supportsNativeBridge => false;

  @override
  Future<SourceRuntimeResult> probe(SourceEngine engine) async =>
      SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: '',
        elapsedMs: 0,
        exitCode: -1,
        isStub: true,
        message: 'Probe skipped for ${engine.title}. $reason',
      );

  @override
  Future<SourceRuntimeResult> execute(SourceRuntimeRequest request) async =>
      SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: '',
        elapsedMs: 0,
        exitCode: -1,
        isStub: true,
        message:
            'Execute skipped for ${request.engine.title}. '
            'Payload was captured for migration debugging. $reason',
      );
}
