import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import '../../models/biosphere_zone_model.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/plant_card.dart';
import '../details/plant_details_screen.dart';

class ExploreFloraScreen extends StatefulWidget {
  final AppState appState;

  const ExploreFloraScreen({super.key, required this.appState});

  @override
  State<ExploreFloraScreen> createState() => _ExploreFloraScreenState();
}

class _ExploreFloraScreenState extends State<ExploreFloraScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _habitats = const [
    {'id': 'all', 'label': 'All Habitats', 'icon': Icons.all_inclusive},
    {'id': 'coastal', 'label': 'Coastal Plains', 'icon': Icons.waves},
    {'id': 'montane', 'label': 'Montane Forest', 'icon': Icons.forest},
    {'id': 'riverbank', 'label': 'Riverbanks', 'icon': Icons.water},
    {'id': 'backyard', 'label': 'Backyard Halamanan', 'icon': Icons.yard},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getZoneIcon(String iconName) {
    switch (iconName) {
      case 'beach_access':
        return Icons.beach_access;
      case 'landscape':
        return Icons.landscape;
      case 'forest':
        return Icons.forest;
      case 'air':
        return Icons.air;
      default:
        return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final plants = widget.appState.filteredPlants;
        final zones = widget.appState.biosphereZones;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Greeting & Header
              Row(
                children: [
                  const Icon(Icons.nature_people, size: 18, color: AppColors.tertiary),
                  const SizedBox(width: 6),
                  Text(
                    'ISLAND ETHNOBOTANY ATLAS',
                    style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Explore Catanduanes',
                style: AppTypography.headlineLg(color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  children: const [
                    TextSpan(text: 'Discover indigenous '),
                    TextSpan(
                      text: 'halamang gamot',
                      style: TextStyle(
                        color: AppColors.tertiary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' mapped across Pacific coastline ridges, rainforest sanctuaries, and rural barangays.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F442B21),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => widget.appState.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search municipality, ecosystem, or ailment...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              widget.appState.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Habitat Filter Pills
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _habitats.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final hab = _habitats[index];
                    final isSelected = widget.appState.selectedHabitat == hab['id'];
                    return CategoryPill(
                      label: hab['label'] as String,
                      icon: hab['icon'] as IconData,
                      isSelected: isSelected,
                      onTap: () => widget.appState.setSelectedHabitat(hab['id'] as String),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Living Geo-Index Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F442B21),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.map, size: 16, color: AppColors.tertiary),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVING GEO-INDEX',
                                  style: AppTypography.labelSm(color: AppColors.tertiary).copyWith(
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Catanduanes Biosphere Zones',
                              style: AppTypography.headlineSm(color: AppColors.onSurface),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.tertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4 Active Zones',
                                style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Summary Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                          left: BorderSide(color: AppColors.tertiary, width: 4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pin_drop, color: AppColors.tertiary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '4 Biogeographic Habitat Sectors',
                                  style: AppTypography.labelMd(color: AppColors.onSurface),
                                ),
                                Text(
                                  'Across 11 Municipalities in Catanduanes Island',
                                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '66+ Taxa',
                              style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Zones Accordion / Cards List
                    ...zones.map((zone) => _buildZoneTile(zone)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Foraging Trails
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Foraging Trails',
                        style: AppTypography.headlineSm(color: AppColors.onSurface),
                      ),
                      Text(
                        'Documented roadside & wilderness sightings',
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...plants.map((p) => PlantCard(
                    plant: p,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlantDetailsScreen(
                            plant: p,
                            appState: widget.appState,
                          ),
                        ),
                      );
                    },
                    onBookmarkToggle: () => widget.appState.toggleSave(p.id),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneTile(BiosphereZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getZoneIcon(zone.iconName), size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    zone.sector.toUpperCase(),
                    style: AppTypography.labelSm(color: AppColors.primary).copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${zone.speciesCount} Species',
                  style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(zone.title, style: AppTypography.labelLg(color: AppColors.onSurface)),
          const SizedBox(height: 2),
          Text(zone.description, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0x1ADBDBD0)),
          const SizedBox(height: 8),
          Text('Key Botanical Taxa:', style: AppTypography.labelSm(color: AppColors.secondary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: zone.keyTaxa
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      t,
                      style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
