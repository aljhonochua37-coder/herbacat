import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onAddToCart;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onBookmarkToggle,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F442B21),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Image with Verified Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 84,
                        height: 84,
                        color: AppColors.surfaceContainer,
                        child: Image.network(
                          plant.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.spa, color: AppColors.secondary, size: 36),
                          ),
                        ),
                      ),
                    ),
                    if (plant.isDohApproved)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 10, color: AppColors.tertiary),
                              const SizedBox(width: 2),
                              Text(
                                'DOH',
                                style: AppTypography.labelSm(color: AppColors.tertiary).copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plant.name,
                              style: AppTypography.headlineSm(color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onBookmarkToggle != null)
                            InkWell(
                              onTap: onBookmarkToggle,
                              borderRadius: BorderRadius.circular(9999),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  plant.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  size: 20,
                                  color: plant.isSaved ? AppColors.primary : AppColors.outline,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plant.scientificName,
                        style: AppTypography.bodySm(color: AppColors.tertiary).copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Location & Category Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              plant.categoryLabel,
                              style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 11, color: AppColors.primary),
                                const SizedBox(width: 2),
                                Text(
                                  plant.municipality,
                                  style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Shopping Price & Add to Cart Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₱${plant.price.toStringAsFixed(0)}',
                                style: AppTypography.headlineSm(color: AppColors.primary).copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                plant.inStock ? '• In stock' : '• Sold out',
                                style: AppTypography.labelSm(
                                  color: plant.inStock ? AppColors.tertiary : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          if (onAddToCart != null && plant.inStock)
                            InkWell(
                              onTap: onAddToCart,
                              borderRadius: BorderRadius.circular(9999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_shopping_cart, size: 14, color: AppColors.onSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: AppTypography.labelSm(color: AppColors.onSecondary).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

