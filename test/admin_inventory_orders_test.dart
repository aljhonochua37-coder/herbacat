import 'package:flutter_test/flutter_test.dart';
import 'package:herbacat/models/order_model.dart';
import 'package:herbacat/models/recipe_model.dart';
import 'package:herbacat/services/auth_database.dart';
import 'package:herbacat/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppState createTestAppState() {
    return AppState(
      authDatabase: AuthDatabase(dbFilePath: ''),
    );
  }

  group('Admin Dashboard & Inventory Manager Tests', () {
    test('Non-admin users are strictly blocked from inventory updates and herb mutations', () async {
      final appState = createTestAppState();

      // Register and login as community member
      await appState.register(
        name: 'Normal User',
        email: 'user@catanduanes.org',
        password: 'Password123!',
        municipality: 'Virac',
        role: UserRole.communityMember,
      );
      await appState.login(
        email: 'user@catanduanes.org',
        password: 'Password123!',
      );

      expect(appState.currentUser.isAdmin, isFalse);

      // Attempting inventory updates must throw StateError
      expect(
        () => appState.updateHerbStock(herbId: 'lagundi', inStock: false, stockQuantity: 0),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Unauthorized'))),
      );

      // Attempting to delete an herb must throw StateError
      expect(
        () => appState.deletePlant('lagundi'),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Unauthorized'))),
      );
    });

    test('Administrator can update herb stock, price, and toggle inStock', () async {
      final appState = createTestAppState();

      // Login as admin
      await appState.login(
        email: 'maria.santos@catanduanes.gov.ph',
        password: 'AdminPassword123!',
      );
      expect(appState.currentUser.isAdmin, isTrue);

      // Update Lagundi stock
      appState.updateHerbStock(herbId: 'lagundi', inStock: false, stockQuantity: 3);

      final lagundi = appState.allPlants.firstWhere((p) => p.id == 'lagundi');
      expect(lagundi.inStock, isFalse);
      expect(lagundi.stockQuantity, equals(3));

      // Low stock metric calculation
      expect(appState.lowStockCount, greaterThanOrEqualTo(1));
    });
  });

  group('Recipe & Guide Manager Tests', () {
    test('Administrator can add, modify, and query herbal preparation guides', () async {
      final appState = createTestAppState();

      await appState.login(
        email: 'maria.santos@catanduanes.gov.ph',
        password: 'AdminPassword123!',
      );

      final initialRecipeCount = appState.recipes.length;

      final testRecipe = HerbRecipe(
        id: 'rec_test_sambong_tonic',
        herbId: 'sambong',
        herbName: 'Sambong',
        title: 'Traditional Sambong Kidney Cleanse',
        instruction: 'Boil fresh leaves for 15 minutes, cool and drink.',
        dosage: '1 glass twice daily',
        category: 'Decoction',
        preparationTime: '15 mins',
        createdAt: DateTime.now(),
      );

      await appState.addRecipe(testRecipe);
      expect(appState.recipes.length, equals(initialRecipeCount + 1));

      // Query by herb
      final sambongRecipes = appState.getRecipesForHerb('sambong');
      expect(sambongRecipes.any((r) => r.id == 'rec_test_sambong_tonic'), isTrue);

      // Delete recipe
      await appState.deleteRecipe('rec_test_sambong_tonic');
      expect(appState.recipes.length, equals(initialRecipeCount));
    });

    test('Community members cannot add or delete preparation recipes', () async {
      final appState = createTestAppState();

      await appState.register(
        name: 'Regular Forager',
        email: 'forager@catanduanes.org',
        password: 'Password123!',
        municipality: 'San Andres',
        role: UserRole.communityMember,
      );
      await appState.login(
        email: 'forager@catanduanes.org',
        password: 'Password123!',
      );

      final testRecipe = HerbRecipe(
        id: 'rec_unauthorized',
        herbId: 'lagundi',
        herbName: 'Lagundi',
        title: 'Unauthorized Recipe',
        instruction: 'Should be rejected',
        dosage: 'None',
        createdAt: DateTime.now(),
      );

      expect(
        () => appState.addRecipe(testRecipe),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Unauthorized'))),
      );
    });
  });

  group('Order & Checkout Flow Tests', () {
    test('Verified user can place order, decrementing stock and tracking status', () async {
      final appState = createTestAppState();

      // Register and verify user
      final reg = await appState.register(
        name: 'Elena Ramos',
        email: 'elena.ramos@catanduanes.org',
        password: 'Password123!',
        municipality: 'Pandan',
        role: UserRole.communityMember,
      );
      appState.verifyEmail(reg.user!.verificationToken!);
      await appState.login(
        email: 'elena.ramos@catanduanes.org',
        password: 'Password123!',
      );

      final targetHerb = appState.allPlants.firstWhere((p) => p.id == 'lagundi');
      final initialStock = targetHerb.stockQuantity;

      // Place order for 2 kits
      final order = await appState.placeOrder(
        plant: targetHerb,
        quantity: 2,
        shippingAddress: 'Barangay Pandan Poblacion',
        municipality: 'Pandan',
      );

      expect(order.status, equals(OrderStatus.pending));
      expect(order.items.first.quantity, equals(2));
      expect(order.totalAmount, equals(targetHerb.price * 2));

      // Stock must be decremented
      final updatedHerb = appState.allPlants.firstWhere((p) => p.id == 'lagundi');
      expect(updatedHerb.stockQuantity, equals(initialStock - 2));

      // User must see order in userOrders
      expect(appState.userOrders.any((o) => o.id == order.id), isTrue);

      // Now login as Admin to update order status: pending -> shipped -> delivered
      await appState.login(
        email: 'maria.santos@catanduanes.gov.ph',
        password: 'AdminPassword123!',
      );

      await appState.updateOrderStatus(order.id, OrderStatus.shipped);
      final shippedOrder = appState.allOrders.firstWhere((o) => o.id == order.id);
      expect(shippedOrder.status, equals(OrderStatus.shipped));

      await appState.updateOrderStatus(order.id, OrderStatus.delivered);
      final deliveredOrder = appState.allOrders.firstWhere((o) => o.id == order.id);
      expect(deliveredOrder.status, equals(OrderStatus.delivered));
    });

    test('Regular user cannot update order status', () async {
      final appState = createTestAppState();

      await appState.register(
        name: 'Regular Shopper',
        email: 'shopper@catanduanes.org',
        password: 'Password123!',
        municipality: 'Baras',
        role: UserRole.communityMember,
      );
      await appState.login(
        email: 'shopper@catanduanes.org',
        password: 'Password123!',
      );

      expect(
        () => appState.updateOrderStatus('ord_demo_001', OrderStatus.delivered),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Unauthorized'))),
      );
    });

    test('Adding remedies to cart updates items, total, and checkout places multi-item order', () async {
      final appState = createTestAppState();

      expect(appState.cartItemCount, equals(0));

      appState.addToCart('lagundi', 2);
      appState.addToCart('sambong', 1);

      expect(appState.cartItemCount, equals(3));
      final lagundi = appState.allPlants.firstWhere((p) => p.id == 'lagundi');
      final sambong = appState.allPlants.firstWhere((p) => p.id == 'sambong');
      final expectedTotal = (lagundi.price * 2) + (sambong.price * 1);
      expect(appState.cartTotalAmount, equals(expectedTotal));

      // Checkout cart
      final order = await appState.checkoutCart(
        shippingAddress: 'Barangay San Pedro',
        municipality: 'Bato',
      );

      expect(order, isNotNull);
      expect(order!.items.length, equals(2));
      expect(order.totalAmount, equals(expectedTotal));
      expect(appState.cartItemCount, equals(0)); // Cart cleared
      expect(appState.allOrders.any((o) => o.id == order.id), isTrue);
    });
  });
}
