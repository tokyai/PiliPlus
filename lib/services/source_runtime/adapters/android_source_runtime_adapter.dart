import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/services/source_runtime/adapters/stub_source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';
import 'package:flutter/services.dart';

class AndroidSourceRuntimeAdapter implements SourceRuntimeAdapter {
  AndroidSourceRuntimeAdapter({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(Constants.appName);

  final MethodChannel _channel;

  @override
  bool get supportsNativeBridge => true;

  @override
  Future<SourceRuntimeResult> probe(SourceEngine engine) async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'sourceRuntimeProbe',
        {
          'engine': engine.key,
        },
      );
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      return _parseResult(
        response ?? const <String, dynamic>{},
        elapsedMs: elapsed,
      );
    } on MissingPluginException {
      return _fallbackStub().probe(engine);
    } on PlatformException catch (error) {
      return SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: error.message ?? error.code,
        elapsedMs: DateTime.now().millisecondsSinceEpoch - startedAt,
        exitCode: -1,
        isStub: false,
        message: 'Android probe call failed.',
      );
    }
  }

  @override
  Future<SourceRuntimeResult> execute(SourceRuntimeRequest request) async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'sourceRuntimeExecute',
        request.toMap(),
      );
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      return _parseResult(
        response ?? const <String, dynamic>{},
        elapsedMs: elapsed,
      );
    } on MissingPluginException {
      return _fallbackStub().execute(request);
    } on PlatformException catch (error) {
      return SourceRuntimeResult(
        success: false,
        stdout: '',
        stderr: error.message ?? error.code,
        elapsedMs: DateTime.now().millisecondsSinceEpoch - startedAt,
        exitCode: -1,
        isStub: false,
        message: 'Android execute call failed.',
      );
    }
  }

  SourceRuntimeResult _parseResult(
    Map<String, dynamic> map, {
    required int elapsedMs,
  }) => SourceRuntimeResult(
    success: map['success'] == true,
    stdout: (map['stdout'] ?? '').toString(),
    stderr: (map['stderr'] ?? '').toString(),
    elapsedMs: (map['elapsedMs'] as num?)?.toInt() ?? elapsedMs,
    exitCode: (map['exitCode'] as num?)?.toInt() ?? -1,
    isStub: map['isStub'] == true,
    message: (map['message'] ?? '').toString(),
  );

  StubSourceRuntimeAdapter _fallbackStub() => const StubSourceRuntimeAdapter(
    reason:
        'Android MethodChannel handlers are not wired yet. '
        'Implement sourceRuntimeProbe/sourceRuntimeExecute in MainActivity.',
  );
}
