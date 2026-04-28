import 'dart:convert';

class T4ApiConfig {
  const T4ApiConfig({
    required this.id,
    required this.name,
    required this.apiUrl,
    this.description,
    this.extra = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String apiUrl;
  final String? description;
  final Map<String, dynamic> extra;

  T4ApiConfig copyWith({
    String? id,
    String? name,
    String? apiUrl,
    String? description,
    Map<String, dynamic>? extra,
  }) => T4ApiConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    apiUrl: apiUrl ?? this.apiUrl,
    description: description ?? this.description,
    extra: extra ?? this.extra,
  );

  factory T4ApiConfig.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['configId'] ?? '').toString().trim();
    final name = (json['name'] ?? json['title'] ?? '').toString().trim();
    final apiUrl = (json['apiUrl'] ?? json['url'] ?? '').toString().trim();
    final description = json['description']?.toString().trim();

    return T4ApiConfig(
      id: id,
      name: name,
      apiUrl: apiUrl,
      description: description?.isEmpty == true ? null : description,
      extra: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'id': id,
    'name': name,
    'apiUrl': apiUrl,
    if (description != null && description!.isNotEmpty)
      'description': description,
  };

  static List<T4ApiConfig> listFromDynamic(Object? raw) {
    if (raw == null) return const <T4ApiConfig>[];

    if (raw is String) {
      final source = raw.trim();
      if (source.isEmpty) return const <T4ApiConfig>[];
      return listFromDynamic(jsonDecode(source));
    }

    if (raw is! List) {
      throw const FormatException('Expected a JSON array for t4ApiConfigs.');
    }

    final result = <T4ApiConfig>[];
    for (var index = 0; index < raw.length; index++) {
      final item = raw[index];
      if (item is Map<String, dynamic>) {
        result.add(T4ApiConfig.fromJson(item));
      } else if (item is Map) {
        result.add(T4ApiConfig.fromJson(Map<String, dynamic>.from(item)));
      } else {
        throw FormatException(
          'Invalid t4ApiConfigs item at index $index: ${item.runtimeType}.',
        );
      }
    }
    return result;
  }

  static String encodeList(Iterable<T4ApiConfig> configs) =>
      jsonEncode(configs.map((item) => item.toJson()).toList());
}
