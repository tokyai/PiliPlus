import 'dart:io';

import 'package:PiliPlus/common/constants.dart';
import 'package:flutter/services.dart';

class GoProxyStatus {
  const GoProxyStatus({
    required this.success,
    required this.running,
    required this.proxyUrl,
    required this.message,
    required this.error,
    this.pid,
  });

  final bool success;
  final bool running;
  final String proxyUrl;
  final String message;
  final String error;
  final int? pid;

  static GoProxyStatus fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const GoProxyStatus(
        success: false,
        running: false,
        proxyUrl: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }

    final pid = map['pid'];
    return GoProxyStatus(
      success: map['success'] == true,
      running: map['running'] == true,
      proxyUrl: (map['proxyUrl'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
      pid: switch (pid) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      },
    );
  }
}

class GoProxyCommandResult {
  const GoProxyCommandResult({
    required this.success,
    required this.command,
    required this.message,
    required this.error,
    this.preparedFromAsset = false,
  });

  final bool success;
  final String command;
  final String message;
  final String error;
  final bool preparedFromAsset;

  static GoProxyCommandResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const GoProxyCommandResult(
        success: false,
        command: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return GoProxyCommandResult(
      success: map['success'] == true,
      command: (map['command'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
      preparedFromAsset: map['preparedFromAsset'] == true,
    );
  }
}

class GoProxyRuntimeStateResult {
  const GoProxyRuntimeStateResult({
    required this.success,
    required this.running,
    required this.proxyUrl,
    required this.lastError,
    required this.lastCommand,
    required this.lastArgs,
    required this.lastWorkingDirectory,
    required this.port,
    required this.danmuDir,
    required this.startedAtMs,
    required this.uptimeMs,
    required this.pid,
    required this.message,
    required this.error,
  });

  final bool success;
  final bool running;
  final String proxyUrl;
  final String lastError;
  final String lastCommand;
  final List<String> lastArgs;
  final String lastWorkingDirectory;
  final int port;
  final String danmuDir;
  final int startedAtMs;
  final int uptimeMs;
  final int? pid;
  final String message;
  final String error;

  static GoProxyRuntimeStateResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const GoProxyRuntimeStateResult(
        success: false,
        running: false,
        proxyUrl: '',
        lastError: '',
        lastCommand: '',
        lastArgs: <String>[],
        lastWorkingDirectory: '',
        port: 0,
        danmuDir: '',
        startedAtMs: 0,
        uptimeMs: 0,
        pid: null,
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    int parseInt(Object? value) => switch (value) {
      int item => item,
      num item => item.toInt(),
      String item => int.tryParse(item) ?? 0,
      _ => 0,
    };
    final rawPid = map['pid'];
    final rawArgs = map['lastArgs'];
    return GoProxyRuntimeStateResult(
      success: map['success'] == true,
      running: map['running'] == true,
      proxyUrl: (map['proxyUrl'] ?? '').toString(),
      lastError: (map['lastError'] ?? '').toString(),
      lastCommand: (map['lastCommand'] ?? '').toString(),
      lastArgs: rawArgs is List
          ? rawArgs.map((item) => item.toString()).toList()
          : const <String>[],
      lastWorkingDirectory: (map['lastWorkingDirectory'] ?? '').toString(),
      port: parseInt(map['port']),
      danmuDir: (map['danmuDir'] ?? '').toString(),
      startedAtMs: parseInt(map['startedAtMs']),
      uptimeMs: parseInt(map['uptimeMs']),
      pid: switch (rawPid) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      },
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class GoProxyService {
  GoProxyService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(Constants.appName);

  final MethodChannel _channel;

  Future<GoProxyStatus> start({
    required String command,
    List<String> args = const <String>[],
    int port = 9978,
    String? danmuDir,
    String? workingDirectory,
    String? proxyUrl,
    Map<String, String> environment = const <String, String>{},
  }) async {
    if (!Platform.isAndroid) {
      return const GoProxyStatus(
        success: false,
        running: false,
        proxyUrl: '',
        message: 'GoProxy native bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'startGoProxy',
        <String, dynamic>{
          'command': command.trim(),
          'args': args,
          'port': port,
          'danmuDir': danmuDir,
          'workingDirectory': workingDirectory,
          'proxyUrl': proxyUrl,
          'environment': environment,
        },
      );
      return GoProxyStatus.fromMap(map);
    } on PlatformException catch (error) {
      return GoProxyStatus(
        success: false,
        running: false,
        proxyUrl: '',
        message: 'startGoProxy platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return GoProxyStatus(
        success: false,
        running: false,
        proxyUrl: '',
        message: 'startGoProxy not implemented',
        error: error.toString(),
      );
    }
  }

  Future<GoProxyStatus> stop() async {
    if (!Platform.isAndroid) {
      return const GoProxyStatus(
        success: false,
        running: false,
        proxyUrl: '',
        message: 'GoProxy native bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'stopGoProxy',
      );
      return GoProxyStatus.fromMap(map);
    } on PlatformException catch (error) {
      return GoProxyStatus(
        success: false,
        running: false,
        proxyUrl: '',
        message: 'stopGoProxy platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return GoProxyStatus(
        success: false,
        running: false,
        proxyUrl: '',
        message: 'stopGoProxy not implemented',
        error: error.toString(),
      );
    }
  }

  Future<GoProxyCommandResult> detectCommand({
    List<String> candidates = const <String>[],
  }) async {
    if (!Platform.isAndroid) {
      return const GoProxyCommandResult(
        success: false,
        command: '',
        message: 'GoProxy native bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'detectGoProxyCommand',
        <String, dynamic>{'candidates': candidates},
      );
      return GoProxyCommandResult.fromMap(map);
    } on PlatformException catch (error) {
      return GoProxyCommandResult(
        success: false,
        command: '',
        message: 'detectGoProxyCommand platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return GoProxyCommandResult(
        success: false,
        command: '',
        message: 'detectGoProxyCommand not implemented',
        error: error.toString(),
      );
    }
  }

  Future<GoProxyCommandResult> prepareBinary({
    List<String> assetCandidates = const <String>[
      'assets/runtime/goproxy',
      'assets/goproxy',
      'goproxy',
    ],
    String targetRelativePath = 'tools/goproxy',
  }) async {
    if (!Platform.isAndroid) {
      return const GoProxyCommandResult(
        success: false,
        command: '',
        message: 'GoProxy native bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'prepareGoProxyBinary',
        <String, dynamic>{
          'assetCandidates': assetCandidates,
          'targetRelativePath': targetRelativePath,
        },
      );
      return GoProxyCommandResult.fromMap(map);
    } on PlatformException catch (error) {
      return GoProxyCommandResult(
        success: false,
        command: '',
        message: 'prepareGoProxyBinary platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return GoProxyCommandResult(
        success: false,
        command: '',
        message: 'prepareGoProxyBinary not implemented',
        error: error.toString(),
      );
    }
  }

  Future<bool> isRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isGoProxyRunning') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> getProxyUrl() async {
    if (!Platform.isAndroid) return '';
    try {
      return await _channel.invokeMethod<String>('getProxyUrl') ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  Future<GoProxyRuntimeStateResult> getRuntimeState() async {
    if (!Platform.isAndroid) {
      return const GoProxyRuntimeStateResult(
        success: false,
        running: false,
        proxyUrl: '',
        lastError: '',
        lastCommand: '',
        lastArgs: <String>[],
        lastWorkingDirectory: '',
        port: 0,
        danmuDir: '',
        startedAtMs: 0,
        uptimeMs: 0,
        pid: null,
        message: 'GoProxy native bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'getGoProxyRuntimeState',
      );
      return GoProxyRuntimeStateResult.fromMap(map);
    } on PlatformException catch (error) {
      return GoProxyRuntimeStateResult(
        success: false,
        running: false,
        proxyUrl: '',
        lastError: '',
        lastCommand: '',
        lastArgs: const <String>[],
        lastWorkingDirectory: '',
        port: 0,
        danmuDir: '',
        startedAtMs: 0,
        uptimeMs: 0,
        pid: null,
        message: 'getGoProxyRuntimeState platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return GoProxyRuntimeStateResult(
        success: false,
        running: false,
        proxyUrl: '',
        lastError: '',
        lastCommand: '',
        lastArgs: const <String>[],
        lastWorkingDirectory: '',
        port: 0,
        danmuDir: '',
        startedAtMs: 0,
        uptimeMs: 0,
        pid: null,
        message: 'getGoProxyRuntimeState not implemented',
        error: error.toString(),
      );
    }
  }
}
