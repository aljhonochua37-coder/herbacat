import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../state/app_state.dart';
import '../widgets/app_header.dart';
import 'home/home_directory_screen.dart';
import 'explore/explore_flora_screen.dart';
import 'admin/admin_management_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  final AppState appState;
  final int initialIndex;

  const MainShell({
    super.key,
    required this.appState,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final isAdmin = widget.appState.currentUser.isAdmin;

        // Build screens dynamically according to role
        final List<Widget> screens = [
          HomeDirectoryScreen(appState: widget.appState),
          ExploreFloraScreen(appState: widget.appState),
          if (isAdmin) AdminManagementScreen(appState: widget.appState),
          ProfileScreen(appState: widget.appState),
        ];

        // Build navigation items according to role
        final List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa),
            label: 'Remedies',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        // Safety clamp for index if role changes
        if (_currentIndex >= screens.length) {
          _currentIndex = screens.length - 1;
        }

        String currentTitle;
        if (isAdmin) {
          switch (_currentIndex) {
            case 0:
              currentTitle = 'HerbaCat Shop';
              break;
            case 1:
              currentTitle = 'Herbal Remedies';
              break;
            case 2:
              currentTitle = 'Admin Portal';
              break;
            case 3:
              currentTitle = 'My Account';
              break;
            default:
              currentTitle = 'HerbaCat Shop';
          }
        } else {
          switch (_currentIndex) {
            case 0:
              currentTitle = 'HerbaCat Shop';
              break;
            case 1:
              currentTitle = 'Herbal Remedies';
              break;
            case 2:
              currentTitle = 'My Account';
              break;
            default:
              currentTitle = 'HerbaCat Shop';
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppHeader(
            title: currentTitle,
            cartCount: widget.appState.cartItemCount,
            onCartTap: () => _showCartSheet(context),
            onProfileTap: () {
              setState(() {
                _currentIndex = screens.length - 1;
              });
            },
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10442B21),
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.surfaceContainerLowest,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                selectedFontSize: 12,
                unselectedFontSize: 11,
                elevation: 0,
                items: navItems,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCartSheet(BuildContext context) {
    final addressCtrl = TextEditingController(text: 'Barangay Poblacion');
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
        return ListenableBuilder(
          listenable: widget.appState,
          builder: (context, _) {
            final cartItems = widget.appState.cartItems;
            final total = widget.appState.cartTotalAmount;

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
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Herbal Cart (${widget.appState.cartItemCount})', style: AppTypography.headlineSm()),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (cartItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.remove_shopping_cart_outlined, size: 48, color: AppColors.outline),
                            const SizedBox(height: 12),
                            Text('Your herbal cart is empty', style: AppTypography.labelLg()),
                            const SizedBox(height: 4),
                            Text(
                              'Add pure halamang gamot remedies from our Catanduanes shop.',
                              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cartItems.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = cartItems[idx];
                          final plant = item.key;
                          final qty = item.value;
                          final itemSubtotal = plant.price * qty;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    plant.imageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(Icons.spa, color: AppColors.secondary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(plant.name, style: AppTypography.labelMd()),
                                      Text(
                                        '₱${plant.price.toStringAsFixed(0)} each',
                                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => widget.appState.updateCartQuantity(plant.id, qty - 1),
                                    ),
                                    Text('$qty', style: AppTypography.labelMd()),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () => widget.appState.updateCartQuantity(plant.id, qty + 1),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₱${itemSubtotal.toStringAsFixed(0)}',
                                  style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: municipalityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Municipality (Catanduanes)',
                        prefixIcon: Icon(Icons.location_city, size: 20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Barangay & Delivery Address',
                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Local Delivery:', style: AppTypography.bodyMd()),
                        Text('FREE (Catanduanes Local)', style: AppTypography.labelSm(color: AppColors.tertiary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:', style: AppTypography.headlineSm()),
                        Text(
                          '₱${total.toStringAsFixed(0)}',
                          style: AppTypography.headlineSm(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final order = await widget.appState.checkoutCart(
                            shippingAddress: addressCtrl.text.trim(),
                            municipality: municipalityCtrl.text.trim(),
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (context.mounted && order != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id} placed! Pending Dispatch.'),
                                backgroundColor: AppColors.secondary,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text('Checkout & Place Order', style: AppTypography.labelLg(color: AppColors.onPrimary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
