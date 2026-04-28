import 'dart:convert';

import 'package:PiliPlus/models/peekpili/t4_api_config.dart';
import 'package:dio/dio.dart';

class SourceConfigFetchResult {
  const SourceConfigFetchResult({
    required this.success,
    required this.configs,
    required this.message,
    required this.error,
    required this.rawData,
  });

  final bool success;
  final List<T4ApiConfig> configs;
  final String message;
  final String error;
  final Object? rawData;

  String get prettyConfigsJson => const JsonEncoder.withIndent(
    '  ',
  ).convert(configs.map((item) => item.toJson()).toList());
}

class SourceConfigService {
  SourceConfigService({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<SourceConfigFetchResult> fetchT4Configs(String url) async {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) {
      return const SourceConfigFetchResult(
        success: false,
        configs: <T4ApiConfig>[],
        message: 'URL is empty.',
        error: 'empty_url',
        rawData: null,
      );
    }
    try {
      final response = await _dio.get<Object>(
        normalizedUrl,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      final rawData = response.data;
      final normalized = _extractConfigPayload(rawData);
      final configs = T4ApiConfig.listFromDynamic(normalized);
      if (configs.isEmpty) {
        return SourceConfigFetchResult(
          success: false,
          configs: const <T4ApiConfig>[],
          message: 'No valid t4ApiConfigs extracted from payload.',
          error: 'empty_configs',
          rawData: rawData,
        );
      }
      return SourceConfigFetchResult(
        success: true,
        configs: configs,
        message: 'Fetched ${configs.length} config items.',
        error: '',
        rawData: rawData,
      );
    } catch (error) {
      return SourceConfigFetchResult(
        success: false,
        configs: const <T4ApiConfig>[],
        message: 'Fetch source config failed.',
        error: error.toString(),
        rawData: null,
      );
    }
  }

  Object? _extractConfigPayload(Object? rawData) {
    if (rawData is String) {
      final source = rawData.trim();
      if (source.isEmpty) return const <Object>[];
      return _extractConfigPayload(jsonDecode(source));
    }

    if (rawData is List) return rawData;

    if (rawData is! Map) return const <Object>[];

    final map = Map<String, dynamic>.from(rawData);
    final direct =
        map['t4ApiConfigs'] ??
        map['apiConfigs'] ??
        map['sourceConfigs'] ??
        map['sites'];
    if (direct != null) {
      return direct;
    }

    final dataField = map['data'];
    if (dataField is Map) {
      final nested = Map<String, dynamic>.from(dataField);
      if (nested['t4ApiConfigs'] != null) return nested['t4ApiConfigs'];
      if (nested['apiConfigs'] != null) return nested['apiConfigs'];
      if (nested['sourceConfigs'] != null) return nested['sourceConfigs'];
      if (nested['sites'] != null) return nested['sites'];
    }
    if (dataField is List) {
      return dataField;
    }

    return const <Object>[];
  }
}
