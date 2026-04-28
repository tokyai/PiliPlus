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

class JarLifecycleActionResult {
  const JarLifecycleActionResult({
    required this.success,
    required this.message,
    required this.error,
  });

  final bool success;
  final String message;
  final String error;

  static JarLifecycleActionResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarLifecycleActionResult(
        success: false,
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return JarLifecycleActionResult(
      success: map['success'] == true,
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class JarSpiderCrashStateResult {
  const JarSpiderCrashStateResult({
    required this.success,
    required this.crashed,
    required this.message,
    required this.error,
  });

  final bool success;
  final bool crashed;
  final String message;
  final String error;

  static JarSpiderCrashStateResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarSpiderCrashStateResult(
        success: false,
        crashed: false,
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return JarSpiderCrashStateResult(
      success: map['success'] == true,
      crashed: map['crashed'] == true,
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class JarSpiderCrashCountResult {
  const JarSpiderCrashCountResult({
    required this.success,
    required this.count,
    required this.message,
    required this.error,
  });

  final bool success;
  final int count;
  final String message;
  final String error;

  static JarSpiderCrashCountResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarSpiderCrashCountResult(
        success: false,
        count: 0,
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    final count = map['count'];
    return JarSpiderCrashCountResult(
      success: map['success'] == true,
      count: switch (count) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class JarDataResult {
  const JarDataResult({
    required this.success,
    required this.data,
    required this.message,
    required this.error,
  });

  final bool success;
  final String data;
  final String message;
  final String error;

  static JarDataResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarDataResult(
        success: false,
        data: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return JarDataResult(
      success: map['success'] == true,
      data: (map['data'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class JarRuntimeRecentItem {
  const JarRuntimeRecentItem({
    required this.jarPath,
    required this.key,
  });

  final String jarPath;
  final String key;

  static JarRuntimeRecentItem fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarRuntimeRecentItem(jarPath: '', key: '');
    }
    return JarRuntimeRecentItem(
      jarPath: (map['jarPath'] ?? '').toString(),
      key: (map['key'] ?? '').toString(),
    );
  }
}

class JarRuntimeStateResult {
  const JarRuntimeStateResult({
    required this.success,
    required this.loadedCount,
    required this.crashedCount,
    required this.contextCount,
    required this.recentCount,
    required this.loadedIds,
    required this.crashedIds,
    required this.contextIds,
    required this.recentItems,
    required this.message,
    required this.error,
  });

  final bool success;
  final int loadedCount;
  final int crashedCount;
  final int contextCount;
  final int recentCount;
  final List<String> loadedIds;
  final List<String> crashedIds;
  final List<String> contextIds;
  final List<JarRuntimeRecentItem> recentItems;
  final String message;
  final String error;

  static JarRuntimeStateResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const JarRuntimeStateResult(
        success: false,
        loadedCount: 0,
        crashedCount: 0,
        contextCount: 0,
        recentCount: 0,
        loadedIds: <String>[],
        crashedIds: <String>[],
        contextIds: <String>[],
        recentItems: <JarRuntimeRecentItem>[],
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    int parseIntValue(Object? value) => switch (value) {
      int item => item,
      num item => item.toInt(),
      String item => int.tryParse(item) ?? 0,
      _ => 0,
    };

    List<String> parseStringList(Object? value) {
      final list = value is List ? value : const <dynamic>[];
      return list.map((item) => item.toString()).toList();
    }

    List<JarRuntimeRecentItem> parseRecentItems(Object? value) {
      final list = value is List ? value : const <dynamic>[];
      return list.map((item) {
        if (item is Map<Object?, Object?>) {
          return JarRuntimeRecentItem.fromMap(item);
        }
        if (item is Map) {
          return JarRuntimeRecentItem.fromMap(
            item.map(MapEntry.new),
          );
        }
        return const JarRuntimeRecentItem(jarPath: '', key: '');
      }).toList();
    }

    return JarRuntimeStateResult(
      success: map['success'] == true,
      loadedCount: parseIntValue(map['loadedCount']),
      crashedCount: parseIntValue(map['crashedCount']),
      contextCount: parseIntValue(map['contextCount']),
      recentCount: parseIntValue(map['recentCount']),
      loadedIds: parseStringList(map['loadedIds']),
      crashedIds: parseStringList(map['crashedIds']),
      contextIds: parseStringList(map['contextIds']),
      recentItems: parseRecentItems(map['recentItems']),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
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
    String mainClass = '',
    String methodName = '',
    List<String> args = const <String>[],
    bool staticOnly = false,
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
          'options': <String, dynamic>{
            'mainClass': mainClass.trim(),
            'staticOnly': staticOnly,
          },
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

  Future<JarLifecycleActionResult> destroySpider({
    required String key,
    required String jarPath,
  }) async {
    if (!Platform.isAndroid) {
      return const JarLifecycleActionResult(
        success: false,
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'destroySpider',
        <String, dynamic>{
          'key': key.trim(),
          'jar': jarPath.trim(),
          'jarPath': jarPath.trim(),
        },
      );
      return JarLifecycleActionResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'destroySpider platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'destroySpider not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarLifecycleActionResult> markSpiderCrashed({
    required String key,
    required String jarPath,
  }) async {
    if (!Platform.isAndroid) {
      return const JarLifecycleActionResult(
        success: false,
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'markSpiderCrashed',
        <String, dynamic>{
          'key': key.trim(),
          'jar': jarPath.trim(),
          'jarPath': jarPath.trim(),
        },
      );
      return JarLifecycleActionResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'markSpiderCrashed platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'markSpiderCrashed not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarSpiderCrashStateResult> isSpiderCrashed({
    required String key,
    required String jarPath,
  }) async {
    if (!Platform.isAndroid) {
      return const JarSpiderCrashStateResult(
        success: false,
        crashed: false,
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'isSpiderCrashed',
        <String, dynamic>{
          'key': key.trim(),
          'jar': jarPath.trim(),
          'jarPath': jarPath.trim(),
        },
      );
      return JarSpiderCrashStateResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarSpiderCrashStateResult(
        success: false,
        crashed: false,
        message: 'isSpiderCrashed platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarSpiderCrashStateResult(
        success: false,
        crashed: false,
        message: 'isSpiderCrashed not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarSpiderCrashCountResult> getCrashedSpiderCount() async {
    if (!Platform.isAndroid) {
      return const JarSpiderCrashCountResult(
        success: false,
        count: 0,
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'getCrashedSpiderCount',
      );
      return JarSpiderCrashCountResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarSpiderCrashCountResult(
        success: false,
        count: 0,
        message: 'getCrashedSpiderCount platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarSpiderCrashCountResult(
        success: false,
        count: 0,
        message: 'getCrashedSpiderCount not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarLifecycleActionResult> clearCrashedSpiders() async {
    if (!Platform.isAndroid) {
      return const JarLifecycleActionResult(
        success: false,
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'clearCrashedSpiders',
      );
      return JarLifecycleActionResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'clearCrashedSpiders platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'clearCrashedSpiders not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarLifecycleActionResult> clearAll() async {
    if (!Platform.isAndroid) {
      return const JarLifecycleActionResult(
        success: false,
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'clearAll',
      );
      return JarLifecycleActionResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'clearAll platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'clearAll not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarRuntimeStateResult> getRuntimeState() async {
    if (!Platform.isAndroid) {
      return const JarRuntimeStateResult(
        success: false,
        loadedCount: 0,
        crashedCount: 0,
        contextCount: 0,
        recentCount: 0,
        loadedIds: <String>[],
        crashedIds: <String>[],
        contextIds: <String>[],
        recentItems: <JarRuntimeRecentItem>[],
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'getJarRuntimeState',
      );
      return JarRuntimeStateResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarRuntimeStateResult(
        success: false,
        loadedCount: 0,
        crashedCount: 0,
        contextCount: 0,
        recentCount: 0,
        loadedIds: const <String>[],
        crashedIds: const <String>[],
        contextIds: const <String>[],
        recentItems: const <JarRuntimeRecentItem>[],
        message: 'getJarRuntimeState platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarRuntimeStateResult(
        success: false,
        loadedCount: 0,
        crashedCount: 0,
        contextCount: 0,
        recentCount: 0,
        loadedIds: const <String>[],
        crashedIds: const <String>[],
        contextIds: const <String>[],
        recentItems: const <JarRuntimeRecentItem>[],
        message: 'getJarRuntimeState not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarDataResult> homeContent({
    required String key,
    required String jarPath,
    bool filter = true,
  }) {
    return _invokeJarDataMethod(
      method: 'homeContent',
      args: <String, dynamic>{
        'key': key.trim(),
        'jar': jarPath.trim(),
        'jarPath': jarPath.trim(),
        'filter': filter,
      },
    );
  }

  Future<JarDataResult> homeVideoContent({
    required String key,
    required String jarPath,
  }) {
    return _invokeJarDataMethod(
      method: 'homeVideoContent',
      args: <String, dynamic>{
        'key': key.trim(),
        'jar': jarPath.trim(),
        'jarPath': jarPath.trim(),
      },
    );
  }

  Future<JarDataResult> categoryContent({
    required String key,
    required String jarPath,
    String tid = '',
    String pg = '1',
    bool filter = true,
    Map<String, String> extend = const <String, String>{},
  }) {
    return _invokeJarDataMethod(
      method: 'categoryContent',
      args: <String, dynamic>{
        'key': key.trim(),
        'jar': jarPath.trim(),
        'jarPath': jarPath.trim(),
        'tid': tid,
        'pg': pg,
        'filter': filter,
        'extend': extend,
      },
    );
  }

  Future<JarDataResult> searchContent({
    required String key,
    required String jarPath,
    required String keyword,
    bool quick = false,
    String pg = '1',
  }) {
    return _invokeJarDataMethod(
      method: 'searchContent',
      args: <String, dynamic>{
        'key': key.trim(),
        'jar': jarPath.trim(),
        'jarPath': jarPath.trim(),
        'keyword': keyword,
        'quick': quick,
        'pg': pg,
      },
    );
  }

  Future<JarDataResult> detailContent({
    required String key,
    required String jarPath,
    List<String> ids = const <String>[],
  }) {
    return _invokeJarDataMethod(
      method: 'detailContent',
      args: <String, dynamic>{
        'key': key.trim(),
        'jar': jarPath.trim(),
        'jarPath': jarPath.trim(),
        'ids': ids,
      },
    );
  }

  Future<JarDataResult> playerContent({
    required String key,
    required String jarPath,
    String flag = '',
    String id = '',
    List<String> vipFlags = const <String>[],
  }) {
    return _invokeJarDataMethod(
      method: 'playerContent',
      args: <String, dynamic>{
        'key': key.trim(),
        'jar': jarPath.trim(),
        'jarPath': jarPath.trim(),
        'flag': flag,
        'id': id,
        'vipFlags': vipFlags,
      },
    );
  }

  Future<JarDataResult> actionContent({
    required String key,
    required String jarPath,
    required String action,
  }) {
    return _invokeJarDataMethod(
      method: 'action',
      args: <String, dynamic>{
        'key': key.trim(),
        'jar': jarPath.trim(),
        'jarPath': jarPath.trim(),
        'action': action,
      },
    );
  }

  Future<JarLifecycleActionResult> setRecent({
    required String jarPath,
    String key = '',
  }) async {
    if (!Platform.isAndroid) {
      return const JarLifecycleActionResult(
        success: false,
        message:
            'Jar native lifecycle bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'setRecent',
        <String, dynamic>{
          'key': key.trim(),
          'jar': jarPath.trim(),
          'jarPath': jarPath.trim(),
        },
      );
      return JarLifecycleActionResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'setRecent platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarLifecycleActionResult(
        success: false,
        message: 'setRecent not implemented',
        error: error.toString(),
      );
    }
  }

  Future<JarDataResult> _invokeJarDataMethod({
    required String method,
    required Map<String, dynamic> args,
  }) async {
    if (!Platform.isAndroid) {
      return const JarDataResult(
        success: false,
        data: '',
        message: 'Jar native data bridge is only implemented on Android now.',
        error: 'unsupported_platform',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        method,
        args,
      );
      return JarDataResult.fromMap(map);
    } on PlatformException catch (error) {
      return JarDataResult(
        success: false,
        data: '',
        message: '$method platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return JarDataResult(
        success: false,
        data: '',
        message: '$method not implemented',
        error: error.toString(),
      );
    }
  }
}
