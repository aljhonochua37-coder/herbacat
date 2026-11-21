import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../auth/verify_email_screen.dart';
import '../details/plant_details_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppState appState;

  const ProfileScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        final savedPlants = appState.savedPlants;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A442B21),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            user.isGuest ? Icons.eco : Icons.person,
                            size: 32,
                            color: AppColors.secondary,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.explore, size: 12, color: AppColors.onPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: user.isGuest ? AppColors.primaryFixed : AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              user.roleDisplayName,
                              style: AppTypography.labelSm(
                                color: user.isGuest ? AppColors.onPrimaryFixedVariant : AppColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.name,
                            style: AppTypography.headlineSm(color: AppColors.onSurface),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: AppColors.tertiary),
                              const SizedBox(width: 2),
                              Text(
                                user.municipality.isEmpty ? 'Catanduanes Island' : user.municipality,
                                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Email Verification Status Banner for logged-in accounts
              if (!user.isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: user.isEmailVerified
                        ? AppColors.secondaryContainer.withValues(alpha: 0.5)
                        : AppColors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user.isEmailVerified ? AppColors.tertiary : AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: user.isEmailVerified ? AppColors.tertiaryFixed : AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          user.isEmailVerified ? Icons.verified : Icons.mark_email_unread_outlined,
                          color: user.isEmailVerified ? AppColors.onTertiaryFixedVariant : AppColors.onPrimaryFixedVariant,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isEmailVerified ? 'Verified Account' : 'Email Not Verified',
                              style: AppTypography.labelLg(
                                color: user.isEmailVerified ? AppColors.onSecondaryContainer : AppColors.onPrimaryContainer,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.isEmailVerified
                                  ? 'Full access to bookmarking and field observations.'
                                  : 'Verify your email to unlock bookmarking & journal features.',
                              style: AppTypography.bodySm(
                                color: user.isEmailVerified ? AppColors.onSecondaryContainer : AppColors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!user.isEmailVerified) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VerifyEmailScreen(
                                  appState: appState,
                                  initialEmail: user.email,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Verify',
                            style: AppTypography.labelSm(color: AppColors.onPrimary).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // If Guest: Show Callout Card to Join/Sign In
              if (user.isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26006A46),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.spa, color: AppColors.tertiaryFixed, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'FIELD JOURNAL PASS',
                            style: AppTypography.labelSm(color: AppColors.tertiaryFixed).copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Save Your Field Discoveries',
                        style: AppTypography.headlineSm(color: AppColors.onTertiary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a free HerbaCat account to bookmark traditional halamang gamot decoctions, sync offline trail guides, and submit local specimen sightings to barangay health workers.',
                        style: AppTypography.bodySm(color: AppColors.onTertiary.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SignUpScreen(appState: appState),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Create Free Account',
                            style: AppTypography.labelLg(color: AppColors.onPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(appState: appState),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.onTertiary, width: 1),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Log In to Existing Account',
                            style: AppTypography.labelMd(color: AppColors.onTertiary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Saved Specimen List / Bookmarks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Field Specimens',
                    style: AppTypography.headlineSm(color: AppColors.onSurface),
                  ),
                  Text(
                    '${savedPlants.length} Saved',
                    style: AppTypography.labelSm(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (savedPlants.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No saved plants yet. Tap the bookmark icon on any plant to save it to your notebook.',
                      style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: savedPlants.map((plant) {
                      return ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlantDetailsScreen(
                                plant: plant,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: AppColors.surfaceContainer,
                            child: Image.network(
                              plant.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa, color: AppColors.secondary),
                            ),
                          ),
                        ),
                        title: Text(plant.name, style: AppTypography.labelLg(color: AppColors.onSurface)),
                        subtitle: Text(
                          '${plant.scientificName} • ${plant.categoryLabel}',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),

              // Orders Section
              if (!user.isGuest) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Field Orders & Specimens',
                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                    ),
                    Text(
                      '${appState.userOrders.length} Orders',
                      style: AppTypography.labelSm(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (appState.userOrders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        'No orders placed yet. You can order herbal remedy kits directly from any plant detail page.',
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appState.userOrders.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, idx) {
                        final order = appState.userOrders[idx];
                        Color badgeColor;
                        IconData badgeIcon;
                        switch (order.status.name) {
                          case 'delivered':
                            badgeColor = AppColors.tertiary;
                            badgeIcon = Icons.check_circle_outline;
                            break;
                          case 'shipped':
                            badgeColor = const Color(0xFF0284C7);
                            badgeIcon = Icons.local_shipping_outlined;
                            break;
                          case 'cancelled':
                            badgeColor = AppColors.error;
                            badgeIcon = Icons.cancel_outlined;
                            break;
                          default:
                            badgeColor = AppColors.primary;
                            badgeIcon = Icons.schedule;
                        }

                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                                    style: AppTypography.labelMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(badgeIcon, size: 14, color: badgeColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.status.displayName,
                                          style: AppTypography.labelSm(color: badgeColor).copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...order.items.map((it) => Row(
                                    children: [
                                      const Icon(Icons.spa, size: 14, color: AppColors.secondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${it.quantity}x ${it.herbName}',
                                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                        ),
                                      ),
                                      Text(
                                        '₱${it.subtotal.toStringAsFixed(0)}',
                                        style: AppTypography.labelSm(color: AppColors.onSurface),
                                      ),
                                    ],
                                  )),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Destination: ${order.municipality}',
                                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(fontSize: 11),
                                  ),
                                  Text(
                                    'Total: ₱${order.totalAmount.toStringAsFixed(0)}',
                                    style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Settings Section
              Text(
                'Settings & System',
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: appState.isOfflineActive,
                      activeTrackColor: AppColors.tertiary,
                      title: Text('Offline Field Mode', style: AppTypography.labelLg()),
                      subtitle: Text(
                        'Cache plant identification records locally for remote island trails',
                        style: AppTypography.bodySm(),
                      ),
                      onChanged: (val) => appState.setOfflineMode(val),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined, color: AppColors.secondary),
                      title: Text('Pharmacopeia Standards', style: AppTypography.labelMd()),
                      subtitle: Text('Philippine Department of Health (DOH) & PITAHC 10 Medicinal Plants', style: AppTypography.bodySm()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Log Out / Switch Account Button
              if (!user.isGuest)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      appState.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(appState: appState),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorContainer,
                      foregroundColor: AppColors.onErrorContainer,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: AppTypography.labelLg(color: AppColors.onErrorContainer),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(appState: appState),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.secondary),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Log In with Field Account',
                      style: AppTypography.labelLg(color: AppColors.secondary),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
