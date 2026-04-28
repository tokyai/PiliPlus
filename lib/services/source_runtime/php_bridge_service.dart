import 'dart:io';

import 'package:PiliPlus/common/constants.dart';
import 'package:flutter/services.dart';

class PhpServerStatus {
  const PhpServerStatus({
    required this.success,
    required this.running,
    required this.port,
    required this.ports,
    required this.documentRoot,
    required this.message,
    required this.error,
  });

  final bool success;
  final bool running;
  final int port;
  final List<int> ports;
  final String documentRoot;
  final String message;
  final String error;

  static PhpServerStatus fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const PhpServerStatus(
        success: false,
        running: false,
        port: 0,
        ports: <int>[],
        documentRoot: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    final rawPort = map['port'];
    final rawPorts = map['ports'];
    return PhpServerStatus(
      success: map['success'] == true,
      running: map['running'] == true,
      port: switch (rawPort) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      ports: rawPorts is List
          ? rawPorts
                .map(
                  (item) => switch (item) {
                    int value => value,
                    num value => value.toInt(),
                    String value => int.tryParse(value),
                    _ => null,
                  },
                )
                .whereType<int>()
                .toList()
          : const <int>[],
      documentRoot: (map['documentRoot'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class PhpCommandResult {
  const PhpCommandResult({
    required this.success,
    required this.command,
    required this.preparedFromAsset,
    required this.downloaded,
    required this.extracted,
    required this.archivePath,
    required this.message,
    required this.error,
  });

  final bool success;
  final String command;
  final bool preparedFromAsset;
  final bool downloaded;
  final bool extracted;
  final String archivePath;
  final String message;
  final String error;

  static PhpCommandResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const PhpCommandResult(
        success: false,
        command: '',
        preparedFromAsset: false,
        downloaded: false,
        extracted: false,
        archivePath: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return PhpCommandResult(
      success: map['success'] == true,
      command: (map['command'] ?? '').toString(),
      preparedFromAsset: map['preparedFromAsset'] == true,
      downloaded: map['downloaded'] == true,
      extracted: map['extracted'] == true,
      archivePath: (map['archivePath'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class PhpExecutionResult {
  const PhpExecutionResult({
    required this.success,
    required this.textOutputOrError,
    required this.message,
    required this.error,
  });

  final bool success;
  final String textOutputOrError;
  final String message;
  final String error;

  static PhpExecutionResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const PhpExecutionResult(
        success: false,
        textOutputOrError: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return PhpExecutionResult(
      success: map['success'] == true,
      textOutputOrError: (map['textOutputOrError'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class PhpBridgeService {
  PhpBridgeService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(Constants.appName);

  final MethodChannel _channel;

  Future<PhpServerStatus> startServer({
    int port = 9980,
    int instances = 4,
    String? documentRoot,
    String? command,
    List<String> commandCandidates = const <String>[],
    Map<String, String> environment = const <String, String>{},
  }) async {
    if (!Platform.isAndroid) {
      return const PhpServerStatus(
        success: false,
        running: false,
        port: 0,
        ports: <int>[],
        documentRoot: '',
        message: 'PHP bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'startServer',
        <String, dynamic>{
          'port': port,
          'instances': instances,
          'documentRoot': documentRoot?.trim(),
          'command': command?.trim(),
          'commandCandidates': commandCandidates,
          'environment': environment,
        },
      );
      return PhpServerStatus.fromMap(map);
    } on PlatformException catch (error) {
      return PhpServerStatus(
        success: false,
        running: false,
        port: 0,
        ports: const <int>[],
        documentRoot: '',
        message: 'startServer platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return PhpServerStatus(
        success: false,
        running: false,
        port: 0,
        ports: const <int>[],
        documentRoot: '',
        message: 'startServer not implemented',
        error: error.toString(),
      );
    }
  }

  Future<PhpServerStatus> stopServer() async {
    if (!Platform.isAndroid) {
      return const PhpServerStatus(
        success: false,
        running: false,
        port: 0,
        ports: <int>[],
        documentRoot: '',
        message: 'PHP bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'stopServer',
      );
      return PhpServerStatus.fromMap(map);
    } on PlatformException catch (error) {
      return PhpServerStatus(
        success: false,
        running: false,
        port: 0,
        ports: const <int>[],
        documentRoot: '',
        message: 'stopServer platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return PhpServerStatus(
        success: false,
        running: false,
        port: 0,
        ports: const <int>[],
        documentRoot: '',
        message: 'stopServer not implemented',
        error: error.toString(),
      );
    }
  }

  Future<PhpCommandResult> installPhp({
    String? downloadUrl,
    String targetRelativePath = 'php/php',
    List<String> assetCandidates = const <String>[
      'php/php',
      'assets/runtime/php',
      'assets/php/php',
      'php',
    ],
  }) async {
    if (!Platform.isAndroid) {
      return const PhpCommandResult(
        success: false,
        command: '',
        preparedFromAsset: false,
        downloaded: false,
        extracted: false,
        archivePath: '',
        message: 'PHP bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'installPhp',
        <String, dynamic>{
          'downloadUrl': downloadUrl,
          'targetRelativePath': targetRelativePath,
          'assetCandidates': assetCandidates,
        },
      );
      return PhpCommandResult.fromMap(map);
    } on PlatformException catch (error) {
      return PhpCommandResult(
        success: false,
        command: '',
        preparedFromAsset: false,
        downloaded: false,
        extracted: false,
        archivePath: '',
        message: 'installPhp platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return PhpCommandResult(
        success: false,
        command: '',
        preparedFromAsset: false,
        downloaded: false,
        extracted: false,
        archivePath: '',
        message: 'installPhp not implemented',
        error: error.toString(),
      );
    }
  }

  Future<PhpExecutionResult> executeCode(
    String code, {
    int timeoutMs = 15000,
    String? command,
    List<String> commandCandidates = const <String>[],
    Map<String, String> environment = const <String, String>{},
  }) async {
    if (!Platform.isAndroid) {
      return const PhpExecutionResult(
        success: false,
        textOutputOrError: '',
        message: 'PHP bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'executeCode',
        <String, dynamic>{
          'code': code,
          'timeoutMs': timeoutMs,
          'command': command?.trim(),
          'commandCandidates': commandCandidates,
          'environment': environment,
        },
      );
      return PhpExecutionResult.fromMap(map);
    } on PlatformException catch (error) {
      return PhpExecutionResult(
        success: false,
        textOutputOrError: '',
        message: 'executeCode platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return PhpExecutionResult(
        success: false,
        textOutputOrError: '',
        message: 'executeCode not implemented',
        error: error.toString(),
      );
    }
  }

  Future<bool> isInstalled() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isInstalled') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> getVersion() async {
    if (!Platform.isAndroid) return '';
    try {
      return await _channel.invokeMethod<String>('getVersion') ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  Future<List<String>> getExtensions() async {
    if (!Platform.isAndroid) return const <String>[];
    try {
      final value = await _channel.invokeMethod<dynamic>('getExtensions');
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const <String>[];
    } on PlatformException {
      return const <String>[];
    } on MissingPluginException {
      return const <String>[];
    }
  }

  Future<String> getScriptsDir() async {
    if (!Platform.isAndroid) return '';
    try {
      return await _channel.invokeMethod<String>('getScriptsDir') ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  Future<String> getPhpDir() async {
    if (!Platform.isAndroid) return '';
    try {
      return await _channel.invokeMethod<String>('getPhpDir') ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  Future<int> getServerPort() async {
    if (!Platform.isAndroid) return 0;
    try {
      final value = await _channel.invokeMethod<dynamic>('getServerPort');
      return switch (value) {
        int item => item,
        num item => item.toInt(),
        String item => int.tryParse(item) ?? 0,
        _ => 0,
      };
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  Future<bool> isServerRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isServerRunning') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> getDefaultDownloadUrl() async {
    if (!Platform.isAndroid) return '';
    try {
      return await _channel.invokeMethod<String>('getDefaultDownloadUrl') ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }
}
