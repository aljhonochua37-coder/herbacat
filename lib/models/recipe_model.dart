class HerbRecipe {
  final String id;
  final String herbId;
  final String herbName;
  final String title;
  final String instruction;
  final String dosage;
  final String category; // 'Decoction', 'Poultice', 'Infusion', 'Compress', 'Syrup'
  final String preparationTime;
  final DateTime createdAt;

  const HerbRecipe({
    required this.id,
    required this.herbId,
    required this.herbName,
    required this.title,
    required this.instruction,
    required this.dosage,
    this.category = 'Decoction',
    this.preparationTime = '15-20 mins',
    required this.createdAt,
  });

  HerbRecipe copyWith({
    String? id,
    String? herbId,
    String? herbName,
    String? title,
    String? instruction,
    String? dosage,
    String? category,
    String? preparationTime,
    DateTime? createdAt,
  }) {
    return HerbRecipe(
      id: id ?? this.id,
      herbId: herbId ?? this.herbId,
      herbName: herbName ?? this.herbName,
      title: title ?? this.title,
      instruction: instruction ?? this.instruction,
      dosage: dosage ?? this.dosage,
      category: category ?? this.category,
      preparationTime: preparationTime ?? this.preparationTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'herbId': herbId,
      'herbName': herbName,
      'title': title,
      'instruction': instruction,
      'dosage': dosage,
      'category': category,
      'preparationTime': preparationTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HerbRecipe.fromMap(Map<String, dynamic> map, {String? docId}) {
    return HerbRecipe(
      id: docId ?? map['id'] as String? ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
      herbId: map['herbId'] as String? ?? '',
      herbName: map['herbName'] as String? ?? 'Herbal Plant',
      title: map['title'] as String? ?? 'Preparation Method',
      instruction: map['instruction'] as String? ?? '',
      dosage: map['dosage'] as String? ?? 'Take as directed',
      category: map['category'] as String? ?? 'Decoction',
      preparationTime: map['preparationTime'] as String? ?? '15 mins',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val is DateTime) return val;
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
