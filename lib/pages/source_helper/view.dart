import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/services/source_runtime/go_proxy_service.dart';
import 'package:PiliPlus/services/source_runtime/jar_loader_service.dart';
import 'package:PiliPlus/services/source_runtime/php_bridge_service.dart';
import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_service.dart';
import 'package:PiliPlus/services/source_runtime/t4_active_config_service.dart';
import 'package:PiliPlus/services/source_runtime/t4_home_tab_config_service.dart';
import 'package:PiliPlus/services/source_runtime/t4_navigation_config_service.dart';
import 'package:PiliPlus/services/source_runtime/thunder_service.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';

class SourceHelperSettingPage extends StatelessWidget {
  const SourceHelperSettingPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Source Helper')) : null,
      body: ListView(
        children: const [
          _HelperRouteTile(
            title: 'Python Test',
            subtitle: '/pythonTest',
            route: '/pythonTest',
            icon: Icons.data_object_outlined,
          ),
          _HelperRouteTile(
            title: 'CatJs Test',
            subtitle: '/catJsTest',
            route: '/catJsTest',
            icon: Icons.javascript_outlined,
          ),
          _HelperRouteTile(
            title: 'NodeJs Test',
            subtitle: '/nodeJsTest',
            route: '/nodeJsTest',
            icon: Icons.terminal_outlined,
          ),
          _HelperRouteTile(
            title: 'PHP Test',
            subtitle: '/phpTest',
            route: '/phpTest',
            icon: Icons.php_outlined,
          ),
          _HelperRouteTile(
            title: 'PHP Bridge Test',
            subtitle: '/phpBridgeTest',
            route: '/phpBridgeTest',
            icon: Icons.developer_board_outlined,
          ),
          _HelperRouteTile(
            title: 'Jar Test',
            subtitle: '/jarTest',
            route: '/jarTest',
            icon: Icons.data_array_outlined,
          ),
          _HelperRouteTile(
            title: 'GoProxy Test',
            subtitle: '/goProxyTest',
            route: '/goProxyTest',
            icon: Icons.hub_outlined,
          ),
          _HelperRouteTile(
            title: 'Thunder Test',
            subtitle: '/thunderTest',
            route: '/thunderTest',
            icon: Icons.bolt_outlined,
          ),
          _HelperRouteTile(
            title: 'T4 Active Config',
            subtitle: '/t4ActiveConfigTest',
            route: '/t4ActiveConfigTest',
            icon: Icons.dataset_linked_outlined,
          ),
        ],
      ),
    );
  }
}

class _HelperRouteTile extends StatelessWidget {
  const _HelperRouteTile({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Get.toNamed(route),
  );
}

class SourceHelperToolPage extends StatefulWidget {
  const SourceHelperToolPage({
    super.key,
    required this.title,
    required this.routeName,
    required this.engine,
  });

  final String title;
  final String routeName;
  final SourceEngine engine;

  @override
  State<SourceHelperToolPage> createState() => _SourceHelperToolPageState();
}

class _SourceHelperToolPageState extends State<SourceHelperToolPage> {
  late final SourceRuntimeService _runtimeService;
  late final TextEditingController _payloadCtr;
  SourceRuntimeResult? _lastResult;
  bool _isLoading = false;
  bool _executeAsCode = false;

  @override
  void initState() {
    super.initState();
    _runtimeService = Get.find<SourceRuntimeService>();
    _payloadCtr = TextEditingController(
      text:
          '{"message":"ping","timestamp":${DateTime.now().millisecondsSinceEpoch}}',
    );
  }

  @override
  void dispose() {
    _payloadCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _lastResult;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text('Route: ${widget.routeName}'),
            subtitle: Text(
              'Engine: ${widget.engine.key} | Native bridge: ${_runtimeService.supportsNativeBridge}',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _payloadCtr,
            minLines: 4,
            maxLines: 8,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 'Payload',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Execute As Code'),
            subtitle: const Text(
              'Off: payload echo test. On: run payload as runtime code.',
            ),
            value: _executeAsCode,
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _executeAsCode = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: _isLoading ? null : _probe,
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text('Probe Runtime'),
              ),
              FilledButton.icon(
                onPressed: _isLoading ? null : _execute,
                icon: _isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Execute Test'),
              ),
              OutlinedButton.icon(
                onPressed: result == null
                    ? null
                    : () => Utils.copyText(
                        result.mergedOutput,
                        toastText: 'Output copied',
                      ),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy Output'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(result.success ? 'SUCCESS' : 'FAILED'),
                          avatar: Icon(
                            result.success
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            size: 16,
                          ),
                        ),
                        Chip(label: Text('exit=${result.exitCode}')),
                        Chip(label: Text('elapsed=${result.elapsedMs}ms')),
                        if (result.isStub) const Chip(label: Text('STUB')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      result.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(height: 16),
                    SelectableText(
                      result.mergedOutput,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _probe() async {
    setState(() => _isLoading = true);
    final result = await _runtimeService.probe(widget.engine);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _lastResult = result;
    });
  }

  Future<void> _execute() async {
    setState(() => _isLoading = true);
    final result = await _runtimeService.execute(
      engine: widget.engine,
      payload: _payloadCtr.text.trim(),
      options: <String, dynamic>{
        'route': widget.routeName,
        'executeAsCode': _executeAsCode,
      },
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _lastResult = result;
    });
  }
}

class JarTestPage extends StatefulWidget {
  const JarTestPage({super.key});

  @override
  State<JarTestPage> createState() => _JarTestPageState();
}

class _JarTestPageState extends State<JarTestPage> {
  late final JarLoaderService _jarLoaderService;
  late final TextEditingController _jarPathCtr;
  late final TextEditingController _entryClassCtr;
  late final TextEditingController _spiderKeyCtr;
  late final TextEditingController _mainClassCtr;
  late final TextEditingController _methodCtr;
  late final TextEditingController _argsCtr;
  late final TextEditingController _spiderApiPayloadCtr;
  bool _staticOnly = false;
  String _spiderApiMethod = 'homeContent';

  static const List<String> _spiderApiMethods = <String>[
    'homeContent',
    'homeVideoContent',
    'categoryContent',
    'searchContent',
    'detailContent',
    'playerContent',
    'action',
  ];

  JarProbeResult? _probeResult;
  JarInvokeResult? _invokeResult;
  JarLifecycleActionResult? _lifecycleResult;
  JarSpiderCrashStateResult? _crashStateResult;
  JarSpiderCrashCountResult? _crashCountResult;
  JarRuntimeStateResult? _runtimeStateResult;
  JarDataResult? _spiderDataResult;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _jarLoaderService = Get.find<JarLoaderService>();
    _jarPathCtr = TextEditingController(text: Pref.jarTestPath);
    _entryClassCtr = TextEditingController(text: Pref.jarTestEntryClass);
    _spiderKeyCtr = TextEditingController(text: Pref.jarTestEntryClass);
    _mainClassCtr = TextEditingController();
    _methodCtr = TextEditingController(text: Pref.jarTestMethod);
    _argsCtr = TextEditingController(text: Pref.jarTestArgs);
    _spiderApiPayloadCtr = TextEditingController(text: '{"filter": true}');
  }

  @override
  void dispose() {
    _jarPathCtr.dispose();
    _entryClassCtr.dispose();
    _spiderKeyCtr.dispose();
    _mainClassCtr.dispose();
    _methodCtr.dispose();
    _argsCtr.dispose();
    _spiderApiPayloadCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jar Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _jarPathCtr,
            decoration: const InputDecoration(
              labelText: 'Jar Path',
              hintText: '/sdcard/Download/plugin.jar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _entryClassCtr,
                  decoration: const InputDecoration(
                    labelText: 'Entry Class',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _methodCtr,
                  decoration: const InputDecoration(
                    labelText: 'Method',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mainClassCtr,
            decoration: const InputDecoration(
              labelText: 'Main Class (optional override)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Static Method Only'),
            subtitle: const Text(
              'When enabled, only static target methods are considered.',
            ),
            value: _staticOnly,
            onChanged: (value) => setState(() => _staticOnly = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _argsCtr,
            decoration: const InputDecoration(
              labelText: 'Args (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _spiderKeyCtr,
            decoration: const InputDecoration(
              labelText: 'Spider Key (lifecycle)',
              hintText: 'default uses Entry Class if empty',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _probe,
                icon: const Icon(Icons.search),
                label: const Text('Probe Jar'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _invoke,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Load Jar'),
              ),
              OutlinedButton.icon(
                onPressed: _saveJarPreset,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Preset'),
              ),
              OutlinedButton.icon(
                onPressed: _invokeResult == null
                    ? null
                    : () => Utils.copyText(
                        _invokeResult!.mergedOutput,
                        toastText: 'Output copied',
                      ),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy Output'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _markSpiderCrashed,
                icon: const Icon(Icons.warning_amber_outlined),
                label: const Text('Mark Crashed'),
              ),
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _isSpiderCrashed,
                icon: const Icon(Icons.help_outline),
                label: const Text('Is Crashed'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _destroySpider,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Destroy Spider'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _getCrashedSpiderCount,
                icon: const Icon(Icons.numbers_outlined),
                label: const Text('Crashed Count'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _clearCrashedSpiders,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('Clear Crashed'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _clearAllSpiders,
                icon: const Icon(Icons.layers_clear_outlined),
                label: const Text('Clear All'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _getRuntimeState,
                icon: const Icon(Icons.storage_outlined),
                label: const Text('Runtime State'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Spider API Quick Call',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _spiderApiMethod,
            decoration: const InputDecoration(
              labelText: 'API Method',
              border: OutlineInputBorder(),
            ),
            items: _spiderApiMethods
                .map(
                  (method) => DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _spiderApiMethod = value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _spiderApiPayloadCtr,
            minLines: 3,
            maxLines: 6,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              labelText: 'JSON Payload',
              hintText: '{"keyword":"test","pg":"1","quick":false}',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _callSpiderApi,
                icon: const Icon(Icons.api_outlined),
                label: const Text('Call Spider API'),
              ),
              OutlinedButton.icon(
                onPressed: _spiderDataResult == null
                    ? null
                    : () => Utils.copyText(
                        _spiderDataResult!.data,
                        toastText: 'Data copied',
                      ),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy API Data'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_probeResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _probeResult!.success ? 'PROBE OK' : 'PROBE FAIL',
                          ),
                        ),
                        Chip(label: Text('exists=${_probeResult!.exists}')),
                        Chip(label: Text('readable=${_probeResult!.readable}')),
                        Chip(label: Text('size=${_probeResult!.size}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('path: ${_probeResult!.path}'),
                    const SizedBox(height: 4),
                    SelectableText('message: ${_probeResult!.message}'),
                    if (_probeResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_probeResult!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_invokeResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _invokeResult!.success ? 'LOAD OK' : 'LOAD FAIL',
                          ),
                        ),
                        Chip(label: Text('exit=${_invokeResult!.exitCode}')),
                        if (_invokeResult!.isStub)
                          const Chip(label: Text('STUB')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_invokeResult!.message),
                    if (_invokeResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_invokeResult!.error}'),
                    ],
                    const Divider(height: 16),
                    SelectableText(
                      _invokeResult!.mergedOutput,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_lifecycleResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(
                        _lifecycleResult!.success
                            ? 'LIFECYCLE OK'
                            : 'LIFECYCLE FAIL',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText('message: ${_lifecycleResult!.message}'),
                    if (_lifecycleResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_lifecycleResult!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_crashStateResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _crashStateResult!.success
                                ? 'CRASH STATE OK'
                                : 'CRASH STATE FAIL',
                          ),
                        ),
                        Chip(
                          label: Text('crashed=${_crashStateResult!.crashed}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('message: ${_crashStateResult!.message}'),
                    if (_crashStateResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_crashStateResult!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_crashCountResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _crashCountResult!.success
                                ? 'COUNT OK'
                                : 'COUNT FAIL',
                          ),
                        ),
                        Chip(label: Text('count=${_crashCountResult!.count}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('message: ${_crashCountResult!.message}'),
                    if (_crashCountResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_crashCountResult!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_runtimeStateResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _runtimeStateResult!.success
                                ? 'RUNTIME OK'
                                : 'RUNTIME FAIL',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'loaded=${_runtimeStateResult!.loadedCount}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'crashed=${_runtimeStateResult!.crashedCount}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'context=${_runtimeStateResult!.contextCount}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'recent=${_runtimeStateResult!.recentCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('message: ${_runtimeStateResult!.message}'),
                    const SizedBox(height: 4),
                    SelectableText(
                      'loadedIds: ${_runtimeStateResult!.loadedIds.join(', ')}',
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'contextIds: ${_runtimeStateResult!.contextIds.join(', ')}',
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'crashedIds: ${_runtimeStateResult!.crashedIds.join(', ')}',
                    ),
                    if (_runtimeStateResult!.recentItems.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        'recent: ${_runtimeStateResult!.recentItems.map((item) => '${item.key}@${item.jarPath}').join(' | ')}',
                      ),
                    ],
                    if (_runtimeStateResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_runtimeStateResult!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_spiderDataResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _spiderDataResult!.success
                                ? 'SPIDER API OK'
                                : 'SPIDER API FAIL',
                          ),
                        ),
                        Chip(label: Text('method=$_spiderApiMethod')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('message: ${_spiderDataResult!.message}'),
                    if (_spiderDataResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_spiderDataResult!.error}'),
                    ],
                    const Divider(height: 16),
                    SelectableText(
                      _spiderDataResult!.data,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _probe() async {
    setState(() => _loading = true);
    _saveJarPreset(needToast: false);
    final result = await _jarLoaderService.probeJarFile(
      _jarPathCtr.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _probeResult = result;
    });
  }

  Future<void> _invoke() async {
    setState(() => _loading = true);
    _saveJarPreset(needToast: false);
    final result = await _jarLoaderService.loadJar(
      jarPath: _jarPathCtr.text.trim(),
      entryClass: _entryClassCtr.text.trim(),
      mainClass: _mainClassCtr.text.trim(),
      methodName: _methodCtr.text.trim(),
      args: _parseCsv(_argsCtr.text),
      staticOnly: _staticOnly,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invokeResult = result;
    });
  }

  Future<void> _destroySpider() async {
    final args = _resolveLifecycleArgs();
    if (args == null) return;
    setState(() => _loading = true);
    final result = await _jarLoaderService.destroySpider(
      key: args['key']!,
      jarPath: args['jarPath']!,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lifecycleResult = result;
    });
  }

  Future<void> _markSpiderCrashed() async {
    final args = _resolveLifecycleArgs();
    if (args == null) return;
    setState(() => _loading = true);
    final result = await _jarLoaderService.markSpiderCrashed(
      key: args['key']!,
      jarPath: args['jarPath']!,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lifecycleResult = result;
    });
  }

  Future<void> _isSpiderCrashed() async {
    final args = _resolveLifecycleArgs();
    if (args == null) return;
    setState(() => _loading = true);
    final result = await _jarLoaderService.isSpiderCrashed(
      key: args['key']!,
      jarPath: args['jarPath']!,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _crashStateResult = result;
    });
  }

  Future<void> _getCrashedSpiderCount() async {
    setState(() => _loading = true);
    final result = await _jarLoaderService.getCrashedSpiderCount();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _crashCountResult = result;
    });
  }

  Future<void> _clearCrashedSpiders() async {
    setState(() => _loading = true);
    final result = await _jarLoaderService.clearCrashedSpiders();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lifecycleResult = result;
    });
  }

  Future<void> _clearAllSpiders() async {
    setState(() => _loading = true);
    final result = await _jarLoaderService.clearAll();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lifecycleResult = result;
    });
  }

  Future<void> _getRuntimeState() async {
    setState(() => _loading = true);
    final result = await _jarLoaderService.getRuntimeState();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _runtimeStateResult = result;
    });
  }

  Future<void> _callSpiderApi() async {
    final args = _resolveLifecycleArgs();
    if (args == null) return;
    final payload = _parseSpiderApiPayload();
    if (payload == null) return;

    setState(() => _loading = true);
    JarDataResult result;
    switch (_spiderApiMethod) {
      case 'homeContent':
        result = await _jarLoaderService.homeContent(
          key: args['key']!,
          jarPath: args['jarPath']!,
          filter: payload['filter'] is bool ? payload['filter'] as bool : true,
        );
        break;
      case 'homeVideoContent':
        result = await _jarLoaderService.homeVideoContent(
          key: args['key']!,
          jarPath: args['jarPath']!,
        );
        break;
      case 'categoryContent':
        result = await _jarLoaderService.categoryContent(
          key: args['key']!,
          jarPath: args['jarPath']!,
          tid: (payload['tid'] ?? '').toString(),
          pg: (payload['pg'] ?? '1').toString(),
          filter: payload['filter'] is bool ? payload['filter'] as bool : true,
          extend: _asStringMap(payload['extend']),
        );
        break;
      case 'searchContent':
        result = await _jarLoaderService.searchContent(
          key: args['key']!,
          jarPath: args['jarPath']!,
          keyword: (payload['keyword'] ?? '').toString(),
          quick: payload['quick'] is bool ? payload['quick'] as bool : false,
          pg: (payload['pg'] ?? '1').toString(),
        );
        break;
      case 'detailContent':
        result = await _jarLoaderService.detailContent(
          key: args['key']!,
          jarPath: args['jarPath']!,
          ids: _asStringList(payload['ids']),
        );
        break;
      case 'playerContent':
        result = await _jarLoaderService.playerContent(
          key: args['key']!,
          jarPath: args['jarPath']!,
          flag: (payload['flag'] ?? '').toString(),
          id: (payload['id'] ?? '').toString(),
          vipFlags: _asStringList(payload['vipFlags']),
        );
        break;
      case 'action':
        result = await _jarLoaderService.actionContent(
          key: args['key']!,
          jarPath: args['jarPath']!,
          action: (payload['action'] ?? '').toString(),
        );
        break;
      default:
        result = const JarDataResult(
          success: false,
          data: '',
          message: 'Unsupported method.',
          error: 'unsupported_method',
        );
        break;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _spiderDataResult = result;
    });
  }

  List<String> _parseCsv(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const <String>[];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _parseSpiderApiPayload() {
    final text = _spiderApiPayloadCtr.text.trim();
    if (text.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      SmartDialog.showToast('JSON payload must be an object');
      return null;
    } catch (error) {
      SmartDialog.showToast('Invalid JSON payload: $error');
      return null;
    }
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const <String>[];
  }

  Map<String, String> _asStringMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item.toString()),
      );
    }
    return const <String, String>{};
  }

  Map<String, String>? _resolveLifecycleArgs() {
    final jarPath = _jarPathCtr.text.trim();
    final key = _spiderKeyCtr.text.trim().isNotEmpty
        ? _spiderKeyCtr.text.trim()
        : _entryClassCtr.text.trim();
    if (jarPath.isEmpty || key.isEmpty) {
      SmartDialog.showToast('Jar Path and Spider Key are required');
      return null;
    }
    return <String, String>{
      'jarPath': jarPath,
      'key': key,
    };
  }

  void _saveJarPreset({bool needToast = true}) {
    GStorage.setting.putAll(<String, dynamic>{
      SettingBoxKey.jarTestPath: _jarPathCtr.text.trim(),
      SettingBoxKey.jarTestEntryClass: _entryClassCtr.text.trim(),
      SettingBoxKey.jarTestMethod: _methodCtr.text.trim(),
      SettingBoxKey.jarTestArgs: _argsCtr.text.trim(),
    });
    if (needToast) {
      SmartDialog.showToast('Jar preset saved');
    }
  }
}

class PhpBridgeTestPage extends StatefulWidget {
  const PhpBridgeTestPage({super.key});

  @override
  State<PhpBridgeTestPage> createState() => _PhpBridgeTestPageState();
}

class _PhpBridgeTestPageState extends State<PhpBridgeTestPage> {
  late final PhpBridgeService _phpBridgeService;
  late final TextEditingController _commandCtr;
  late final TextEditingController _candidatesCtr;
  late final TextEditingController _documentRootCtr;
  late final TextEditingController _portCtr;
  late final TextEditingController _instancesCtr;
  late final TextEditingController _timeoutCtr;
  late final TextEditingController _codeCtr;

  bool _loading = false;
  bool _installed = false;
  bool _running = false;
  int _serverPort = 0;
  String _version = '';
  String _phpDir = '';
  String _scriptsDir = '';
  String _defaultDownloadUrl = '';
  List<String> _extensions = const <String>[];

  PhpServerStatus? _serverStatus;
  PhpCommandResult? _commandResult;
  PhpExecutionResult? _executionResult;

  @override
  void initState() {
    super.initState();
    _phpBridgeService = Get.find<PhpBridgeService>();
    _commandCtr = TextEditingController(text: 'php');
    _candidatesCtr = TextEditingController(text: 'php/php,tools/php/php,php');
    _documentRootCtr = TextEditingController();
    _portCtr = TextEditingController(text: '9980');
    _instancesCtr = TextEditingController(text: '4');
    _timeoutCtr = TextEditingController(text: '15000');
    _codeCtr = TextEditingController(text: 'echo "php bridge ok\\n";');
    _refreshBasics();
  }

  @override
  void dispose() {
    _commandCtr.dispose();
    _candidatesCtr.dispose();
    _documentRootCtr.dispose();
    _portCtr.dispose();
    _instancesCtr.dispose();
    _timeoutCtr.dispose();
    _codeCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PHP Bridge Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: const Text('Android PHP Bridge'),
            subtitle: Text('installed=$_installed | running=$_running'),
          ),
          TextField(
            controller: _commandCtr,
            decoration: const InputDecoration(
              labelText: 'Command',
              hintText: '/data/user/0/<pkg>/files/tools/php/php',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _candidatesCtr,
            decoration: const InputDecoration(
              labelText: 'Command Candidates (comma separated)',
              hintText: 'tools/php/php,php',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portCtr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _instancesCtr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Instances',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _documentRootCtr,
            decoration: const InputDecoration(
              labelText: 'Document Root (optional)',
              hintText: '/sdcard/Download/php-www',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeoutCtr,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Execute Timeout (ms)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtr,
            minLines: 3,
            maxLines: 8,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              labelText: 'PHP Code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _refreshBasics,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Basics'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _installPhp,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Install PHP'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _startServer,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Server'),
              ),
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _stopServer,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Server'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _fetchExtensions,
                icon: const Icon(Icons.extension_outlined),
                label: const Text('Get Extensions'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _executeCode,
                icon: const Icon(Icons.code_outlined),
                label: const Text('Execute Code'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('installed=$_installed')),
                      Chip(label: Text('running=$_running')),
                      Chip(label: Text('port=$_serverPort')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    'version: ${_version.isEmpty ? '(empty)' : _version}',
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'phpDir: ${_phpDir.isEmpty ? '(empty)' : _phpDir}',
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'scriptsDir: ${_scriptsDir.isEmpty ? '(empty)' : _scriptsDir}',
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'downloadUrl: ${_defaultDownloadUrl.isEmpty ? '(empty)' : _defaultDownloadUrl}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_extensions.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(label: Text('extensions=${_extensions.length}')),
                    const SizedBox(height: 8),
                    SelectableText(_extensions.join(', ')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_commandResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _commandResult!.success
                                ? 'INSTALL OK'
                                : 'INSTALL FAIL',
                          ),
                        ),
                        if (_commandResult!.preparedFromAsset)
                          const Chip(label: Text('FROM ASSET')),
                        if (_commandResult!.downloaded)
                          const Chip(label: Text('DOWNLOADED')),
                        if (_commandResult!.extracted)
                          const Chip(label: Text('EXTRACTED')),
                        if (_commandResult!.archiveFormat.isNotEmpty)
                          Chip(
                            label: Text(
                              'ARCHIVE=${_commandResult!.archiveFormat}',
                            ),
                          ),
                        if (_commandResult!.extractMethod.isNotEmpty)
                          Chip(
                            label: Text(
                              'METHOD=${_commandResult!.extractMethod}',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('command: ${_commandResult!.command}'),
                    if (_commandResult!.archivePath.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        'archivePath: ${_commandResult!.archivePath}',
                      ),
                    ],
                    if (_commandResult!.archiveFormat.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        'archiveFormat: ${_commandResult!.archiveFormat}',
                      ),
                    ],
                    if (_commandResult!.extractMethod.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        'extractMethod: ${_commandResult!.extractMethod}',
                      ),
                    ],
                    const SizedBox(height: 4),
                    SelectableText('message: ${_commandResult!.message}'),
                    if (_commandResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_commandResult!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_serverStatus != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _serverStatus!.success
                                ? 'SERVER OK'
                                : 'SERVER FAIL',
                          ),
                        ),
                        Chip(label: Text('running=${_serverStatus!.running}')),
                        Chip(label: Text('port=${_serverStatus!.port}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('ports: ${_serverStatus!.ports.join(', ')}'),
                    const SizedBox(height: 4),
                    SelectableText(
                      'documentRoot: ${_serverStatus!.documentRoot}',
                    ),
                    const SizedBox(height: 4),
                    SelectableText('message: ${_serverStatus!.message}'),
                    if (_serverStatus!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_serverStatus!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_executionResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(
                        _executionResult!.success
                            ? 'EXECUTE OK'
                            : 'EXECUTE FAIL',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText('message: ${_executionResult!.message}'),
                    if (_executionResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_executionResult!.error}'),
                    ],
                    const Divider(height: 16),
                    SelectableText(
                      _executionResult!.textOutputOrError,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshBasics() async {
    setState(() => _loading = true);
    final installed = await _phpBridgeService.isInstalled();
    final running = await _phpBridgeService.isServerRunning();
    final serverPort = await _phpBridgeService.getServerPort();
    final version = await _phpBridgeService.getVersion();
    final phpDir = await _phpBridgeService.getPhpDir();
    final scriptsDir = await _phpBridgeService.getScriptsDir();
    final downloadUrl = await _phpBridgeService.getDefaultDownloadUrl();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _installed = installed;
      _running = running;
      _serverPort = serverPort;
      _version = version;
      _phpDir = phpDir;
      _scriptsDir = scriptsDir;
      _defaultDownloadUrl = downloadUrl;
    });
  }

  Future<void> _installPhp() async {
    setState(() => _loading = true);
    final result = await _phpBridgeService.installPhp(
      downloadUrl: _defaultDownloadUrl.isEmpty ? null : _defaultDownloadUrl,
      assetCandidates: _parseCsv(_candidatesCtr.text),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _commandResult = result;
    });
    await _refreshBasics();
  }

  Future<void> _startServer() async {
    setState(() => _loading = true);
    final status = await _phpBridgeService.startServer(
      port: int.tryParse(_portCtr.text.trim()) ?? 9980,
      instances: int.tryParse(_instancesCtr.text.trim()) ?? 4,
      command: _commandCtr.text.trim(),
      commandCandidates: _parseCsv(_candidatesCtr.text),
      documentRoot: _documentRootCtr.text.trim().isEmpty
          ? null
          : _documentRootCtr.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _serverStatus = status;
      _running = status.running;
      _serverPort = status.port;
    });
  }

  Future<void> _stopServer() async {
    setState(() => _loading = true);
    final status = await _phpBridgeService.stopServer();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _serverStatus = status;
      _running = status.running;
      _serverPort = status.port;
    });
  }

  Future<void> _fetchExtensions() async {
    setState(() => _loading = true);
    final extensions = await _phpBridgeService.getExtensions();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _extensions = extensions;
    });
  }

  Future<void> _executeCode() async {
    setState(() => _loading = true);
    final result = await _phpBridgeService.executeCode(
      _codeCtr.text.trim(),
      timeoutMs: int.tryParse(_timeoutCtr.text.trim()) ?? 15000,
      command: _commandCtr.text.trim(),
      commandCandidates: _parseCsv(_candidatesCtr.text),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _executionResult = result;
    });
  }

  List<String> _parseCsv(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const <String>[];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class GoProxyTestPage extends StatefulWidget {
  const GoProxyTestPage({super.key});

  @override
  State<GoProxyTestPage> createState() => _GoProxyTestPageState();
}

class _GoProxyTestPageState extends State<GoProxyTestPage> {
  late final GoProxyService _goProxyService;
  late final TextEditingController _commandCtr;
  late final TextEditingController _argsCtr;
  late final TextEditingController _portCtr;
  late final TextEditingController _proxyUrlCtr;
  late final TextEditingController _assetCandidatesCtr;
  late bool _autoStart;

  GoProxyStatus? _status;
  GoProxyCommandResult? _commandResult;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _goProxyService = Get.find<GoProxyService>();
    _commandCtr = TextEditingController(text: Pref.goProxyCommand);
    _argsCtr = TextEditingController(
      text: Pref.goProxyArgs.isEmpty
          ? '--listen 127.0.0.1:9978'
          : Pref.goProxyArgs,
    );
    _portCtr = TextEditingController(text: Pref.goProxyPort.toString());
    _proxyUrlCtr = TextEditingController(
      text: Pref.goProxyProxyUrl.isEmpty
          ? 'http://127.0.0.1:9978'
          : Pref.goProxyProxyUrl,
    );
    _assetCandidatesCtr = TextEditingController(
      text: Pref.goProxyAssetCandidates,
    );
    _autoStart = Pref.goProxyAutoStart;
    _refreshStatus();
    _detectCommand();
  }

  @override
  void dispose() {
    _commandCtr.dispose();
    _argsCtr.dispose();
    _portCtr.dispose();
    _proxyUrlCtr.dispose();
    _assetCandidatesCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('GoProxy Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _commandCtr,
            decoration: const InputDecoration(
              labelText: 'Command',
              hintText: '/data/user/0/<pkg>/files/goproxy',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _argsCtr,
            decoration: const InputDecoration(
              labelText: 'Args',
              hintText: '--listen 127.0.0.1:9978',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portCtr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _proxyUrlCtr,
                  decoration: const InputDecoration(
                    labelText: 'Proxy URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _assetCandidatesCtr,
            decoration: const InputDecoration(
              labelText: 'Asset Candidates (comma separated)',
              hintText: 'assets/runtime/goproxy,assets/goproxy,goproxy',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto Start On Android Launch'),
            subtitle: const Text(
              'Use saved command/args/port/proxyUrl to start GoProxy at app startup.',
            ),
            value: _autoStart,
            onChanged: (value) => setState(() => _autoStart = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _stop,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _refreshStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _detectCommand,
                icon: const Icon(Icons.search),
                label: const Text('Detect Command'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _prepareBinary,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Prepare Asset'),
              ),
              OutlinedButton.icon(
                onPressed: _saveGoProxyPreset,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Preset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_commandResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _commandResult!.success
                                ? 'COMMAND OK'
                                : 'COMMAND FAIL',
                          ),
                        ),
                        if (_commandResult!.preparedFromAsset)
                          const Chip(label: Text('FROM ASSET')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('command: ${_commandResult!.command}'),
                    const SizedBox(height: 4),
                    SelectableText('message: ${_commandResult!.message}'),
                    if (_commandResult!.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_commandResult!.error}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (status != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(status.running ? 'RUNNING' : 'STOPPED'),
                        ),
                        Chip(label: Text('success=${status.success}')),
                        if (status.pid != null)
                          Chip(label: Text('pid=${status.pid}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('proxyUrl: ${status.proxyUrl}'),
                    const SizedBox(height: 4),
                    SelectableText('message: ${status.message}'),
                    if (status.error.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${status.error}'),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    final running = await _goProxyService.isRunning();
    final url = await _goProxyService.getProxyUrl();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = GoProxyStatus(
        success: true,
        running: running,
        proxyUrl: url,
        message: 'Status refreshed',
        error: '',
      );
    });
  }

  Future<void> _detectCommand() async {
    setState(() => _loading = true);
    _saveGoProxyPreset(needToast: false);
    final result = await _goProxyService.detectCommand(
      candidates: _parseCsv(_assetCandidatesCtr.text),
    );
    if (!mounted) return;
    if (result.success && result.command.isNotEmpty) {
      _commandCtr.text = result.command;
    }
    setState(() {
      _loading = false;
      _commandResult = result;
    });
  }

  Future<void> _prepareBinary() async {
    setState(() => _loading = true);
    _saveGoProxyPreset(needToast: false);
    final result = await _goProxyService.prepareBinary(
      assetCandidates: _parseCsv(_assetCandidatesCtr.text),
    );
    if (!mounted) return;
    if (result.success && result.command.isNotEmpty) {
      _commandCtr.text = result.command;
    }
    setState(() {
      _loading = false;
      _commandResult = result;
    });
  }

  Future<void> _start() async {
    setState(() => _loading = true);
    _saveGoProxyPreset(needToast: false);
    final args = _parseArgs(_argsCtr.text);
    final port = int.tryParse(_portCtr.text.trim()) ?? 9978;
    final status = await _goProxyService.start(
      command: _commandCtr.text.trim(),
      args: args,
      port: port,
      proxyUrl: _proxyUrlCtr.text.trim().isEmpty
          ? null
          : _proxyUrlCtr.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = status;
    });
  }

  Future<void> _stop() async {
    setState(() => _loading = true);
    final status = await _goProxyService.stop();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = status;
    });
  }

  List<String> _parseArgs(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const <String>[];
    return text.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).toList();
  }

  List<String> _parseCsv(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const <String>[];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _saveGoProxyPreset({bool needToast = true}) {
    GStorage.setting.putAll(<String, dynamic>{
      SettingBoxKey.goProxyCommand: _commandCtr.text.trim(),
      SettingBoxKey.goProxyArgs: _argsCtr.text.trim(),
      SettingBoxKey.goProxyPort: int.tryParse(_portCtr.text.trim()) ?? 9978,
      SettingBoxKey.goProxyProxyUrl: _proxyUrlCtr.text.trim(),
      SettingBoxKey.goProxyAssetCandidates: _assetCandidatesCtr.text.trim(),
      SettingBoxKey.goProxyAutoStart: _autoStart,
    });
    if (needToast) {
      SmartDialog.showToast('GoProxy preset saved');
    }
  }
}

class ThunderTestPage extends StatefulWidget {
  const ThunderTestPage({super.key});

  @override
  State<ThunderTestPage> createState() => _ThunderTestPageState();
}

class _ThunderTestPageState extends State<ThunderTestPage> {
  late final ThunderService _thunderService;
  late final TextEditingController _urlCtr;
  late final TextEditingController _taskIdCtr;

  bool _loading = false;
  bool _supported = false;
  ThunderParseResult? _parseResult;
  ThunderPlayUrlResult? _playResult;
  ThunderStatusResult? _statusResult;
  ThunderRuntimeStateResult? _runtimeStateResult;

  @override
  void initState() {
    super.initState();
    _thunderService = Get.find<ThunderService>();
    _urlCtr = TextEditingController(text: 'magnet:?xt=urn:btih:');
    _taskIdCtr = TextEditingController();
    _checkSupported();
  }

  @override
  void dispose() {
    _urlCtr.dispose();
    _taskIdCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thunder Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: const Text('Android Thunder Bridge'),
            subtitle: Text(
              _supported ? 'supported=true' : 'supported=false',
            ),
          ),
          TextField(
            controller: _urlCtr,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Magnet/Thunder URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taskIdCtr,
            decoration: const InputDecoration(
              labelText: 'Task ID (for stopTask)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _checkSupported,
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text('Is Supported'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _parse,
                icon: const Icon(Icons.search),
                label: const Text('Parse Magnet'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _getPlayUrl,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Get Play Url'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _stopTask,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop Task'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _stopLatestTask,
                icon: const Icon(Icons.stop_outlined),
                label: const Text('Stop Latest'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _release,
                icon: const Icon(Icons.power_settings_new_outlined),
                label: const Text('Release'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _getRuntimeState,
                icon: const Icon(Icons.storage_outlined),
                label: const Text('Runtime State'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_parseResult != null) _buildParseCard(context, _parseResult!),
          const SizedBox(height: 8),
          if (_playResult != null) _buildPlayCard(context, _playResult!),
          const SizedBox(height: 8),
          if (_statusResult != null) _buildStatusCard(context, _statusResult!),
          const SizedBox(height: 8),
          if (_runtimeStateResult != null)
            _buildRuntimeStateCard(context, _runtimeStateResult!),
        ],
      ),
    );
  }

  Widget _buildParseCard(BuildContext context, ThunderParseResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(result.success ? 'PARSE OK' : 'PARSE FAIL')),
                Chip(label: Text('protocol=${result.protocol}')),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText('normalized: ${result.normalizedUrl}'),
            const SizedBox(height: 4),
            SelectableText('infoHash: ${result.infoHash}'),
            const SizedBox(height: 4),
            SelectableText('message: ${result.message}'),
            if (result.error.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText('error: ${result.error}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayCard(BuildContext context, ThunderPlayUrlResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(result.success ? 'PLAY URL OK' : 'PLAY URL FAIL'),
                ),
                Chip(label: Text('protocol=${result.protocol}')),
                if (result.taskId.isNotEmpty)
                  Chip(label: Text('taskId=${result.taskId}')),
                Chip(label: Text('active=${result.activeTaskCount}')),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText('playUrl: ${result.playUrl}'),
            const SizedBox(height: 4),
            SelectableText('infoHash: ${result.infoHash}'),
            const SizedBox(height: 4),
            SelectableText('message: ${result.message}'),
            if (result.error.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText('error: ${result.error}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, ThunderStatusResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(result.success ? 'STATUS OK' : 'STATUS FAIL')),
                if (result.taskId.isNotEmpty)
                  Chip(label: Text('taskId=${result.taskId}')),
                Chip(label: Text('active=${result.activeTaskCount}')),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText('message: ${result.message}'),
            if (result.error.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText('error: ${result.error}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimeStateCard(
    BuildContext context,
    ThunderRuntimeStateResult result,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(result.success ? 'RUNTIME OK' : 'RUNTIME FAIL'),
                ),
                Chip(label: Text('active=${result.activeTaskCount}')),
                Chip(label: Text('seq=${result.taskSequence}')),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText('message: ${result.message}'),
            if (result.error.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText('error: ${result.error}'),
            ],
            if (result.tasks.isNotEmpty) ...[
              const Divider(height: 16),
              SelectableText(
                result.tasks
                    .map(
                      (item) =>
                          '${item.taskId} [${item.protocol}] age=${item.ageMs}ms play=${item.playUrl}',
                    )
                    .join('\n'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _checkSupported() async {
    setState(() => _loading = true);
    final supported = await _thunderService.isSupported();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _supported = supported;
    });
  }

  Future<void> _parse() async {
    setState(() => _loading = true);
    final result = await _thunderService.parseMagnet(_urlCtr.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _parseResult = result;
    });
  }

  Future<void> _getPlayUrl() async {
    setState(() => _loading = true);
    final result = await _thunderService.getPlayUrl(url: _urlCtr.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _playResult = result;
    });
  }

  Future<void> _stopTask() async {
    setState(() => _loading = true);
    final result = await _thunderService.stopTask(_taskIdCtr.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusResult = result;
    });
  }

  Future<void> _stopLatestTask() async {
    setState(() => _loading = true);
    final result = await _thunderService.stopTask('');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusResult = result;
    });
  }

  Future<void> _release() async {
    setState(() => _loading = true);
    final result = await _thunderService.release();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusResult = result;
    });
  }

  Future<void> _getRuntimeState() async {
    setState(() => _loading = true);
    final result = await _thunderService.getRuntimeState();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _runtimeStateResult = result;
    });
  }
}

class T4ActiveConfigTestPage extends StatefulWidget {
  const T4ActiveConfigTestPage({super.key});

  @override
  State<T4ActiveConfigTestPage> createState() => _T4ActiveConfigTestPageState();
}

class _T4ActiveConfigTestPageState extends State<T4ActiveConfigTestPage> {
  late final T4ActiveConfigService _activeConfigService;
  late final T4HomeTabConfigService _homeTabConfigService;
  late final T4NavigationConfigService _navigationConfigService;

  T4ActiveConfigState? _state;
  T4HomeTabApplyResult? _homeTabResult;
  T4NavigationApplyResult? _navigationResult;
  bool _loading = false;
  bool _forceRemote = false;
  bool _persistRemoteSnapshot = false;

  @override
  void initState() {
    super.initState();
    _activeConfigService = Get.find<T4ActiveConfigService>();
    _homeTabConfigService = Get.find<T4HomeTabConfigService>();
    _navigationConfigService = Get.find<T4NavigationConfigService>();
    _resolve();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(title: const Text('T4 Active Config')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Force remote fetch'),
            subtitle: const Text(
              'Ignore local-mode switch and always try source config URL first.',
            ),
            value: _forceRemote,
            onChanged: (value) => setState(() => _forceRemote = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Persist remote snapshot'),
            subtitle: const Text(
              'When remote resolves successfully, save configs to local storage.',
            ),
            value: _persistRemoteSnapshot,
            onChanged: (value) =>
                setState(() => _persistRemoteSnapshot = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _resolve,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Resolve Active'),
              ),
              OutlinedButton.icon(
                onPressed: state == null
                    ? null
                    : () => Utils.copyText(
                        _debugSummary(state),
                        toastText: 'Summary copied',
                      ),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy Summary'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _previewNavigation,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview Nav'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _applyNavigation,
                icon: const Icon(Icons.publish_outlined),
                label: const Text('Apply Nav'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _previewHomeTabs,
                icon: const Icon(Icons.preview_outlined),
                label: const Text('Preview Home Tabs'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _applyHomeTabs,
                icon: const Icon(Icons.playlist_add_check_outlined),
                label: const Text('Apply Home Tabs'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(state.success ? 'SUCCESS' : 'FAILED')),
                        Chip(label: Text('source=${state.source.name}')),
                        Chip(label: Text('count=${state.configs.length}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('message: ${state.message}'),
                    if (state.hasError) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${state.error}'),
                    ],
                    const SizedBox(height: 4),
                    SelectableText('sourceUrl: ${state.sourceUrl}'),
                    const SizedBox(height: 4),
                    SelectableText('usedLocalMode: ${state.usedLocalMode}'),
                    const Divider(height: 16),
                    SelectableText(
                      'currentId: ${state.currentId.isEmpty ? '(none)' : state.currentId}',
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'currentName: ${state.currentConfig?.name ?? '(none)'}',
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'currentApiUrl: ${state.currentConfig?.apiUrl ?? '(none)'}',
                    ),
                    if (state.currentConfig?.description case final desc?) ...[
                      const SizedBox(height: 4),
                      SelectableText('description: $desc'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_homeTabResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _homeTabResult!.success
                                ? 'HOME TABS READY'
                                : 'HOME TABS FAILED',
                          ),
                        ),
                        Chip(
                          label: Text('source=${_homeTabResult!.source.name}'),
                        ),
                        Chip(
                          label: Text('items=${_homeTabResult!.tabs.length}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'fromConfigId: ${_homeTabResult!.fromConfigId}',
                    ),
                    const SizedBox(height: 4),
                    SelectableText('message: ${_homeTabResult!.message}'),
                    if (_homeTabResult!.hasError) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_homeTabResult!.error}'),
                    ],
                    const Divider(height: 16),
                    SelectableText(
                      'tabBarSort: ${_homeTabResult!.tabs.map((item) => item.name).join(', ')}',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_navigationResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _navigationResult!.success
                                ? 'NAV READY'
                                : 'NAV FAILED',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'source=${_navigationResult!.source.name}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'items=${_navigationResult!.navigationBars.length}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'default=${_navigationResult!.selectedIndex}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'fromConfigId: ${_navigationResult!.fromConfigId}',
                    ),
                    const SizedBox(height: 4),
                    SelectableText('message: ${_navigationResult!.message}'),
                    if (_navigationResult!.hasError) ...[
                      const SizedBox(height: 4),
                      SelectableText('error: ${_navigationResult!.error}'),
                    ],
                    const Divider(height: 16),
                    SelectableText(
                      'navBarSort: ${_navigationResult!.navigationBars.map((item) => item.name).join(', ')}',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _resolve() async {
    setState(() => _loading = true);
    final state = await _activeConfigService.resolve(
      forceRemote: _forceRemote,
      persistRemoteSnapshot: _persistRemoteSnapshot,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _state = state;
    });
  }

  Future<void> _previewHomeTabs() async {
    setState(() => _loading = true);
    final result = await _homeTabConfigService.previewFromActive(
      forceRemote: _forceRemote,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _homeTabResult = result;
    });
    if (result.success) {
      SmartDialog.showToast('Home tabs parsed from active config');
    } else {
      SmartDialog.showToast('Home tabs parse failed: ${result.error}');
    }
  }

  Future<void> _applyHomeTabs() async {
    setState(() => _loading = true);
    final result = await _homeTabConfigService.applyFromActive(
      forceRemote: _forceRemote,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _homeTabResult = result;
    });
    if (result.success) {
      SmartDialog.showToast(
        'Applied tabBarSort. Restart main page to take effect.',
      );
    } else {
      SmartDialog.showToast('Apply home tabs failed: ${result.error}');
    }
  }

  Future<void> _previewNavigation() async {
    setState(() => _loading = true);
    final result = await _navigationConfigService.previewFromActive(
      forceRemote: _forceRemote,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _navigationResult = result;
    });
    if (result.success) {
      SmartDialog.showToast('Navigation parsed from active config');
    } else {
      SmartDialog.showToast('Navigation parse failed: ${result.error}');
    }
  }

  Future<void> _applyNavigation() async {
    setState(() => _loading = true);
    final result = await _navigationConfigService.applyFromActive(
      forceRemote: _forceRemote,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _navigationResult = result;
    });
    if (result.success) {
      SmartDialog.showToast(
        'Applied navBarSort/defaultHomePage. Restart main page to take effect.',
      );
    } else {
      SmartDialog.showToast('Apply navigation failed: ${result.error}');
    }
  }

  String _debugSummary(T4ActiveConfigState state) {
    final currentName = state.currentConfig?.name ?? '(none)';
    final currentUrl = state.currentConfig?.apiUrl ?? '(none)';
    return [
      'success=${state.success}',
      'source=${state.source.name}',
      'count=${state.configs.length}',
      'currentId=${state.currentId}',
      'currentName=$currentName',
      'currentApiUrl=$currentUrl',
      'sourceUrl=${state.sourceUrl}',
      'usedLocalMode=${state.usedLocalMode}',
      'message=${state.message}',
      if (state.hasError) 'error=${state.error}',
    ].join('\n');
  }
}
