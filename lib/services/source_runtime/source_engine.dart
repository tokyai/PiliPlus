enum SourceEngine {
  python(
    key: 'python',
    title: 'Python',
    probeCommand: 'python',
    probeArgs: <String>['--version'],
  ),
  catJs(
    key: 'catjs',
    title: 'CatJs',
    probeCommand: 'node',
    probeArgs: <String>['--version'],
  ),
  nodeJs(
    key: 'nodejs',
    title: 'NodeJs',
    probeCommand: 'node',
    probeArgs: <String>['--version'],
  ),
  jar(
    key: 'jar',
    title: 'Jar',
    probeCommand: 'java',
    probeArgs: <String>['-version'],
  ),
  php(
    key: 'php',
    title: 'PHP',
    probeCommand: 'php',
    probeArgs: <String>['--version'],
  ),
  goProxy(
    key: 'goproxy',
    title: 'GoProxy',
    probeCommand: 'go',
    probeArgs: <String>['version'],
  ),
  ;

  const SourceEngine({
    required this.key,
    required this.title,
    required this.probeCommand,
    required this.probeArgs,
  });

  final String key;
  final String title;
  final String probeCommand;
  final List<String> probeArgs;

  static SourceEngine fromKey(String key) => SourceEngine.values.firstWhere(
    (item) => item.key == key,
    orElse: () => SourceEngine.python,
  );
}
