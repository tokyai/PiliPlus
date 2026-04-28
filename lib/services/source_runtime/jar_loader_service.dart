import 'dart:io';

import 'package:PiliPlus/common/constants.dart';
import 'package:flutter/services.dart';

class JarProbeResult {
  const JarProbeResult({
    required this.success,
    required this.exists,
    required this.readable,
    required this.size,
    required this.path,
    required this.message,
    required this.error,
  });

  final bool success;
  final bool exists;
  final bool readable;
  final int size;
  final String path;
  final String message;
  final String error;

  static JarProbeResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarProbeResult(
        success: false,
        exists: false,
        readable: false,
        size: 0,
        path: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    final size = map['size'];
    return JarProbeResult(
      success: map['success'] == true,
      exists: map['exists'] == true,
      readable: map['readable'] == true,
      size: switch (size) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      path: (map['path'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class JarInvokeResult {
  const JarInvokeResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.message,
    required this.error,
    required this.isStub,
  });

  final bool success;
  final String stdout;
  final String stderr;
  final int exitCode;
  final String message;
  final String error;
  final bool isStub;

  String get mergedOutput {
    final out = stdout.trim();
    final err = stderr.trim();
    if (out.isEmpty && err.isEmpty) return message;
    if (err.isEmpty) return out;
    if (out.isEmpty) return err;
    return '$out\n$err';
  }

  static JarInvokeResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarInvokeResult(
        success: false,
        stdout: '',
        stderr: '',
        exitCode: -1,
        message: 'Empty platform response.',
        error: 'empty_response',
        isStub: true,
      );
    }
    final exitCode = map['exitCode'];
    return JarInvokeResult(
      success: map['success'] == true,
      stdout: (map['stdout'] ?? '').toString(),
      stderr: (map['stderr'] ?? '').toString(),
      exitCode: switch (exitCode) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value) ?? -1,
        _ => -1,
      },
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
      isStub: map['isStub'] == true,
    );
  }
}

class JarLoaderService {
  JarLoaderService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(Constants.appName);

  final MethodChannel _channel;

  Future<JarProbeResult> probeJarFile(String jarPath) async {
    if (!Platform.isAndroid) {
      return const JarProbeResult(
        success: false,
        exists: false,
        readable: false,
        size: 0,
        path: '',
        message: 'Jar native bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'probeJarFile',
        <String, dynamic>{'jarPath': jarPath.trim()},
      );
      return JarProbeResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarProbeResult(
        success: false,
        exists: false,
        readable: false,
        size: 0,
        path: jarPath,
        message: 'probeJarFile platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarProbeResult(
        success: false,
        exists: false,
        readable: false,
        size: 0,
        path: jarPath,
        message: 'probeJarFile not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarInvokeResult> loadJar({
    required String jarPath,
    String entryClass = '',
    String methodName = '',
    List<String> args = const <String>[],
  }) async {
    if (!Platform.isAndroid) {
      return const JarInvokeResult(
        success: false,
        stdout: '',
        stderr: '',
        exitCode: -1,
        message: 'Jar native bridge is only implemented on Android now.',
        error: 'unsupported_platform',
        isStub: true,
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'loadJar',
        <String, dynamic>{
          'jarPath': jarPath.trim(),
          'entryClass': entryClass.trim(),
          'methodName': methodName.trim(),
          'args': args,
        },
      );
      return JarInvokeResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarInvokeResult(
        success: false,
        stdout: '',
        stderr: '',
        exitCode: -1,
        message: 'loadJar platform error',
        error: error.message ?? error.code,
        isStub: true,
      );
    } on MissingPluginException catch (error) {
      return JarInvokeResult(
        success: false,
        stdout: '',
        stderr: '',
        exitCode: -1,
        message: 'loadJar not implemented',
        error: error.toString(),
        isStub: true,
      );
    }
  }
}
