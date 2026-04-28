import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/common/constants.dart';
import 'package:flutter/services.dart';

class ThunderParseResult {
  const ThunderParseResult({
    required this.success,
    required this.protocol,
    required this.originalUrl,
    required this.normalizedUrl,
    required this.infoHash,
    required this.message,
    required this.error,
  });

  final bool success;
  final String protocol;
  final String originalUrl;
  final String normalizedUrl;
  final String infoHash;
  final String message;
  final String error;

  static ThunderParseResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ThunderParseResult(
        success: false,
        protocol: '',
        originalUrl: '',
        normalizedUrl: '',
        infoHash: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return ThunderParseResult(
      success: map['success'] == true,
      protocol: (map['protocol'] ?? '').toString(),
      originalUrl: (map['originalUrl'] ?? '').toString(),
      normalizedUrl: (map['normalizedUrl'] ?? '').toString(),
      infoHash: (map['infoHash'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class ThunderPlayUrlResult {
  const ThunderPlayUrlResult({
    required this.success,
    required this.playUrl,
    required this.protocol,
    required this.infoHash,
    required this.taskId,
    required this.activeTaskCount,
    required this.message,
    required this.error,
  });

  final bool success;
  final String playUrl;
  final String protocol;
  final String infoHash;
  final String taskId;
  final int activeTaskCount;
  final String message;
  final String error;

  static ThunderPlayUrlResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ThunderPlayUrlResult(
        success: false,
        playUrl: '',
        protocol: '',
        infoHash: '',
        taskId: '',
        activeTaskCount: 0,
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    final activeTaskCount = map['activeTaskCount'];
    return ThunderPlayUrlResult(
      success: map['success'] == true,
      playUrl: (map['playUrl'] ?? '').toString(),
      protocol: (map['protocol'] ?? '').toString(),
      infoHash: (map['infoHash'] ?? '').toString(),
      taskId: (map['taskId'] ?? '').toString(),
      activeTaskCount: switch (activeTaskCount) {
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

class ThunderStatusResult {
  const ThunderStatusResult({
    required this.success,
    required this.taskId,
    required this.activeTaskCount,
    required this.message,
    required this.error,
  });

  final bool success;
  final String taskId;
  final int activeTaskCount;
  final String message;
  final String error;

  static ThunderStatusResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ThunderStatusResult(
        success: false,
        taskId: '',
        activeTaskCount: 0,
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    final activeTaskCount = map['activeTaskCount'];
    return ThunderStatusResult(
      success: map['success'] == true,
      taskId: (map['taskId'] ?? '').toString(),
      activeTaskCount: switch (activeTaskCount) {
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

class ThunderTaskSnapshot {
  const ThunderTaskSnapshot({
    required this.taskId,
    required this.protocol,
    required this.originalUrl,
    required this.playUrl,
    required this.infoHash,
    required this.index,
    required this.createdAtMs,
    required this.ageMs,
  });

  final String taskId;
  final String protocol;
  final String originalUrl;
  final String playUrl;
  final String infoHash;
  final int index;
  final int createdAtMs;
  final int ageMs;

  static ThunderTaskSnapshot fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ThunderTaskSnapshot(
        taskId: '',
        protocol: '',
        originalUrl: '',
        playUrl: '',
        infoHash: '',
        index: 0,
        createdAtMs: 0,
        ageMs: 0,
      );
    }
    int parseInt(Object? value) => switch (value) {
      int item => item,
      num item => item.toInt(),
      String item => int.tryParse(item) ?? 0,
      _ => 0,
    };
    return ThunderTaskSnapshot(
      taskId: (map['taskId'] ?? '').toString(),
      protocol: (map['protocol'] ?? '').toString(),
      originalUrl: (map['originalUrl'] ?? '').toString(),
      playUrl: (map['playUrl'] ?? '').toString(),
      infoHash: (map['infoHash'] ?? '').toString(),
      index: parseInt(map['index']),
      createdAtMs: parseInt(map['createdAtMs']),
      ageMs: parseInt(map['ageMs']),
    );
  }
}

class ThunderRuntimeStateResult {
  const ThunderRuntimeStateResult({
    required this.success,
    required this.activeTaskCount,
    required this.taskSequence,
    required this.tasks,
    required this.message,
    required this.error,
  });

  final bool success;
  final int activeTaskCount;
  final int taskSequence;
  final List<ThunderTaskSnapshot> tasks;
  final String message;
  final String error;

  static ThunderRuntimeStateResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ThunderRuntimeStateResult(
        success: false,
        activeTaskCount: 0,
        taskSequence: 0,
        tasks: <ThunderTaskSnapshot>[],
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
    final rawTasks = map['tasks'];
    final tasks = rawTasks is List
        ? rawTasks.map((item) {
            if (item is Map<Object?, Object?>) {
              return ThunderTaskSnapshot.fromMap(item);
            }
            if (item is Map) {
              return ThunderTaskSnapshot.fromMap(
                item.map(MapEntry.new),
              );
            }
            return const ThunderTaskSnapshot(
              taskId: '',
              protocol: '',
              originalUrl: '',
              playUrl: '',
              infoHash: '',
              index: 0,
              createdAtMs: 0,
              ageMs: 0,
            );
          }).toList()
        : const <ThunderTaskSnapshot>[];
    return ThunderRuntimeStateResult(
      success: map['success'] == true,
      activeTaskCount: parseInt(map['activeTaskCount']),
      taskSequence: parseInt(map['taskSequence']),
      tasks: tasks,
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class ThunderService {
  ThunderService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(Constants.appName);

  final MethodChannel _channel;
  final Map<String, String> _fallbackTasks = <String, String>{};
  final Map<String, int> _fallbackTaskCreatedAt = <String, int>{};
  int _fallbackTaskCounter = 0;

  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return true;
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'thunderIsSupported',
      );
      return map?['supported'] == true || map?['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<ThunderParseResult> parseMagnet(String url) async {
    if (!Platform.isAndroid) {
      return _parseFallback(url);
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'thunderParseMagnet',
        <String, dynamic>{
          'url': url.trim(),
        },
      );
      return ThunderParseResult.fromMap(map);
    } on PlatformException catch (error) {
      return ThunderParseResult(
        success: false,
        protocol: '',
        originalUrl: url,
        normalizedUrl: '',
        infoHash: '',
        message: 'thunderParseMagnet platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderParseResult(
        success: false,
        protocol: '',
        originalUrl: url,
        normalizedUrl: '',
        infoHash: '',
        message: 'thunderParseMagnet not implemented',
        error: error.toString(),
      );
    }
  }

  Future<ThunderPlayUrlResult> getPlayUrl({
    required String url,
    int index = 0,
  }) async {
    if (!Platform.isAndroid) {
      final parsed = _parseFallback(url);
      final taskId = parsed.success
          ? _createFallbackTask(parsed.normalizedUrl)
          : '';
      return ThunderPlayUrlResult(
        success: parsed.success,
        playUrl: parsed.normalizedUrl,
        protocol: parsed.protocol,
        infoHash: parsed.infoHash,
        taskId: taskId,
        activeTaskCount: _fallbackTasks.length,
        message: parsed.message,
        error: parsed.error,
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'thunderGetPlayUrl',
        <String, dynamic>{
          'url': url.trim(),
          'index': index,
        },
      );
      return ThunderPlayUrlResult.fromMap(map);
    } on PlatformException catch (error) {
      return ThunderPlayUrlResult(
        success: false,
        playUrl: '',
        protocol: '',
        infoHash: '',
        taskId: '',
        activeTaskCount: 0,
        message: 'thunderGetPlayUrl platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderPlayUrlResult(
        success: false,
        playUrl: '',
        protocol: '',
        infoHash: '',
        taskId: '',
        activeTaskCount: 0,
        message: 'thunderGetPlayUrl not implemented',
        error: error.toString(),
      );
    }
  }

  Future<ThunderStatusResult> stopTask(String taskId) async {
    if (!Platform.isAndroid) {
      final normalized = taskId.trim();
      if (normalized.isEmpty) {
        return ThunderStatusResult(
          success: false,
          taskId: '',
          activeTaskCount: _fallbackTasks.length,
          message: 'taskId is required.',
          error: 'missing_task_id',
        );
      }
      final removed = _fallbackTasks.remove(normalized);
      _fallbackTaskCreatedAt.remove(normalized);
      return ThunderStatusResult(
        success: removed != null,
        taskId: normalized,
        activeTaskCount: _fallbackTasks.length,
        message: removed != null
            ? 'Thunder fallback task stopped.'
            : 'Thunder fallback task not found.',
        error: removed != null ? '' : 'task_not_found',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'thunderStopTask',
        <String, dynamic>{'taskId': taskId},
      );
      return ThunderStatusResult.fromMap(map);
    } on PlatformException catch (error) {
      return ThunderStatusResult(
        success: false,
        taskId: '',
        activeTaskCount: 0,
        message: 'thunderStopTask platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderStatusResult(
        success: false,
        taskId: '',
        activeTaskCount: 0,
        message: 'thunderStopTask not implemented',
        error: error.toString(),
      );
    }
  }

  Future<ThunderStatusResult> release() async {
    if (!Platform.isAndroid) {
      final cleared = _fallbackTasks.length;
      _fallbackTasks.clear();
      _fallbackTaskCreatedAt.clear();
      return ThunderStatusResult(
        success: true,
        taskId: '',
        activeTaskCount: 0,
        message: 'Thunder fallback mode released. Cleared $cleared tasks.',
        error: '',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'thunderRelease',
      );
      return ThunderStatusResult.fromMap(map);
    } on PlatformException catch (error) {
      return ThunderStatusResult(
        success: false,
        taskId: '',
        activeTaskCount: 0,
        message: 'thunderRelease platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderStatusResult(
        success: false,
        taskId: '',
        activeTaskCount: 0,
        message: 'thunderRelease not implemented',
        error: error.toString(),
      );
    }
  }

  Future<ThunderRuntimeStateResult> getRuntimeState() async {
    if (!Platform.isAndroid) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final tasks = _fallbackTasks.entries.map((entry) {
        final parsed = _parseThunderLikeUrl(entry.value);
        final createdAtMs = _fallbackTaskCreatedAt[entry.key] ?? 0;
        return ThunderTaskSnapshot(
          taskId: entry.key,
          protocol: parsed?.protocol ?? '',
          originalUrl: parsed?.originalUrl ?? '',
          playUrl: entry.value,
          infoHash: parsed?.infoHash ?? '',
          index: 0,
          createdAtMs: createdAtMs,
          ageMs: createdAtMs > 0
              ? (now - createdAtMs).clamp(0, 1 << 31).toInt()
              : 0,
        );
      }).toList();
      return ThunderRuntimeStateResult(
        success: true,
        activeTaskCount: _fallbackTasks.length,
        taskSequence: _fallbackTaskCounter,
        tasks: tasks,
        message: 'Thunder fallback runtime state snapshot loaded.',
        error: '',
      );
    }
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'getThunderRuntimeState',
      );
      return ThunderRuntimeStateResult.fromMap(map);
    } on PlatformException catch (error) {
      return ThunderRuntimeStateResult(
        success: false,
        activeTaskCount: 0,
        taskSequence: 0,
        tasks: const <ThunderTaskSnapshot>[],
        message: 'getThunderRuntimeState platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderRuntimeStateResult(
        success: false,
        activeTaskCount: 0,
        taskSequence: 0,
        tasks: const <ThunderTaskSnapshot>[],
        message: 'getThunderRuntimeState not implemented',
        error: error.toString(),
      );
    }
  }

  String _createFallbackTask(String playUrl) {
    _fallbackTaskCounter += 1;
    final taskId = 'fallback_$_fallbackTaskCounter';
    _fallbackTasks[taskId] = playUrl;
    _fallbackTaskCreatedAt[taskId] = DateTime.now().millisecondsSinceEpoch;
    return taskId;
  }

  ThunderParseResult _parseFallback(String url) {
    final input = url.trim();
    if (input.isEmpty) {
      return const ThunderParseResult(
        success: false,
        protocol: '',
        originalUrl: '',
        normalizedUrl: '',
        infoHash: '',
        message: 'url is required.',
        error: 'empty_url',
      );
    }

    final parsed = _parseThunderLikeUrl(input);
    if (parsed == null) {
      return const ThunderParseResult(
        success: false,
        protocol: '',
        originalUrl: '',
        normalizedUrl: '',
        infoHash: '',
        message: 'Unsupported url protocol.',
        error: 'unsupported_protocol',
      );
    }
    return ThunderParseResult(
      success: true,
      protocol: parsed.protocol,
      originalUrl: parsed.originalUrl,
      normalizedUrl: parsed.normalizedUrl,
      infoHash: parsed.infoHash,
      message: 'Parsed successfully (fallback).',
      error: '',
    );
  }

  _ParsedThunderUrl? _parseThunderLikeUrl(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final lowerInput = input.toLowerCase();
    if (lowerInput.startsWith('thunder://') ||
        lowerInput.startsWith('qqdl://') ||
        lowerInput.startsWith('flashget://')) {
      final scheme = lowerInput.substring(0, lowerInput.indexOf('://'));
      final encoded = input.substring(input.indexOf('://') + 3);
      if (encoded.isEmpty) return null;
      final decoded = _decodeThunderFamilyPayload(encoded);
      if (decoded == null) return null;
      final unwrapped = _unwrapThunderFamilyPayload(decoded, scheme);
      final nested =
          _parseThunderLikeUrl(unwrapped) ??
          _ParsedThunderUrl(
            protocol: scheme,
            originalUrl: input,
            normalizedUrl: unwrapped,
            infoHash: '',
          );
      return _ParsedThunderUrl(
        protocol: nested.protocol,
        originalUrl: input,
        normalizedUrl: nested.normalizedUrl,
        infoHash: nested.infoHash,
      );
    }

    final lower = lowerInput;
    final supportedSchemes = <String>[
      'magnet:',
      'ed2k://',
      'ftp://',
      'http://',
      'https://',
    ];
    if (!supportedSchemes.any(lower.startsWith)) return null;

    final protocol = input.split(':').first.toLowerCase();
    var infoHash = '';
    if (protocol == 'magnet') {
      final uri = Uri.tryParse(input);
      final xt = uri?.queryParameters['xt'] ?? '';
      if (xt.toLowerCase().startsWith('urn:btih:')) {
        infoHash = xt.substring('urn:btih:'.length).trim();
      }
    }
    return _ParsedThunderUrl(
      protocol: protocol,
      originalUrl: input,
      normalizedUrl: input,
      infoHash: infoHash,
    );
  }

  String? _decodeThunderFamilyPayload(String encoded) {
    final normalized = encoded.trim().replaceAll(' ', '+');
    final padding = (4 - normalized.length % 4) % 4;
    final padded = '$normalized${'=' * padding}';
    final candidates = <String>[padded, normalized];
    for (final candidate in candidates) {
      try {
        return utf8.decode(base64.decode(candidate));
      } catch (_) {}
      try {
        return utf8.decode(base64Url.decode(candidate));
      } catch (_) {}
    }
    return null;
  }

  String _unwrapThunderFamilyPayload(String decoded, String scheme) {
    final text = decoded.trim();
    if (scheme == 'flashget') {
      return text
          .replaceFirst(RegExp(r'^\[FLASHGET\]', caseSensitive: false), '')
          .replaceFirst(RegExp(r'\[FLASHGET\]$', caseSensitive: false), '')
          .trim();
    }
    return text
        .replaceFirst(RegExp(r'^AA', caseSensitive: false), '')
        .replaceFirst(RegExp(r'ZZ$', caseSensitive: false), '')
        .trim();
  }
}

class _ParsedThunderUrl {
  const _ParsedThunderUrl({
    required this.protocol,
    required this.originalUrl,
    required this.normalizedUrl,
    required this.infoHash,
  });

  final String protocol;
  final String originalUrl;
  final String normalizedUrl;
  final String infoHash;
}
