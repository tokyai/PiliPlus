import 'package:PiliPlus/utils/peekpili_config_store.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class TmdbSettingPage extends StatefulWidget {
  const TmdbSettingPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<TmdbSettingPage> createState() => _TmdbSettingPageState();
}

class _TmdbSettingPageState extends State<TmdbSettingPage> {
  late final TextEditingController _accessTokenCtr;
  late final TextEditingController _imageProxyCtr;
  late bool _integrationEnabled;

  @override
  void initState() {
    super.initState();
    _accessTokenCtr = TextEditingController(
      text: PeekPiliConfigStore.tmdbAccessToken,
    );
    _imageProxyCtr = TextEditingController(
      text: PeekPiliConfigStore.tmdbImageProxy,
    );
    _integrationEnabled = PeekPiliConfigStore.tmdbIntegrationEnabled;
  }

  @override
  void dispose() {
    _accessTokenCtr.dispose();
    _imageProxyCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('TMDB Config')) : null,
      body: ListView(
        padding: padding.copyWith(
          top: 20,
          left: 20 + (showAppBar ? padding.left : 0),
          right: 20 + (showAppBar ? padding.right : 0),
          bottom: padding.bottom + 100,
        ),
        children: [
          SwitchListTile(
            value: _integrationEnabled,
            onChanged: (value) => setState(() => _integrationEnabled = value),
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable TMDB integration'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accessTokenCtr,
            decoration: const InputDecoration(
              labelText: 'TMDB Access Token',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _imageProxyCtr,
            decoration: const InputDecoration(
              labelText: 'TMDB Image Proxy',
              hintText: 'https://image.tmdb.org/t/p/w500',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _clearSavedMatches,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear saved matches'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
    );
  }

  Future<void> _save() async {
    await PeekPiliConfigStore.saveTmdbConfig(
      accessToken: _accessTokenCtr.text,
      integrationEnabled: _integrationEnabled,
      imageProxy: _imageProxyCtr.text,
    );
    SmartDialog.showToast('TMDB config saved');
  }

  Future<void> _clearSavedMatches() async {
    await GStorage.setting.delete(SettingBoxKey.tmdbSavedMatches);
    SmartDialog.showToast('TMDB saved matches cleared');
  }
}
