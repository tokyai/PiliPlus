import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/services/source_runtime/go_proxy_service.dart';
import 'package:PiliPlus/services/source_runtime/jar_loader_service.dart';
import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_service.dart';
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
      options: <String, dynamic>{'route': widget.routeName},
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
  late final TextEditingController _methodCtr;
  late final TextEditingController _argsCtr;

  JarProbeResult? _probeResult;
  JarInvokeResult? _invokeResult;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _jarLoaderService = Get.find<JarLoaderService>();
    _jarPathCtr = TextEditingController(text: Pref.jarTestPath);
    _entryClassCtr = TextEditingController(text: Pref.jarTestEntryClass);
    _methodCtr = TextEditingController(text: Pref.jarTestMethod);
    _argsCtr = TextEditingController(text: Pref.jarTestArgs);
  }

  @override
  void dispose() {
    _jarPathCtr.dispose();
    _entryClassCtr.dispose();
    _methodCtr.dispose();
    _argsCtr.dispose();
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
            controller: _argsCtr,
            decoration: const InputDecoration(
              labelText: 'Args (comma separated)',
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
      methodName: _methodCtr.text.trim(),
      args: _parseCsv(_argsCtr.text),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invokeResult = result;
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
