import 'package:PiliPlus/models/peekpili/t4_api_config.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';

abstract final class PeekPiliConfigStore {
  static String get t4SourceConfigUrl => GStorage.setting.get(
    SettingBoxKey.t4SourceConfigUrl,
    defaultValue: '',
  );

  static bool get t4IsLocalConfig => GStorage.setting.get(
    SettingBoxKey.t4IsLocalConfig,
    defaultValue: false,
  );

  static bool get t4NavAutoApply => GStorage.setting.get(
    SettingBoxKey.t4NavAutoApply,
    defaultValue: false,
  );

  static String get t4CurrentApiConfigId => GStorage.setting.get(
    SettingBoxKey.t4CurrentApiConfigId,
    defaultValue: '',
  );

  static List<T4ApiConfig> get t4ApiConfigs {
    final raw = GStorage.setting.get(
      SettingBoxKey.t4ApiConfigs,
      defaultValue: '[]',
    );
    try {
      return T4ApiConfig.listFromDynamic(raw);
    } catch (_) {
      return const <T4ApiConfig>[];
    }
  }

  static String get t4ApiConfigsJson => T4ApiConfig.encodeList(t4ApiConfigs);

  static String get tmdbAccessToken => GStorage.setting.get(
    SettingBoxKey.tmdbAccessToken,
    defaultValue: '',
  );

  static bool get tmdbIntegrationEnabled => GStorage.setting.get(
    SettingBoxKey.tmdbIntegrationEnabled,
    defaultValue: false,
  );

  static String get tmdbImageProxy => GStorage.setting.get(
    SettingBoxKey.tmdbImageProxy,
    defaultValue: '',
  );

  static Future<void> saveT4Config({
    required String sourceConfigUrl,
    required bool isLocalConfig,
    required String currentApiConfigId,
    required List<T4ApiConfig> apiConfigs,
    required bool navAutoApply,
  }) => GStorage.setting.putAll(<String, dynamic>{
    SettingBoxKey.t4SourceConfigUrl: sourceConfigUrl.trim(),
    SettingBoxKey.t4IsLocalConfig: isLocalConfig,
    SettingBoxKey.t4CurrentApiConfigId: currentApiConfigId.trim(),
    SettingBoxKey.t4ApiConfigs: T4ApiConfig.encodeList(apiConfigs),
    SettingBoxKey.t4NavAutoApply: navAutoApply,
  });

  static Future<void> saveTmdbConfig({
    required String accessToken,
    required bool integrationEnabled,
    required String imageProxy,
  }) => GStorage.setting.putAll(<String, dynamic>{
    SettingBoxKey.tmdbAccessToken: accessToken.trim(),
    SettingBoxKey.tmdbIntegrationEnabled: integrationEnabled,
    SettingBoxKey.tmdbImageProxy: imageProxy.trim(),
  });
}
