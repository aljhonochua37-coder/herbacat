class Plant {
  final String id;
  final String name;
  final List<String> localNames;
  final String scientificName;
  final String family;
  final String growthForm;
  final List<String> partsUsed;
  final String therapeuticCategory; // 'respiratory', 'kidney', 'skin', 'digestive'
  final String categoryLabel;
  final bool isDohApproved;
  final String specimenNumber;
  final String municipality;
  final String habitatZone; // 'coastal', 'montane', 'riverbank', 'backyard', 'limestone'
  final String habitatLabel;
  final String description;
  final String medicinalUses;
  final List<String> indications;
  final List<PreparationMethod> preparations;
  final String precautions;
  final String imageUrl;
  bool isSaved;

  // Inventory & Commerce extensions
  final bool inStock;
  final int stockQuantity;
  final double price;
  final String dosage;

  Plant({
    required this.id,
    required this.name,
    required this.localNames,
    required this.scientificName,
    required this.family,
    required this.growthForm,
    required this.partsUsed,
    required this.therapeuticCategory,
    required this.categoryLabel,
    required this.isDohApproved,
    required this.specimenNumber,
    required this.municipality,
    required this.habitatZone,
    required this.habitatLabel,
    required this.description,
    required this.medicinalUses,
    required this.indications,
    required this.preparations,
    required this.precautions,
    required this.imageUrl,
    this.isSaved = false,
    this.inStock = true,
    this.stockQuantity = 25,
    this.price = 120.0,
    this.dosage = '',
  });

  Plant copyWith({
    String? id,
    String? name,
    List<String>? localNames,
    String? scientificName,
    String? family,
    String? growthForm,
    List<String>? partsUsed,
    String? therapeuticCategory,
    String? categoryLabel,
    bool? isDohApproved,
    String? specimenNumber,
    String? municipality,
    String? habitatZone,
    String? habitatLabel,
    String? description,
    String? medicinalUses,
    List<String>? indications,
    List<PreparationMethod>? preparations,
    String? precautions,
    String? imageUrl,
    bool? isSaved,
    bool? inStock,
    int? stockQuantity,
    double? price,
    String? dosage,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      localNames: localNames ?? this.localNames,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      growthForm: growthForm ?? this.growthForm,
      partsUsed: partsUsed ?? this.partsUsed,
      therapeuticCategory: therapeuticCategory ?? this.therapeuticCategory,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      isDohApproved: isDohApproved ?? this.isDohApproved,
      specimenNumber: specimenNumber ?? this.specimenNumber,
      municipality: municipality ?? this.municipality,
      habitatZone: habitatZone ?? this.habitatZone,
      habitatLabel: habitatLabel ?? this.habitatLabel,
      description: description ?? this.description,
      medicinalUses: medicinalUses ?? this.medicinalUses,
      indications: indications ?? this.indications,
      preparations: preparations ?? this.preparations,
      precautions: precautions ?? this.precautions,
      imageUrl: imageUrl ?? this.imageUrl,
      isSaved: isSaved ?? this.isSaved,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      price: price ?? this.price,
      dosage: dosage ?? this.dosage,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'localNames': localNames,
      'scientificName': scientificName,
      'family': family,
      'growthForm': growthForm,
      'partsUsed': partsUsed,
      'therapeuticCategory': therapeuticCategory,
      'categoryLabel': categoryLabel,
      'isDohApproved': isDohApproved,
      'specimenNumber': specimenNumber,
      'municipality': municipality,
      'habitatZone': habitatZone,
      'habitatLabel': habitatLabel,
      'description': description,
      'medicinalUses': medicinalUses,
      'indications': indications,
      'preparations': preparations.map((p) => p.toMap()).toList(),
      'precautions': precautions,
      'imageUrl': imageUrl,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'price': price,
      'dosage': dosage.isNotEmpty ? dosage : (preparations.isNotEmpty ? preparations.first.dosage : ''),
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawPreps = map['preparations'] as List<dynamic>? ?? [];
    return Plant(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Herb',
      localNames: (map['localNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      scientificName: map['scientificName'] as String? ?? '',
      family: map['family'] as String? ?? '',
      growthForm: map['growthForm'] as String? ?? 'Herbaceous Plant',
      partsUsed: (map['partsUsed'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Leaves'],
      therapeuticCategory: map['therapeuticCategory'] as String? ?? 'general',
      categoryLabel: map['categoryLabel'] as String? ?? 'General Botanical',
      isDohApproved: map['isDohApproved'] as bool? ?? false,
      specimenNumber: map['specimenNumber'] as String? ?? '#000',
      municipality: map['municipality'] as String? ?? 'Virac',
      habitatZone: map['habitatZone'] as String? ?? 'coastal',
      habitatLabel: map['habitatLabel'] as String? ?? 'Lowland Plain',
      description: map['description'] as String? ?? '',
      medicinalUses: map['medicinalUses'] as String? ?? '',
      indications: (map['indications'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      preparations: rawPreps
          .whereType<Map<String, dynamic>>()
          .map((p) => PreparationMethod.fromMap(p))
          .toList(),
      precautions: map['precautions'] as String? ?? 'Consult health professional before usage.',
      imageUrl: map['imageUrl'] as String? ?? '',
      isSaved: map['isSaved'] as bool? ?? false,
      inStock: map['inStock'] as bool? ?? true,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 25,
      price: (map['price'] as num?)?.toDouble() ?? 120.0,
      dosage: map['dosage'] as String? ?? '',
    );
  }
}

class PreparationMethod {
  final String title;
  final String instruction;
  final String dosage;

  const PreparationMethod({
    required this.title,
    required this.instruction,
    required this.dosage,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'instruction': instruction,
      'dosage': dosage,
    };
  }

  factory PreparationMethod.fromMap(Map<String, dynamic> map) {
    return PreparationMethod(
      title: map['title'] as String? ?? 'Preparation Method',
      instruction: map['instruction'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
    );
  }
}
