// Autor: Davi de Assis Fabricio

class Achievement {
  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
  });

  final String id;
  final String code;
  final String name;

  /// A descrição já explica a condição de desbloqueio.
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;

  factory Achievement.fromMap(
    Map<String, dynamic> map, {
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      unlocked: unlockedAt != null,
      unlockedAt: unlockedAt,
    );
  }
}
