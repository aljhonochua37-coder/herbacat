import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../models/recipe_model.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';

class AdminManagementScreen extends StatefulWidget {
  final AppState appState;

  const AdminManagementScreen({super.key, required this.appState});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  // 0: Herbs & Stock, 1: Add/Edit Herb, 2: Recipes & Guides, 3: Orders Overview
  int _selectedTab = 0;
  Plant? _editingPlant;

  // Herb Form controllers
  final _nameCtrl = TextEditingController();
  final _scientificCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _municipalityCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _indicationsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _precautionsCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '120');
  final _stockQtyCtrl = TextEditingController(text: '25');
  final _imageUrlCtrl = TextEditingController();
  bool _inStockVal = true;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scientificCtrl.dispose();
    _familyCtrl.dispose();
    _municipalityCtrl.dispose();
    _categoryCtrl.dispose();
    _indicationsCtrl.dispose();
    _descriptionCtrl.dispose();
    _precautionsCtrl.dispose();
    _dosageCtrl.dispose();
    _priceCtrl.dispose();
    _stockQtyCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Plant plant) {
    setState(() {
      _editingPlant = plant;
      _nameCtrl.text = plant.name;
      _scientificCtrl.text = plant.scientificName;
      _familyCtrl.text = plant.family;
      _municipalityCtrl.text = plant.municipality;
      _categoryCtrl.text = plant.therapeuticCategory;
      _indicationsCtrl.text = plant.indications.join(', ');
      _descriptionCtrl.text = plant.description;
      _precautionsCtrl.text = plant.precautions;
      _dosageCtrl.text = plant.dosage.isNotEmpty
          ? plant.dosage
          : (plant.preparations.isNotEmpty ? plant.preparations.first.dosage : '');
      _priceCtrl.text = plant.price.toStringAsFixed(0);
      _stockQtyCtrl.text = plant.stockQuantity.toString();
      _imageUrlCtrl.text = plant.imageUrl;
      _inStockVal = plant.inStock;
      _selectedTab = 1;
    });
  }

  void _clearForm() {
    setState(() {
      _editingPlant = null;
      _nameCtrl.clear();
      _scientificCtrl.clear();
      _familyCtrl.clear();
      _municipalityCtrl.clear();
      _categoryCtrl.clear();
      _indicationsCtrl.clear();
      _descriptionCtrl.clear();
      _precautionsCtrl.clear();
      _dosageCtrl.clear();
      _priceCtrl.text = '120';
      _stockQtyCtrl.text = '25';
      _imageUrlCtrl.clear();
      _inStockVal = true;
    });
  }

  Future<void> _handleUploadSampleImage() async {
    setState(() => _isUploadingImage = true);
    try {
      // Create a 1x1 png sample byte array to test Firebase Storage upload
      final sampleBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );
      final downloadUrl = await widget.appState.uploadHerbImage(
        sampleBytes,
        '${_nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : "herb"}_specimen.png',
      );
      setState(() {
        _imageUrlCtrl.text = downloadUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded to Firebase Storage successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase Storage note: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _saveRecord() {
    if (!widget.appState.currentUser.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only administrators can modify records.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter plant name')),
      );
      return;
    }

    final indicationsList = _indicationsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final price = double.tryParse(_priceCtrl.text.trim()) ?? 120.0;
    final stockQty = int.tryParse(_stockQtyCtrl.text.trim()) ?? 25;

    if (_editingPlant != null) {
      // Update
      final updated = _editingPlant!.copyWith(
        name: _nameCtrl.text.trim(),
        scientificName: _scientificCtrl.text.trim().isEmpty
            ? _editingPlant!.scientificName
            : _scientificCtrl.text.trim(),
        family: _familyCtrl.text.trim().isEmpty
            ? _editingPlant!.family
            : _familyCtrl.text.trim(),
        municipality: _municipalityCtrl.text.trim().isEmpty
            ? _editingPlant!.municipality
            : _municipalityCtrl.text.trim(),
        indications: indicationsList.isEmpty ? _editingPlant!.indications : indicationsList,
        description: _descriptionCtrl.text.trim().isEmpty
            ? _editingPlant!.description
            : _descriptionCtrl.text.trim(),
        precautions: _precautionsCtrl.text.trim().isEmpty
            ? _editingPlant!.precautions
            : _precautionsCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        price: price,
        stockQuantity: stockQty,
        inStock: _inStockVal,
        imageUrl: _imageUrlCtrl.text.trim().isNotEmpty
            ? _imageUrlCtrl.text.trim()
            : _editingPlant!.imageUrl,
      );
      widget.appState.updatePlant(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Herb "${updated.name}" updated successfully'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      // Create new
      final newPlant = Plant(
        id: 'specimen-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        localNames: [_nameCtrl.text.trim()],
        scientificName: _scientificCtrl.text.trim().isEmpty
            ? '${_nameCtrl.text.trim()} sp.'
            : _scientificCtrl.text.trim(),
        family: _familyCtrl.text.trim().isEmpty ? 'Flora of Catanduanes' : _familyCtrl.text.trim(),
        growthForm: 'Herbal Shrub',
        partsUsed: ['Leaves', 'Flowers'],
        therapeuticCategory: _categoryCtrl.text.trim().isEmpty ? 'respiratory' : _categoryCtrl.text.trim().toLowerCase(),
        categoryLabel: _categoryCtrl.text.trim().isEmpty ? 'Respiratory Care' : _categoryCtrl.text.trim(),
        isDohApproved: false,
        specimenNumber: '#CAT-${(widget.appState.allPlants.length + 1).toString().padLeft(3, "0")}',
        municipality: _municipalityCtrl.text.trim().isEmpty ? 'Virac' : _municipalityCtrl.text.trim(),
        habitatZone: 'montane',
        habitatLabel: 'Montane & Foothill Ridges',
        description: _descriptionCtrl.text.trim().isEmpty
            ? 'Indigenous botanical specimen documented in the island province of Catanduanes.'
            : _descriptionCtrl.text.trim(),
        medicinalUses: 'Documented traditional remedy used in local barangay pharmacopeia.',
        indications: indicationsList.isEmpty ? ['Traditional field remedy'] : indicationsList,
        preparations: [
          PreparationMethod(
            title: 'Standard Decoction',
            instruction: 'Boil freshly gathered leaves in 2 glasses of water for 15 minutes. Cool and filter.',
            dosage: _dosageCtrl.text.trim().isNotEmpty ? _dosageCtrl.text.trim() : 'Drink 1/2 glass 3 times daily.',
          ),
        ],
        precautions: _precautionsCtrl.text.trim().isEmpty
            ? 'Consult licensed healthcare provider before clinical application.'
            : _precautionsCtrl.text.trim(),
        imageUrl: _imageUrlCtrl.text.trim().isNotEmpty
            ? _imageUrlCtrl.text.trim()
            : 'https://images.unsplash.com/photo-1546842931-886c185b4c8c',
        price: price,
        stockQuantity: stockQty,
        inStock: _inStockVal,
        dosage: _dosageCtrl.text.trim(),
      );

      widget.appState.addPlant(newPlant);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New Herb "${newPlant.name}" published to Firestore'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }

    _clearForm();
    setState(() => _selectedTab = 0);
  }

  void _showRecipeDialog({HerbRecipe? recipe}) {
    final titleCtrl = TextEditingController(text: recipe?.title ?? '');
    final instructionCtrl = TextEditingController(text: recipe?.instruction ?? '');
    final dosageCtrl = TextEditingController(text: recipe?.dosage ?? '');
    final prepTimeCtrl = TextEditingController(text: recipe?.preparationTime ?? '15 mins');
    String selectedHerbId = recipe?.herbId ?? (widget.appState.allPlants.isNotEmpty ? widget.appState.allPlants.first.id : '');
    String selectedCategory = recipe?.category ?? 'Decoction';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final herbs = widget.appState.allPlants;
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                recipe != null ? 'Edit Recipe Guide' : 'Add Recipe Guide',
                style: AppTypography.headlineSm(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedHerbId,
                      decoration: const InputDecoration(labelText: 'Linked Herb'),
                      items: herbs.map((h) {
                        return DropdownMenuItem(value: h.id, child: Text(h.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedHerbId = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Guide / Recipe Title'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Preparation Method'),
                      items: const [
                        DropdownMenuItem(value: 'Decoction', child: Text('Decoction (Laga)')),
                        DropdownMenuItem(value: 'Poultice', child: Text('Poultice (Tapal)')),
                        DropdownMenuItem(value: 'Infusion', child: Text('Infusion (Pampa-init)')),
                        DropdownMenuItem(value: 'Extract', child: Text('Sap / Juice Extract')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: prepTimeCtrl,
                      decoration: const InputDecoration(labelText: 'Preparation Time (e.g. 15 mins)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: instructionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Preparation Steps / Instructions'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dosageCtrl,
                      decoration: const InputDecoration(labelText: 'Dosage / Directions of Use'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final matchedHerb = herbs.firstWhere(
                      (h) => h.id == selectedHerbId,
                      orElse: () => herbs.first,
                    );
                    if (recipe != null) {
                      final updated = recipe.copyWith(
                        herbId: selectedHerbId,
                        herbName: matchedHerb.name,
                        title: titleCtrl.text.trim(),
                        category: selectedCategory,
                        preparationTime: prepTimeCtrl.text.trim(),
                        instruction: instructionCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim(),
                      );
                      widget.appState.updateRecipe(updated);
                    } else {
                      final newRecipe = HerbRecipe(
                        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                        herbId: selectedHerbId,
                        herbName: matchedHerb.name,
                        title: titleCtrl.text.trim(),
                        category: selectedCategory,
                        preparationTime: prepTimeCtrl.text.trim(),
                        instruction: instructionCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      widget.appState.addRecipe(newRecipe);
                    }
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recipe guide saved to Firestore!'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('Save Guide', style: AppTypography.labelMd(color: AppColors.onPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final user = widget.appState.currentUser;

        // Role-based protection: Community users are strictly blocked
        if (!user.isAdmin) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('Admin Portal', style: AppTypography.headlineSm(color: AppColors.secondary)),
            ),
            body: _buildAccessDeniedView(context),
          );
        }

        final plants = widget.appState.allPlants;
        final recipes = widget.appState.recipes;
        final orders = widget.appState.allOrders;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Curator Badge Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.tertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.shield_outlined, size: 16, color: AppColors.tertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Administrator: ${user.name} (${user.adminId.isEmpty ? "#1042" : user.adminId}) • Role: Admin',
                          style: AppTypography.labelSm(color: AppColors.onTertiaryFixedVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Title Banner
                Text(
                  'Catanduanes Ethnobotanical Dashboard',
                  style: AppTypography.headlineLg(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage herb specimens, real-time inventory, preparation guides, and dispatch incoming orders.',
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 18),

                // KPI Metrics Overview
                Row(
                  children: [
                    _kpiCard('Herbs', '${widget.appState.totalHerbsCount}', 'Catalog', AppColors.primary, Icons.local_florist),
                    const SizedBox(width: 8),
                    _kpiCard('Low Stock', '${widget.appState.lowStockCount}', 'Action needed', AppColors.error, Icons.warning_amber),
                    const SizedBox(width: 8),
                    _kpiCard('Orders', '${widget.appState.totalOrdersCount}', '${widget.appState.activeOrdersCount} active', AppColors.tertiary, Icons.shopping_bag),
                    const SizedBox(width: 8),
                    _kpiCard('Users', '3', 'Registered', AppColors.secondary, Icons.people),
                  ],
                ),
                const SizedBox(height: 18),

                // Segmented Tab Controls
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tabChip('Herbs (${plants.length})', Icons.inventory_2_outlined, _selectedTab == 0, () => setState(() => _selectedTab = 0)),
                      const SizedBox(width: 8),
                      _tabChip(_editingPlant != null ? 'Edit Herb' : 'Add Herb', Icons.add_circle_outline, _selectedTab == 1, () => setState(() => _selectedTab = 1)),
                      const SizedBox(width: 8),
                      _tabChip('Recipes (${recipes.length})', Icons.menu_book_outlined, _selectedTab == 2, () => setState(() => _selectedTab = 2)),
                      const SizedBox(width: 8),
                      _tabChip('Orders (${orders.length})', Icons.local_shipping_outlined, _selectedTab == 3, () => setState(() => _selectedTab = 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tab Content
                if (_selectedTab == 0) ...[
                  _buildHerbInventoryList(plants),
                ] else if (_selectedTab == 1) ...[
                  _buildHerbForm(),
                ] else if (_selectedTab == 2) ...[
                  _buildRecipesList(recipes),
                ] else if (_selectedTab == 3) ...[
                  _buildOrdersList(orders),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabChip(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.onSecondary : AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.labelMd(
                color: isSelected ? AppColors.onSecondary : AppColors.onSurface,
              ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.headlineSm(color: AppColors.onSurface)),
            Text(title, style: AppTypography.labelSm(color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
            Text(subtitle, style: AppTypography.bodySm(color: color).copyWith(fontSize: 10), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: HERB INVENTORY LIST
  // ==========================================

  Widget _buildHerbInventoryList(List<Plant> plants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Botanical & Stock Inventory', style: AppTypography.headlineSm()),
            TextButton.icon(
              onPressed: () {
                _clearForm();
                setState(() => _selectedTab = 1);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Herb'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plants.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final plant = plants[idx];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          plant.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 50,
                            height: 50,
                            color: AppColors.surfaceContainer,
                            child: const Icon(Icons.spa, color: AppColors.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant.name, style: AppTypography.labelLg()),
                            Text(
                              plant.scientificName,
                              style: AppTypography.bodySm().copyWith(fontStyle: FontStyle.italic),
                            ),
                            Text(
                              '₱${plant.price.toStringAsFixed(0)} • ${plant.municipality}',
                              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: AppColors.secondary),
                        onPressed: () => _startEdit(plant),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => _confirmDeletePlant(plant),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('In Stock:', style: AppTypography.bodySm()),
                          Switch(
                            value: plant.inStock,
                            activeTrackColor: AppColors.tertiary,
                            onChanged: (val) {
                              widget.appState.updateHerbStock(
                                herbId: plant.id,
                                inStock: val,
                                stockQuantity: plant.stockQuantity,
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Qty: ', style: AppTypography.bodySm()),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: plant.stockQuantity > 0
                                ? () {
                                    widget.appState.updateHerbStock(
                                      herbId: plant.id,
                                      inStock: plant.stockQuantity - 1 > 0,
                                      stockQuantity: plant.stockQuantity - 1,
                                    );
                                  }
                                : null,
                          ),
                          Text('${plant.stockQuantity}', style: AppTypography.labelMd().copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              widget.appState.updateHerbStock(
                                herbId: plant.id,
                                inStock: true,
                                stockQuantity: plant.stockQuantity + 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _confirmDeletePlant(Plant plant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${plant.name}?'),
        content: Text('Are you sure you want to remove ${plant.name} from the Firestore herb registry?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.appState.deletePlant(plant.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Herb ${plant.name} removed'), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: HERB FORM
  // ==========================================

  Widget _buildHerbForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editingPlant != null ? 'Edit Herb Record' : 'Create New Herb Entry',
                style: AppTypography.headlineSm(color: AppColors.secondary),
              ),
              if (_editingPlant != null)
                TextButton(
                  onPressed: _clearForm,
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 14),

          _formField('Plant Common Name', 'e.g. Lagundi, Sambong', _nameCtrl),
          _formField('Scientific Name', 'e.g. Vitex negundo L.', _scientificCtrl),
          _formField('Botanical Family', 'e.g. Lamiaceae', _familyCtrl),
          _formField('Municipality in Catanduanes', 'e.g. Virac, Baras', _municipalityCtrl),
          _formField('Therapeutic Indications (comma-separated)', 'e.g. Cough, Asthma, Fever', _indicationsCtrl),
          _formField('Standard Dosage Guidance', 'e.g. 1/2 glass 3x daily after meals', _dosageCtrl),
          _formField('Safety Warnings & Contraindications', 'Describe precautions and high-risk groups...', _precautionsCtrl, maxLines: 2),
          _formField('Botanical Description', 'Describe plant characteristics...', _descriptionCtrl, maxLines: 3),

          // Inventory & Pricing Row
          Row(
            children: [
              Expanded(
                child: _formField('Price (₱)', '120', _priceCtrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _formField('Stock Quantity', '25', _stockQtyCtrl),
              ),
            ],
          ),

          // In Stock Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Available in Stock', style: AppTypography.labelMd()),
            value: _inStockVal,
            activeTrackColor: AppColors.tertiary,
            onChanged: (val) => setState(() => _inStockVal = val),
          ),
          const SizedBox(height: 8),

          // Image Upload to Firebase Storage
          _formField('Image URL', 'Enter direct image URL or upload to Storage', _imageUrlCtrl),
          OutlinedButton.icon(
            onPressed: _isUploadingImage ? null : _handleUploadSampleImage,
            icon: _isUploadingImage
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text(_isUploadingImage ? 'Uploading to Firebase Storage...' : 'Upload Image to Storage'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _editingPlant != null ? 'Save Changes' : 'Publish to Firestore',
                style: AppTypography.labelLg(color: AppColors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: RECIPES & PREPARATION GUIDES
  // ==========================================

  Widget _buildRecipesList(List<HerbRecipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Herbal Preparation Guides', style: AppTypography.headlineSm()),
            ElevatedButton.icon(
              onPressed: () => _showRecipeDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Guide'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recipes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No recipes or preparation guides added yet.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final rec = recipes[idx];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rec.category} • ${rec.preparationTime}',
                            style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: AppColors.secondary),
                              onPressed: () => _showRecipeDialog(recipe: rec),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              onPressed: () => widget.appState.deleteRecipe(rec.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(rec.title, style: AppTypography.labelLg().copyWith(fontWeight: FontWeight.bold)),
                    Text('Linked Herb: ${rec.herbName}', style: AppTypography.bodySm(color: AppColors.tertiary)),
                    const SizedBox(height: 8),
                    Text(rec.instruction, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Dosage: ${rec.dosage}',
                              style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================
  // TAB 3: ORDERS & STATUS UPDATER
  // ==========================================

  Widget _buildOrdersList(List<HerbOrder> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Orders & Dispatch Queue', style: AppTypography.headlineSm()),
            Text('${orders.length} Total', style: AppTypography.labelSm(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No orders placed yet in Firestore.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, idx) {
              final order = orders[idx];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: AppTypography.labelMd().copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₱${order.totalAmount.toStringAsFixed(0)}',
                          style: AppTypography.headlineSm(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${order.userName} (${order.userEmail})',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      'Address: ${order.shippingAddress}, ${order.municipality}',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    ...order.items.map((it) => Text(
                          '• ${it.quantity}x ${it.herbName} (₱${it.subtotal.toStringAsFixed(0)})',
                          style: AppTypography.bodySm(),
                        )),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Update Status:', style: AppTypography.labelSm()),
                        DropdownButton<OrderStatus>(
                          value: order.status,
                          items: OrderStatus.values.map((st) {
                            return DropdownMenuItem(
                              value: st,
                              child: Text(st.displayName),
                            );
                          }).toList(),
                          onChanged: (newStatus) {
                            if (newStatus != null) {
                              widget.appState.updateOrderStatus(order.id, newStatus);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order #${order.id.substring(0, 8)} status set to ${newStatus.displayName}'),
                                  backgroundColor: AppColors.secondary,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAccessDeniedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_bad_rounded,
                color: AppColors.error,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Access Restricted',
              style: AppTypography.headlineLg(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Administrative privileges required. Community users and regular field explorers do not have access to the botanical management dashboard.',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Return to Field Directory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(String label, String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
