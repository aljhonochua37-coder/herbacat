import 'package:flutter/material.dart';
import '../../models/plant_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import '../../widgets/caution_callout.dart';

class PlantDetailsScreen extends StatefulWidget {
  final Plant plant;
  final AppState appState;

  const PlantDetailsScreen({
    super.key,
    required this.plant,
    required this.appState,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.plant.isSaved;
  }

  void _toggleBookmark() {
    widget.appState.toggleSave(widget.plant.id);
    setState(() {
      _isSaved = !_isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Saved to your Field Journal' : 'Removed from Field Journal'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          plant.name,
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? AppColors.primary : AppColors.onSurface,
            ),
            onPressed: _toggleBookmark,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Botanical Photographic Plate
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    color: AppColors.surfaceContainer,
                    child: Image.network(
                      plant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.spa, size: 64, color: AppColors.secondary),
                      ),
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.onSurface.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                // Official Validation Badge
                if (plant.isDohApproved)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 16, color: AppColors.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            'DOH Approved Halamang Gamot',
                            style: AppTypography.labelSm(color: AppColors.tertiary).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Specimen Number & Archive Tag
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HERBAL SPECIMEN ${plant.specimenNumber}',
                            style: AppTypography.labelSm(color: AppColors.secondaryFixed).copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Catanduanes Ethnobotanical Archive',
                            style: AppTypography.bodySm(color: AppColors.surfaceContainerLow),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          plant.growthForm,
                          style: AppTypography.labelSm(color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Plant Identity Block
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    plant.name,
                    style: AppTypography.displayLg(color: AppColors.secondary),
                  ),
                ),
                if (plant.localNames.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      plant.localNames.join(' • '),
                      style: AppTypography.labelSm(color: AppColors.onSecondaryFixedVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plant.scientificName,
              style: AppTypography.headlineSm(color: AppColors.tertiary).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            // Quick Taxonomy & Inventory Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(
                  plant.inStock ? Icons.check_circle : Icons.do_not_disturb_on,
                  plant.inStock ? 'In Stock (${plant.stockQuantity})' : 'Out of Stock',
                  plant.inStock ? AppColors.tertiary : AppColors.error,
                ),
                _buildTag(Icons.local_offer, '₱${plant.price.toStringAsFixed(0)} / kit', AppColors.primary),
                _buildTag(Icons.eco, 'Family: ${plant.family}', AppColors.primary),
                _buildTag(Icons.terrain, plant.habitatLabel, AppColors.tertiary),
                _buildTag(Icons.spa, 'Parts: ${plant.partsUsed.join(", ")}', AppColors.secondary),
              ],
            ),
            const SizedBox(height: 20),

            // Botanical Description Card
            _buildSectionCard(
              title: 'Botanical Description',
              icon: Icons.nature_people,
              child: Text(
                plant.description,
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),

            // Traditional Medicinal Uses Card
            _buildSectionCard(
              title: 'Medicinal Uses',
              icon: Icons.medical_services,
              badge: 'Clinically Validated',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.medicinalUses,
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'KEY INDICATIONS',
                    style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plant.indications
                        .map(
                          (ind) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  ind,
                                  style: AppTypography.labelSm(color: AppColors.onSurface),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preparation Steps Section
            _buildSectionCard(
              title: 'Preparation & Dosage Guidelines',
              icon: Icons.soup_kitchen,
              child: Column(
                children: plant.preparations.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final prep = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$idx',
                                  style: AppTypography.labelSm(color: AppColors.onPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              prep.title,
                              style: AppTypography.labelLg(color: AppColors.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prep.instruction,
                          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Dosage: ${prep.dosage}',
                            style: AppTypography.bodySm(color: AppColors.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Caution Callout
            CautionCallout(message: plant.precautions),
            const SizedBox(height: 20),

            // Habitat Location in Catanduanes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.map, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catanduanes Habitat Location',
                          style: AppTypography.labelMd(color: AppColors.onSurface),
                        ),
                        Text(
                          '${plant.municipality} Municipality • ${plant.habitatLabel}',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Order / Specimen Kit Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondaryContainer),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Herbal Remedy & Tea Kit',
                          style: AppTypography.labelLg(color: AppColors.onSurface),
                        ),
                        Text(
                          '₱${plant.price.toStringAsFixed(0)} • ${plant.inStock ? "Available for Dispatch" : "Temporarily Out of Stock"}',
                          style: AppTypography.bodySm(
                            color: plant.inStock ? AppColors.tertiary : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: plant.inStock
                            ? () {
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
                              }
                            : null,
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Add to Cart'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: plant.inStock ? () => _showOrderSheet(context) : null,
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text('Buy Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showOrderSheet(BuildContext context) {
    int quantity = 1;
    final addressCtrl = TextEditingController(text: 'Barangay Center');
    final municipalityCtrl = TextEditingController(
      text: widget.appState.currentUser.municipality.isNotEmpty
          ? widget.appState.currentUser.municipality
          : 'Virac',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final subtotal = widget.plant.price * quantity;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Herbal Remedy Kit', style: AppTypography.headlineSm()),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.plant.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.spa, color: AppColors.secondary),
                      ),
                    ),
                    title: Text(widget.plant.name, style: AppTypography.labelLg()),
                    subtitle: Text('₱${widget.plant.price.toStringAsFixed(0)} each'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: quantity > 1
                              ? () => setModalState(() => quantity--)
                              : null,
                        ),
                        Text('$quantity', style: AppTypography.labelLg()),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: quantity < widget.plant.stockQuantity
                              ? () => setModalState(() => quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: municipalityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Catanduanes Municipality',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Barangay & Delivery Address',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount:', style: AppTypography.bodyMd()),
                      Text(
                        '₱${subtotal.toStringAsFixed(0)}',
                        style: AppTypography.headlineSm(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final order = await widget.appState.placeOrder(
                          plant: widget.plant,
                          quantity: quantity,
                          shippingAddress: addressCtrl.text.trim(),
                          municipality: municipalityCtrl.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order #${order.id.substring(0, 8)} placed successfully! Status: Pending Dispatch.'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Confirm Order', style: AppTypography.labelLg(color: AppColors.onPrimary)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTag(IconData icon, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A442B21),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(title, style: AppTypography.headlineSm(color: AppColors.onSurface)),
                ],
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    badge,
                    style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
