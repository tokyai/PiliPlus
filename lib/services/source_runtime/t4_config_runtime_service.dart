import 'package:PiliPlus/models/peekpili/t4_api_config.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';

class T4ConfigRuntimeState {
  const T4ConfigRuntimeState({
    required this.configs,
    required this.currentId,
    required this.currentConfig,
    required this.error,
  });

  final List<T4ApiConfig> configs;
  final String currentId;
  final T4ApiConfig? currentConfig;
  final String? error;

  bool get hasError => error != null;
}

class T4ConfigRuntimeService {
  const T4ConfigRuntimeService();

  T4ConfigRuntimeState resolve({
    required String configsJson,
    required String currentId,
  }) {
    try {
      final configs = T4ApiConfig.listFromDynamic(configsJson.trim());
      return _resolveCurrent(configs: configs, currentId: currentId);
    } catch (error) {
      return T4ConfigRuntimeState(
        configs: const <T4ApiConfig>[],
        currentId: '',
        currentConfig: null,
        error: error.toString(),
      );
    }
  }

  Future<void> saveCurrentConfigId(String currentId) {
    return GStorage.setting.put(
      SettingBoxKey.t4CurrentApiConfigId,
      currentId.trim(),
    );
  }

  T4ConfigRuntimeState _resolveCurrent({
    required List<T4ApiConfig> configs,
    required String currentId,
  }) {
    if (configs.isEmpty) {
      return const T4ConfigRuntimeState(
        configs: <T4ApiConfig>[],
        currentId: '',
        currentConfig: null,
        error: null,
      );
    }

    final normalizedId = currentId.trim();
    T4ApiConfig? selected;
    for (final item in configs) {
      if (item.id == normalizedId) {
        selected = item;
        break;
      }
    }
    final effective = selected ?? configs.first;

    return T4ConfigRuntimeState(
      configs: configs,
      currentId: effective.id,
      currentConfig: effective,
      error: null,
    );
  }
}
