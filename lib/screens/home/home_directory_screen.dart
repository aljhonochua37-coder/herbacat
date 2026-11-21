import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/plant_card.dart';
import '../details/plant_details_screen.dart';

class HomeDirectoryScreen extends StatefulWidget {
  final AppState appState;

  const HomeDirectoryScreen({super.key, required this.appState});

  @override
  State<HomeDirectoryScreen> createState() => _HomeDirectoryScreenState();
}

class _HomeDirectoryScreenState extends State<HomeDirectoryScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': 'All Plants'},
    {'id': 'respiratory', 'label': 'Cough & Respiratory'},
    {'id': 'kidney', 'label': 'Kidney & Urinary'},
    {'id': 'skin', 'label': 'Skin & Antifungal'},
    {'id': 'digestive', 'label': 'Digestive'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.appState.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final plants = widget.appState.filteredPlants;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location & Online Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Virac, Catanduanes • Pacific Biosphere',
                          style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Field Online',
                          style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Welcome Headline
              Text(
                'Catanduanes Herbal Shop',
                style: AppTypography.headlineLg(color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Authentic halamang gamot, herbal teas, and traditional remedies from Catanduanes.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                          hintText: 'Search plants, uses, or symptoms...',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3394452C),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.onPrimary, size: 22),
                      onPressed: () => _showFilterSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // DOH Verified Highlight Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.secondaryFixed.withValues(alpha: 0.6)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A442B21),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.verified, color: AppColors.tertiary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PHILIPPINE PHARMACOPEIA',
                            style: AppTypography.labelSm(color: AppColors.tertiary).copyWith(
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '4 Verified DOH Native Medicinal Plants in Catanduanes',
                            style: AppTypography.headlineSm(color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Clinically validated by the Department of Health & PITAHC for traditional therapeutic applications.',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Horizontal Category Filters
              Text(
                'THERAPEUTIC ACTION',
                style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = widget.appState.selectedCategory == cat['id'];
                    return CategoryPill(
                      label: cat['label']!,
                      isSelected: isSelected,
                      onTap: () => widget.appState.setSelectedCategory(cat['id']!),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Plants List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Specimen Catalog',
                    style: AppTypography.headlineSm(color: AppColors.onSurface),
                  ),
                  Text(
                    '${plants.length} Found',
                    style: AppTypography.labelSm(color: AppColors.tertiary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Plants Cards
              if (plants.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: AppColors.outline),
                      const SizedBox(height: 8),
                      Text(
                        'No medicinal plants match your filter.',
                        style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.appState.setSearchQuery('');
                          widget.appState.setSelectedCategory('all');
                          widget.appState.setSelectedHabitat('all');
                          _searchController.clear();
                        },
                        child: const Text('Reset All Filters'),
                      ),
                    ],
                  ),
                )
              else
                ...plants.map((plant) {
                  return PlantCard(
                    plant: plant,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlantDetailsScreen(
                            plant: plant,
                            appState: widget.appState,
                          ),
                        ),
                      );
                    },
                    onBookmarkToggle: () => widget.appState.toggleSave(plant.id),
                    onAddToCart: () {
                      widget.appState.addToCart(plant.id);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${plant.name} to Cart (${widget.appState.cartItemCount} items)'),
                          backgroundColor: AppColors.secondary,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Botanical Records', style: AppTypography.headlineSm()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text('Category', style: AppTypography.labelLg()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final isSel = widget.appState.selectedCategory == c['id'];
                  return ChoiceChip(
                    label: Text(c['label']!),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.onPrimary : AppColors.onSurface,
                    ),
                    onSelected: (val) {
                      widget.appState.setSelectedCategory(val ? c['id']! : 'all');
                      Navigator.of(ctx).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
