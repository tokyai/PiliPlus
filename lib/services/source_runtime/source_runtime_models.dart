import 'package:PiliPlus/services/source_runtime/source_engine.dart';

class SourceRuntimeRequest {
  const SourceRuntimeRequest({
    required this.engine,
    required this.payload,
    this.timeout = const Duration(seconds: 15),
    this.options = const <String, dynamic>{},
  });

  final SourceEngine engine;
  final String payload;
  final Duration timeout;
  final Map<String, dynamic> options;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'engine': engine.key,
    'payload': payload,
    'timeoutMs': timeout.inMilliseconds,
    'options': options,
  };
}

class SourceRuntimeResult {
  const SourceRuntimeResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.elapsedMs,
    required this.exitCode,
    required this.isStub,
    required this.message,
  });

  final bool success;
  final String stdout;
  final String stderr;
  final int elapsedMs;
  final int exitCode;
  final bool isStub;
  final String message;

  String get mergedOutput {
    final out = stdout.trim();
    final err = stderr.trim();
    if (out.isEmpty && err.isEmpty) return message;
    if (err.isEmpty) return out;
    if (out.isEmpty) return err;
    return '$out\n$err';
  }
}
