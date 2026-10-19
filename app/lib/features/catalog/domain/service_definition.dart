class ServiceDefinition {
  const ServiceDefinition({
    required this.code,
    required this.name,
    required this.description,
    required this.baseLaborPaise,
    required this.durationMin,
    required this.active,
    required this.sortOrder,
  });

  final String code;
  final String name;
  final String description;
  final int baseLaborPaise;
  final int durationMin;
  final bool active;
  final int sortOrder;

  String get durationLabel => '$durationMin min';
}
