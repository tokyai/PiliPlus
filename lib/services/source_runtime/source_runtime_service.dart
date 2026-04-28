import 'package:PiliPlus/services/source_runtime/source_engine.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_adapter.dart';
import 'package:PiliPlus/services/source_runtime/source_runtime_models.dart';
import 'package:get/get.dart';

class SourceRuntimeService extends GetxService {
  late final SourceRuntimeAdapter _adapter =
      SourceRuntimeAdapterFactory.create();

  bool get supportsNativeBridge => _adapter.supportsNativeBridge;

  Future<SourceRuntimeResult> probe(SourceEngine engine) {
    return _adapter.probe(engine);
  }

  Future<SourceRuntimeResult> execute({
    required SourceEngine engine,
    required String payload,
    Duration timeout = const Duration(seconds: 15),
    Map<String, dynamic> options = const <String, dynamic>{},
  }) {
    return _adapter.execute(
      SourceRuntimeRequest(
        engine: engine,
        payload: payload,
        timeout: timeout,
        options: options,
      ),
    );
  }
}
