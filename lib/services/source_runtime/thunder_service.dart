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
    required this.message,
    required this.error,
  });

  final bool success;
  final String playUrl;
  final String protocol;
  final String infoHash;
  final String message;
  final String error;

  static ThunderPlayUrlResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ThunderPlayUrlResult(
        success: false,
        playUrl: '',
        protocol: '',
        infoHash: '',
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return ThunderPlayUrlResult(
      success: map['success'] == true,
      playUrl: (map['playUrl'] ?? '').toString(),
      protocol: (map['protocol'] ?? '').toString(),
      infoHash: (map['infoHash'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      error: (map['error'] ?? '').toString(),
    );
  }
}

class ThunderStatusResult {
  const ThunderStatusResult({
    required this.success,
    required this.message,
    required this.error,
  });

  final bool success;
  final String message;
  final String error;

  static ThunderStatusResult fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const ThunderStatusResult(
        success: false,
        message: 'Empty platform response.',
        error: 'empty_response',
      );
    }
    return ThunderStatusResult(
      success: map['success'] == true,
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
      return ThunderPlayUrlResult(
        success: parsed.success,
        playUrl: parsed.normalizedUrl,
        protocol: parsed.protocol,
        infoHash: parsed.infoHash,
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
        message: 'thunderGetPlayUrl platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderPlayUrlResult(
        success: false,
        playUrl: '',
        protocol: '',
        infoHash: '',
        message: 'thunderGetPlayUrl not implemented',
        error: error.toString(),
      );
    }
  }

  Future<ThunderStatusResult> stopTask(String taskId) async {
    if (!Platform.isAndroid) {
      return const ThunderStatusResult(
        success: true,
        message: 'Thunder fallback mode has no active task process.',
        error: '',
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
        message: 'thunderStopTask platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderStatusResult(
        success: false,
        message: 'thunderStopTask not implemented',
        error: error.toString(),
      );
    }
  }

  Future<ThunderStatusResult> release() async {
    if (!Platform.isAndroid) {
      return const ThunderStatusResult(
        success: true,
        message: 'Thunder fallback mode released.',
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
        message: 'thunderRelease platform error',
        error: error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ThunderStatusResult(
        success: false,
        message: 'thunderRelease not implemented',
        error: error.toString(),
      );
    }
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

    if (input.toLowerCase().startsWith('thunder://')) {
      final encoded = input.substring(input.indexOf('://') + 3);
      if (encoded.isEmpty) return null;
      try {
        final decoded = utf8.decode(base64.decode(encoded)).trim();
        final unwrapped = decoded
            .replaceFirst(RegExp(r'^AA', caseSensitive: false), '')
            .replaceFirst(RegExp(r'ZZ$', caseSensitive: false), '')
            .trim();
        final nested =
            _parseThunderLikeUrl(unwrapped) ??
            _ParsedThunderUrl(
              protocol: 'thunder',
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
      } catch (_) {
        return null;
      }
    }

    final lower = input.toLowerCase();
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
