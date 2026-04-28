import 'dart:convert';

import 'package:PiliPlus/models/peekpili/t4_api_config.dart';
import 'package:PiliPlus/services/source_runtime/source_config_service.dart';
import 'package:PiliPlus/services/source_runtime/t4_config_runtime_service.dart';
import 'package:PiliPlus/utils/peekpili_config_store.dart';

enum T4ActiveConfigSource {
  local,
  remote,
  fallbackLocal,
  unavailable,
}

class T4ActiveConfigState {
  const T4ActiveConfigState({
    required this.success,
    required this.source,
    required this.configs,
    required this.currentId,
    required this.currentConfig,
    required this.message,
    required this.error,
    required this.sourceUrl,
    required this.usedLocalMode,
  });

  final bool success;
  final T4ActiveConfigSource source;
  final List<T4ApiConfig> configs;
  final String currentId;
  final T4ApiConfig? currentConfig;
  final String message;
  final String error;
  final String sourceUrl;
  final bool usedLocalMode;

  bool get hasError => error.isNotEmpty;
}

class T4ActiveConfigService {
  T4ActiveConfigService({
    SourceConfigService? sourceConfigService,
    T4ConfigRuntimeService? runtimeService,
  }) : _sourceConfigService = sourceConfigService ?? SourceConfigService(),
       _runtimeService = runtimeService ?? const T4ConfigRuntimeService();

  final SourceConfigService _sourceConfigService;
  final T4ConfigRuntimeService _runtimeService;

  Future<T4ActiveConfigState> resolve({
    bool forceRemote = false,
    bool persistRemoteSnapshot = false,
  }) async {
    final sourceUrl = PeekPiliConfigStore.t4SourceConfigUrl.trim();
    final localJson = PeekPiliConfigStore.t4ApiConfigsJson;
    final currentId = PeekPiliConfigStore.t4CurrentApiConfigId;
    final isLocalMode = PeekPiliConfigStore.t4IsLocalConfig;

    if (isLocalMode && !forceRemote) {
      return _resolveFromJson(
        configsJson: localJson,
        currentId: currentId,
        source: T4ActiveConfigSource.local,
        sourceUrl: sourceUrl,
        usedLocalMode: true,
        messageOnSuccess: 'Using local t4ApiConfigs.',
      );
    }

    if (sourceUrl.isEmpty && !forceRemote) {
      return _resolveFromJson(
        configsJson: localJson,
        currentId: currentId,
        source: T4ActiveConfigSource.fallbackLocal,
        sourceUrl: sourceUrl,
        usedLocalMode: false,
        messageOnSuccess:
            'Source config URL is empty; fallback to local t4ApiConfigs.',
      );
    }

    final remoteResult = await _sourceConfigService.fetchT4Configs(sourceUrl);
    if (remoteResult.success) {
      final configsJson = jsonEncode(
        remoteResult.configs.map((item) => item.toJson()).toList(),
      );
      final resolved = _resolveFromJson(
        configsJson: configsJson,
        currentId: currentId,
        source: T4ActiveConfigSource.remote,
        sourceUrl: sourceUrl,
        usedLocalMode: isLocalMode,
        messageOnSuccess: remoteResult.message,
      );
      if (resolved.success) {
        await _runtimeService.saveCurrentConfigId(resolved.currentId);
        if (persistRemoteSnapshot) {
          await PeekPiliConfigStore.saveT4Config(
            sourceConfigUrl: sourceUrl,
            isLocalConfig: isLocalMode,
            currentApiConfigId: resolved.currentId,
            apiConfigs: resolved.configs,
          );
        }
      }
      return resolved;
    }

    final fallback = _resolveFromJson(
      configsJson: localJson,
      currentId: currentId,
      source: T4ActiveConfigSource.fallbackLocal,
      sourceUrl: sourceUrl,
      usedLocalMode: isLocalMode,
      messageOnSuccess:
          'Remote fetch failed (${remoteResult.error}); fallback to local t4ApiConfigs.',
    );
    if (fallback.success) {
      return fallback;
    }
    return T4ActiveConfigState(
      success: false,
      source: T4ActiveConfigSource.unavailable,
      configs: const <T4ApiConfig>[],
      currentId: '',
      currentConfig: null,
      message: 'No valid t4 config available.',
      error: remoteResult.error,
      sourceUrl: sourceUrl,
      usedLocalMode: isLocalMode,
    );
  }

  T4ActiveConfigState _resolveFromJson({
    required String configsJson,
    required String currentId,
    required T4ActiveConfigSource source,
    required String sourceUrl,
    required bool usedLocalMode,
    required String messageOnSuccess,
  }) {
    final runtimeState = _runtimeService.resolve(
      configsJson: configsJson,
      currentId: currentId,
    );
    if (runtimeState.hasError) {
      return T4ActiveConfigState(
        success: false,
        source: source,
        configs: runtimeState.configs,
        currentId: runtimeState.currentId,
        currentConfig: runtimeState.currentConfig,
        message: 't4ApiConfigs parse failed.',
        error: runtimeState.error ?? 'parse_failed',
        sourceUrl: sourceUrl,
        usedLocalMode: usedLocalMode,
      );
    }
    if (runtimeState.configs.isEmpty || runtimeState.currentConfig == null) {
      return T4ActiveConfigState(
        success: false,
        source: source,
        configs: runtimeState.configs,
        currentId: runtimeState.currentId,
        currentConfig: runtimeState.currentConfig,
        message: 'No t4 configs available.',
        error: 'empty_configs',
        sourceUrl: sourceUrl,
        usedLocalMode: usedLocalMode,
      );
    }
    return T4ActiveConfigState(
      success: true,
      source: source,
      configs: runtimeState.configs,
      currentId: runtimeState.currentId,
      currentConfig: runtimeState.currentConfig,
      message: messageOnSuccess,
      error: '',
      sourceUrl: sourceUrl,
      usedLocalMode: usedLocalMode,
    );
  }
}
