import 'dart:convert';

import 'package:PiliPlus/models/peekpili/t4_api_config.dart';
import 'package:PiliPlus/services/source_runtime/source_config_service.dart';
import 'package:PiliPlus/utils/peekpili_config_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class SourceConfigSettingPage extends StatefulWidget {
  const SourceConfigSettingPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<SourceConfigSettingPage> createState() =>
      _SourceConfigSettingPageState();
}

class _SourceConfigSettingPageState extends State<SourceConfigSettingPage> {
  late final TextEditingController _sourceConfigUrlCtr;
  late final TextEditingController _currentApiConfigIdCtr;
  late final TextEditingController _apiConfigsJsonCtr;
  final _sourceConfigService = SourceConfigService();
  late bool _isLocalConfig;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _sourceConfigUrlCtr = TextEditingController(
      text: PeekPiliConfigStore.t4SourceConfigUrl,
    );
    _currentApiConfigIdCtr = TextEditingController(
      text: PeekPiliConfigStore.t4CurrentApiConfigId,
    );
    _apiConfigsJsonCtr = TextEditingController(
      text: PeekPiliConfigStore.t4ApiConfigsJson,
    );
    _isLocalConfig = PeekPiliConfigStore.t4IsLocalConfig;
  }

  @override
  void dispose() {
    _sourceConfigUrlCtr.dispose();
    _currentApiConfigIdCtr.dispose();
    _apiConfigsJsonCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Source Config')) : null,
      body: ListView(
        padding: padding.copyWith(
          top: 20,
          left: 20 + (showAppBar ? padding.left : 0),
          right: 20 + (showAppBar ? padding.right : 0),
          bottom: padding.bottom + 100,
        ),
        children: [
          TextField(
            controller: _sourceConfigUrlCtr,
            decoration: const InputDecoration(
              labelText: 'Source Config URL',
              hintText: 'https://example.com/source-config.json',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isLocalConfig,
            onChanged: (value) => setState(() => _isLocalConfig = value),
            title: const Text('Use local config'),
            subtitle: const Text(
              'Enabled: read local t4ApiConfigs; Disabled: fetch from URL.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentApiConfigIdCtr,
            decoration: const InputDecoration(
              labelText: 'Current API Config ID',
              hintText: 'default',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _isFetching ? null : _fetchFromUrl,
                icon: _isFetching
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: const Text('Fetch URL'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _loadSampleConfigs,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Load Sample'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _formatJson,
                icon: const Icon(Icons.code),
                label: const Text('Format JSON'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiConfigsJsonCtr,
            minLines: 8,
            maxLines: 18,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 't4ApiConfigs JSON Array',
              hintText: '[{"id":"default","name":"Default","apiUrl":"..."}]',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
    );
  }

  void _loadSampleConfigs() {
    const sample = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'default',
        'name': 'Default',
        'apiUrl': 'https://example.com/api',
        'description': 'Primary source config',
      },
    ];
    _apiConfigsJsonCtr.text = const JsonEncoder.withIndent(
      '  ',
    ).convert(sample);
  }

  void _formatJson() {
    final source = _apiConfigsJsonCtr.text.trim();
    if (source.isEmpty) {
      _apiConfigsJsonCtr.text = '[]';
      return;
    }
    try {
      final parsed = jsonDecode(source);
      _apiConfigsJsonCtr.text = const JsonEncoder.withIndent(
        '  ',
      ).convert(parsed);
    } catch (error) {
      SmartDialog.showToast('Invalid JSON: $error');
    }
  }

  Future<void> _fetchFromUrl() async {
    final url = _sourceConfigUrlCtr.text.trim();
    if (url.isEmpty) {
      SmartDialog.showToast('Source Config URL is empty');
      return;
    }
    setState(() => _isFetching = true);
    final result = await _sourceConfigService.fetchT4Configs(url);
    if (!mounted) return;
    setState(() => _isFetching = false);
    if (!result.success) {
      SmartDialog.showToast('${result.message}: ${result.error}');
      return;
    }
    _apiConfigsJsonCtr.text = result.prettyConfigsJson;
    if (_currentApiConfigIdCtr.text.trim().isEmpty &&
        result.configs.isNotEmpty) {
      _currentApiConfigIdCtr.text = result.configs.first.id;
    }
    SmartDialog.showToast(result.message);
  }

  Future<void> _save() async {
    List<T4ApiConfig> apiConfigs;
    try {
      apiConfigs = T4ApiConfig.listFromDynamic(_apiConfigsJsonCtr.text.trim());
    } catch (error) {
      SmartDialog.showToast('t4ApiConfigs parse failed: $error');
      return;
    }

    final hasInvalidItem = apiConfigs.any(
      (item) => item.id.isEmpty || item.name.isEmpty || item.apiUrl.isEmpty,
    );
    if (hasInvalidItem) {
      SmartDialog.showToast('Each config must include id, name, apiUrl.');
      return;
    }

    await PeekPiliConfigStore.saveT4Config(
      sourceConfigUrl: _sourceConfigUrlCtr.text,
      isLocalConfig: _isLocalConfig,
      currentApiConfigId: _currentApiConfigIdCtr.text,
      apiConfigs: apiConfigs,
    );
    SmartDialog.showToast('Source config saved');
  }
}
