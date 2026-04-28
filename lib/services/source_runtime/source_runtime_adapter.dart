import 'dart:io' show Platform;

import 'package:PiliPlus/services/source_runtime/adapters/android_source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/adapters/desktop_source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/adapters/stub_source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';
import 'package:PiliPlus/utils/platform_utils.dart';

abstract class SourceRuntimeAdapter {
  bool get supportsNativeBridge;

  Future<SourceRuntimeResult> probe(SourceEngine engine);

  Future<SourceRuntimeResult> execute(SourceRuntimeRequest request);
}

abstract final class SourceRuntimeAdapterFactory {
  static SourceRuntimeAdapter create() {
    if (Platform.isAndroid) {
      return AndroidSourceRuntimeAdapter();
    }
    if (PlatformUtils.isDesktop) {
      return DesktopSourceRuntimeAdapter();
    }
    return const StubSourceRuntimeAdapter(
      reason: 'Native runtime bridge is not available on this platform yet.',
    );
  }
}
