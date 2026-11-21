class BiosphereZone {
  final String id;
  final String title;
  final String sector;
  final String municipalities;
  final String description;
  final int speciesCount;
  final List<String> keyTaxa;
  final String iconName;

  const BiosphereZone({
    required this.id,
    required this.title,
    required this.sector,
    required this.municipalities,
    required this.description,
    required this.speciesCount,
    required this.keyTaxa,
    required this.iconName,
  });
}

