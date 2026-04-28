import 'dart:convert';

import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/models/peekpili/t4_api_config.dart';
import 'package:PiliPlus/services/source_runtime/t4_active_config_service.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';

class T4HomeTabApplyResult {
  const T4HomeTabApplyResult({
    required this.success,
    required this.tabs,
    required this.message,
    required this.error,
    required this.fromConfigId,
    required this.source,
  });

  final bool success;
  final List<HomeTabType> tabs;
  final String message;
  final String error;
  final String fromConfigId;
  final T4ActiveConfigSource source;

  bool get hasError => error.isNotEmpty;
}

class T4HomeTabConfigService {
  T4HomeTabConfigService({
    T4ActiveConfigService? activeConfigService,
  }) : _activeConfigService = activeConfigService ?? T4ActiveConfigService();

  final T4ActiveConfigService _activeConfigService;

  Future<T4HomeTabApplyResult> previewFromActive({
    bool forceRemote = false,
    bool allowRemoteFetch = true,
  }) async {
    final activeState = await _activeConfigService.resolve(
      forceRemote: forceRemote,
      allowRemoteFetch: allowRemoteFetch,
    );
    if (!activeState.success || activeState.currentConfig == null) {
      return T4HomeTabApplyResult(
        success: false,
        tabs: const <HomeTabType>[],
        message: 'Unable to resolve active T4 config.',
        error: activeState.hasError ? activeState.error : activeState.message,
        fromConfigId: activeState.currentId,
        source: activeState.source,
      );
    }

    final parsed = _parseHomeTabs(activeState.currentConfig!);
    if (!parsed.success) {
      return T4HomeTabApplyResult(
        success: false,
        tabs: const <HomeTabType>[],
        message: parsed.message,
        error: parsed.error,
        fromConfigId: activeState.currentId,
        source: activeState.source,
      );
    }

    return T4HomeTabApplyResult(
      success: true,
      tabs: parsed.tabs,
      message: parsed.message,
      error: '',
      fromConfigId: activeState.currentId,
      source: activeState.source,
    );
  }

  Future<T4HomeTabApplyResult> applyFromActive({
    bool forceRemote = false,
    bool allowRemoteFetch = true,
  }) async {
    final preview = await previewFromActive(
      forceRemote: forceRemote,
      allowRemoteFetch: allowRemoteFetch,
    );
    if (!preview.success) return preview;

    await GStorage.setting.put(
      SettingBoxKey.tabBarSort,
      preview.tabs.map((item) => item.index).toList(),
    );

    return T4HomeTabApplyResult(
      success: true,
      tabs: preview.tabs,
      message: '${preview.message} Applied to tabBarSort.',
      error: '',
      fromConfigId: preview.fromConfigId,
      source: preview.source,
    );
  }

  _ParsedHomeTabsResult _parseHomeTabs(T4ApiConfig config) {
    final raw = _extractHomeTabsRaw(config.extra);
    if (raw == null) {
      return const _ParsedHomeTabsResult(
        success: false,
        tabs: <HomeTabType>[],
        message: 'No supported home tabs key found in active config.',
        error: 'home_tabs_not_found',
      );
    }

    final tabs = _parseTabs(raw);
    if (tabs.isEmpty) {
      return const _ParsedHomeTabsResult(
        success: false,
        tabs: <HomeTabType>[],
        message: 'Home tabs config exists but no supported item parsed.',
        error: 'home_tabs_empty',
      );
    }

    return _ParsedHomeTabsResult(
      success: true,
      tabs: tabs,
      message:
          'Parsed ${tabs.length} home tabs from active config `${config.id}`.',
      error: '',
    );
  }

  Object? _extractHomeTabsRaw(Map<String, dynamic> extra) {
    const directKeys = <String>[
      'homeTabs',
      'homeTabSort',
      'homeBarSort',
      'homeNavigation',
      'topTabs',
      'tabBarSort',
      'homeChannels',
      'homeSections',
    ];
    for (final key in directKeys) {
      final value = extra[key];
      if (value != null) return value;
    }

    const nestedKeys = <String>['home', 'ui', 'layout', 'app'];
    for (final key in nestedKeys) {
      final nested = extra[key];
      if (nested is Map) {
        final map = Map<String, dynamic>.from(nested);
        for (final directKey in directKeys) {
          final value = map[directKey];
          if (value != null) return value;
        }
      }
    }
    return null;
  }

  List<HomeTabType> _parseTabs(Object raw) {
    final list = _normalizeAsList(raw);
    if (list.isEmpty) return const <HomeTabType>[];

    final parsed = <HomeTabType>[];
    for (final item in list) {
      final tab = _parseTabType(item);
      if (tab != null && !parsed.contains(tab)) {
        parsed.add(tab);
      }
    }
    return parsed;
  }

  HomeTabType? _parseTabType(Object? raw) {
    if (raw == null) return null;
    if (raw is int && raw >= 0 && raw < HomeTabType.values.length) {
      return HomeTabType.values[raw];
    }

    String token;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      token =
          (map['id'] ??
                  map['key'] ??
                  map['type'] ??
                  map['route'] ??
                  map['path'] ??
                  map['name'] ??
                  map['title'] ??
                  '')
              .toString();
    } else {
      token = raw.toString();
    }

    final normalized = _normalizeToken(token);
    if (normalized.isEmpty) return null;

    if (_liveTokens.contains(normalized)) return HomeTabType.live;
    if (_rcmdTokens.contains(normalized)) return HomeTabType.rcmd;
    if (_hotTokens.contains(normalized)) return HomeTabType.hot;
    if (_rankTokens.contains(normalized)) return HomeTabType.rank;
    if (_bangumiTokens.contains(normalized)) return HomeTabType.bangumi;
    if (_cinemaTokens.contains(normalized)) return HomeTabType.cinema;
    return null;
  }

  List<Object?> _normalizeAsList(Object raw) {
    if (raw is List) return raw;
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return const <Object?>[];
      if (text.startsWith('[') || text.startsWith('{')) {
        try {
          final decoded = jsonDecode(text);
          return _normalizeAsList(decoded);
        } catch (_) {
          return text.split(',').map((item) => item.trim()).toList();
        }
      }
      return text.split(',').map((item) => item.trim()).toList();
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final items = map['items'] ?? map['tabs'] ?? map['list'];
      if (items is List) return items;
    }
    return const <Object?>[];
  }

  String _normalizeToken(String raw) {
    var token = raw.trim().toLowerCase();
    if (token.isEmpty) return '';
    if (token.startsWith('/')) token = token.substring(1);
    token = token.replaceAll('\\', '/');
    if (token.contains('/')) {
      final segments = token.split('/');
      token = segments.lastWhere((item) => item.isNotEmpty, orElse: () => '');
    }
    token = token.replaceAll(RegExp(r'[\s_-]+'), '');
    return token;
  }
}

class _ParsedHomeTabsResult {
  const _ParsedHomeTabsResult({
    required this.success,
    required this.tabs,
    required this.message,
    required this.error,
  });

  final bool success;
  final List<HomeTabType> tabs;
  final String message;
  final String error;
}

const Set<String> _liveTokens = <String>{'live', 'zhibo'};
const Set<String> _rcmdTokens = <String>{'rcmd', 'recommend', 'home', 'index'};
const Set<String> _hotTokens = <String>{'hot', 'trending', 'popular'};
const Set<String> _rankTokens = <String>{'rank', 'region', 'zone', 'category'};
const Set<String> _bangumiTokens = <String>{'bangumi', 'anime', 'pgc', 'tv'};
const Set<String> _cinemaTokens = <String>{'cinema', 'movie', 'film', 'ys'};
