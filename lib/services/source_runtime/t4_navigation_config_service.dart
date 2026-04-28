import 'dart:convert';

import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/peekpili/t4_api_config.dart';
import 'package:PiliPlus/services/source_runtime/t4_active_config_service.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';

class T4NavigationApplyResult {
  const T4NavigationApplyResult({
    required this.success,
    required this.navigationBars,
    required this.selectedIndex,
    required this.message,
    required this.error,
    required this.fromConfigId,
    required this.source,
  });

  final bool success;
  final List<NavigationBarType> navigationBars;
  final int selectedIndex;
  final String message;
  final String error;
  final String fromConfigId;
  final T4ActiveConfigSource source;

  bool get hasError => error.isNotEmpty;
}

class T4NavigationConfigService {
  T4NavigationConfigService({
    T4ActiveConfigService? activeConfigService,
  }) : _activeConfigService = activeConfigService ?? T4ActiveConfigService();

  final T4ActiveConfigService _activeConfigService;

  Future<T4NavigationApplyResult> previewFromActive({
    bool forceRemote = false,
    bool allowRemoteFetch = true,
  }) async {
    final activeState = await _activeConfigService.resolve(
      forceRemote: forceRemote,
      allowRemoteFetch: allowRemoteFetch,
    );
    if (!activeState.success || activeState.currentConfig == null) {
      return T4NavigationApplyResult(
        success: false,
        navigationBars: const <NavigationBarType>[],
        selectedIndex: 0,
        message: 'Unable to resolve active T4 config.',
        error: activeState.hasError ? activeState.error : activeState.message,
        fromConfigId: activeState.currentId,
        source: activeState.source,
      );
    }

    final parsed = _parseNavigation(activeState.currentConfig!);
    if (!parsed.success) {
      return T4NavigationApplyResult(
        success: false,
        navigationBars: const <NavigationBarType>[],
        selectedIndex: 0,
        message: parsed.message,
        error: parsed.error,
        fromConfigId: activeState.currentId,
        source: activeState.source,
      );
    }

    return T4NavigationApplyResult(
      success: true,
      navigationBars: parsed.navigationBars,
      selectedIndex: parsed.selectedIndex,
      message: parsed.message,
      error: '',
      fromConfigId: activeState.currentId,
      source: activeState.source,
    );
  }

  Future<T4NavigationApplyResult> applyFromActive({
    bool forceRemote = false,
    bool allowRemoteFetch = true,
  }) async {
    final preview = await previewFromActive(
      forceRemote: forceRemote,
      allowRemoteFetch: allowRemoteFetch,
    );
    if (!preview.success) return preview;

    await GStorage.setting.putAll(<String, dynamic>{
      SettingBoxKey.navBarSort: preview.navigationBars
          .map((item) => item.index)
          .toList(),
      SettingBoxKey.defaultHomePage: preview.selectedIndex,
    });

    return T4NavigationApplyResult(
      success: true,
      navigationBars: preview.navigationBars,
      selectedIndex: preview.selectedIndex,
      message: '${preview.message} Applied to navBarSort/defaultHomePage.',
      error: '',
      fromConfigId: preview.fromConfigId,
      source: preview.source,
    );
  }

  _ParsedNavigationResult _parseNavigation(T4ApiConfig config) {
    final raw = _extractNavigationRaw(config.extra);
    if (raw == null) {
      return const _ParsedNavigationResult(
        success: false,
        navigationBars: <NavigationBarType>[],
        selectedIndex: 0,
        message: 'No supported navigation config key found in active config.',
        error: 'nav_config_not_found',
      );
    }

    final parsedBars = _parseNavigationBars(raw);
    if (parsedBars.isEmpty) {
      return const _ParsedNavigationResult(
        success: false,
        navigationBars: <NavigationBarType>[],
        selectedIndex: 0,
        message: 'Navigation config exists but no supported tab item parsed.',
        error: 'nav_items_empty',
      );
    }

    final defaultType = _parseDefaultNavType(config.extra);
    final selectedIndex = defaultType == null
        ? parsedBars.indexOf(NavigationBarType.home).letOrDefault(0)
        : parsedBars.indexOf(defaultType).letOrDefault(0);

    return _ParsedNavigationResult(
      success: true,
      navigationBars: parsedBars,
      selectedIndex: selectedIndex,
      message:
          'Parsed ${parsedBars.length} nav items from active config `${config.id}`.',
      error: '',
    );
  }

  Object? _extractNavigationRaw(Map<String, dynamic> extra) {
    final directKeys = <String>[
      'navigationBars',
      'navBarSort',
      'bottomNav',
      'bottomTabs',
      'tabs',
      'mainTabs',
      'mainNavigation',
    ];
    for (final key in directKeys) {
      final value = extra[key];
      if (value != null) return value;
    }

    final nestedKeys = <String>['ui', 'layout', 'app', 'home'];
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

  List<NavigationBarType> _parseNavigationBars(Object raw) {
    final list = _normalizeAsList(raw);
    if (list.isEmpty) return const <NavigationBarType>[];

    final parsed = <NavigationBarType>[];
    for (final item in list) {
      final nav = _parseNavType(item);
      if (nav != null && !parsed.contains(nav)) {
        parsed.add(nav);
      }
    }
    return parsed;
  }

  NavigationBarType? _parseDefaultNavType(Map<String, dynamic> extra) {
    const directKeys = <String>[
      'defaultHomePage',
      'defaultNav',
      'defaultTab',
      'defaultNavigation',
      'defaultIndex',
    ];
    Object? value;
    for (final key in directKeys) {
      if (extra[key] != null) {
        value = extra[key];
        break;
      }
    }
    if (value == null) {
      final nested = extra['ui'];
      if (nested is Map) {
        final map = Map<String, dynamic>.from(nested);
        for (final key in directKeys) {
          if (map[key] != null) {
            value = map[key];
            break;
          }
        }
      }
    }
    return _parseNavType(value);
  }

  NavigationBarType? _parseNavType(Object? raw) {
    if (raw == null) return null;
    if (raw is int && raw >= 0 && raw < NavigationBarType.values.length) {
      return NavigationBarType.values[raw];
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

    if (_homeTokens.contains(normalized)) return NavigationBarType.home;
    if (_dynamicsTokens.contains(normalized)) return NavigationBarType.dynamics;
    if (_mineTokens.contains(normalized)) return NavigationBarType.mine;
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

class _ParsedNavigationResult {
  const _ParsedNavigationResult({
    required this.success,
    required this.navigationBars,
    required this.selectedIndex,
    required this.message,
    required this.error,
  });

  final bool success;
  final List<NavigationBarType> navigationBars;
  final int selectedIndex;
  final String message;
  final String error;
}

const Set<String> _homeTokens = <String>{
  'home',
  'index',
  'recommend',
  'rcmd',
};

const Set<String> _dynamicsTokens = <String>{
  'dynamics',
  'dynamic',
  'trend',
  'trending',
  'feed',
  'follow',
};

const Set<String> _mineTokens = <String>{
  'mine',
  'me',
  'my',
  'profile',
  'user',
  'account',
};

extension on int {
  int letOrDefault(int defaultValue) => this >= 0 ? this : defaultValue;
}
