import 'package:flutter_test/flutter_test.dart';
import 'package:herbacat/models/plant_model.dart';
import 'package:herbacat/services/auth_database.dart';
import 'package:herbacat/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppState createTestAppState() {
    return AppState(
      authDatabase: AuthDatabase(dbFilePath: ''), // pure in-memory test database
    );
  }

  group('Requirement 1: Community User Role & Access Restriction', () {
    test('Community User cannot register as Administrator (self-escalation blocked)', () async {
      final appState = createTestAppState();

      // Attempt registering with administrator role
      final regResult = await appState.register(
        name: 'Attacker User',
        email: 'attacker@catanduanes.org',
        password: 'Password123!',
        municipality: 'Virac',
        role: UserRole.administrator, // Attempt escalation
      );

      expect(regResult.success, isTrue);
      // System must downgrade or enforce communityMember
      expect(regResult.user?.role, equals(UserRole.communityMember));
      expect(regResult.user?.isAdmin, isFalse);
    });

    test('Community User is strictly non-admin and blocked from admin mutations', () async {
      final appState = createTestAppState();

      // Register community user
      final regResult = await appState.register(
        name: 'Juan Dela Cruz',
        email: 'juan.community@catanduanes.org',
        password: 'Password123!',
        municipality: 'San Andres',
        role: UserRole.communityMember,
      );
      expect(regResult.success, isTrue);

      // Login as community user
      final loginResult = await appState.login(
        email: 'juan.community@catanduanes.org',
        password: 'Password123!',
      );
      expect(loginResult.success, isTrue);
      expect(appState.currentUser.isAdmin, isFalse);
      expect(appState.currentUser.role, equals(UserRole.communityMember));

      // Attempting admin mutations as community user MUST throw StateError
      final dummyPlant = Plant(
        id: 'test_unauthorized_plant',
        name: 'Unauthorized Plant',
        localNames: ['Bawal'],
        scientificName: 'Planta nonlicita',
        family: 'Fabaceae',
        growthForm: 'Herb',
        partsUsed: ['Leaves'],
        therapeuticCategory: 'respiratory',
        categoryLabel: 'Respiratory',
        isDohApproved: false,
        specimenNumber: '#999',
        municipality: 'Virac',
        habitatZone: 'coastal',
        habitatLabel: 'Coastal',
        description: 'Should not be added',
        medicinalUses: 'None',
        indications: [],
        preparations: [],
        precautions: 'None',
        imageUrl: '',
      );

      expect(
        () => appState.addPlant(dummyPlant),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Unauthorized'),
        )),
      );

      expect(
        () => appState.deletePlant('lagundi'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Unauthorized'),
        )),
      );
    });

    test('Administrator account retains administrative access', () async {
      final appState = createTestAppState();

      // Login as default admin
      final adminLogin = await appState.login(
        email: 'maria.santos@catanduanes.gov.ph',
        password: 'AdminPassword123!',
      );
      expect(adminLogin.success, isTrue);
      expect(appState.currentUser.isAdmin, isTrue);
      expect(appState.currentUser.role, equals(UserRole.administrator));

      final initialCount = appState.allPlants.length;
      final adminPlant = Plant(
        id: 'test_admin_created_plant',
        name: 'Lagundi Test Variant',
        localNames: ['Dangla'],
        scientificName: 'Vitex negundo L.',
        family: 'Lamiaceae',
        growthForm: 'Lowland Shrub',
        partsUsed: ['Leaves'],
        therapeuticCategory: 'respiratory',
        categoryLabel: 'Respiratory',
        isDohApproved: true,
        specimenNumber: '#100',
        municipality: 'Virac',
        habitatZone: 'coastal',
        habitatLabel: 'Coastal',
        description: 'Official test herb entry',
        medicinalUses: 'Cough and asthma relief',
        indications: ['Cough'],
        preparations: [],
        precautions: 'None noted',
        imageUrl: 'https://images.unsplash.com/photo-1546842931-886c185b4c8c',
      );

      appState.addPlant(adminPlant);
      expect(appState.allPlants.length, equals(initialCount + 1));

      appState.deletePlant('test_admin_created_plant');
      expect(appState.allPlants.length, equals(initialCount));
    });
  });

  group('Requirement 2: Email Verification System', () {
    test('Unverified accounts cannot bookmark or save plants', () async {
      final appState = createTestAppState();

      await appState.register(
        name: 'Unverified Explorer',
        email: 'unverified@catanduanes.org',
        password: 'Password123!',
        municipality: 'Baras',
        role: UserRole.communityMember,
      );

      await appState.login(
        email: 'unverified@catanduanes.org',
        password: 'Password123!',
      );
      expect(appState.currentUser.isEmailVerified, isFalse);

      // Find an unsaved plant to test bookmark attempt
      final unsavedPlant = appState.allPlants.firstWhere((p) => !p.isSaved);
      final toggleResult = appState.toggleSave(unsavedPlant.id);
      expect(toggleResult, isFalse);
      expect(appState.savedPlants.any((p) => p.id == unsavedPlant.id), isFalse);
    });

    test('Verification flow: token verification enables full account access', () async {
      final appState = createTestAppState();

      final regResult = await appState.register(
        name: 'Maria Santos',
        email: 'maria.santos@catanduanes.org',
        password: 'Password123!',
        municipality: 'Bato',
        role: UserRole.communityMember,
      );

      expect(regResult.success, isTrue);
      final token = regResult.user?.verificationToken;
      expect(token, isNotNull);
      expect(token!.length, greaterThanOrEqualTo(6));

      // Attempt invalid token
      final invalidRes = appState.verifyEmail('000000_INVALID');
      expect(invalidRes.success, isFalse);
      expect(invalidRes.message.toLowerCase(), contains('invalid'));

      // Perform valid token verification
      final validRes = appState.verifyEmail(token);
      expect(validRes.success, isTrue);
      expect(validRes.message.toLowerCase(), contains('verified successfully'));
      expect(appState.currentUser.isEmailVerified, isTrue);

      // Verified user can now bookmark plants
      final unsavedPlant = appState.allPlants.firstWhere((p) => !p.isSaved);
      final toggleResult = appState.toggleSave(unsavedPlant.id);
      expect(toggleResult, isTrue);
      expect(appState.savedPlants.any((p) => p.id == unsavedPlant.id), isTrue);
    });

    test('Resend verification token generates new valid token', () async {
      final appState = createTestAppState();

      final reg = await appState.register(
        name: 'Pedro Cruz',
        email: 'pedro.cruz@catanduanes.org',
        password: 'Password123!',
        municipality: 'Gigmoto',
        role: UserRole.communityMember,
      );
      final initialToken = reg.user?.verificationToken;

      final resendRes = await appState.resendVerificationEmail('pedro.cruz@catanduanes.org');
      expect(resendRes.success, isTrue);

      final user = appState.authDatabase.getUserByEmail('pedro.cruz@catanduanes.org');
      expect(user?.verificationToken, isNotNull);
      // New token must be generated
      expect(user?.verificationToken, isNot(equals(initialToken)));

      // Verifying with new token succeeds
      final verifyRes = appState.verifyEmail(user!.verificationToken!);
      expect(verifyRes.success, isTrue);
    });
  });

  group('Requirement 3: Forgot Password & Password Reset Flow', () {
    test('Forgot password for unregistered email fails safely', () async {
      final appState = createTestAppState();

      final result = await appState.requestPasswordReset('nonexistent@catanduanes.org');
      expect(result.success, isFalse);
      expect(result.errorMessage?.toLowerCase(), contains('no account'));
    });

    test('Password reset request generates token and allows password update', () async {
      final appState = createTestAppState();

      const email = 'elena.reset@catanduanes.org';
      await appState.register(
        name: 'Elena Reset',
        email: email,
        password: 'InitialPassword123!',
        municipality: 'Pandan',
        role: UserRole.communityMember,
      );

      // Request reset
      final reqResult = await appState.requestPasswordReset(email);
      expect(reqResult.success, isTrue);

      // Get generated reset token
      final resetToken = appState.authDatabase.getUserByEmail(email)?.resetToken;
      expect(resetToken, isNotNull);

      // Attempt invalid token
      final failReset = await appState.resetPassword(
        token: 'WRONG_TOKEN',
        newPassword: 'BrandNewPassword2026!',
      );
      expect(failReset.success, isFalse);
      expect(failReset.errorMessage?.toLowerCase(), contains('invalid'));

      // Reset with valid token
      final successReset = await appState.resetPassword(
        token: resetToken!,
        newPassword: 'BrandNewPassword2026!',
      );
      expect(successReset.success, isTrue);

      // Verify old password fails
      final oldLogin = await appState.login(
        email: email,
        password: 'InitialPassword123!',
      );
      expect(oldLogin.success, isFalse);

      // Verify new password succeeds
      final newLogin = await appState.login(
        email: email,
        password: 'BrandNewPassword2026!',
      );
      expect(newLogin.success, isTrue);

      // Verify single-use token: second attempt with same token fails
      final replayReset = await appState.resetPassword(
        token: resetToken,
        newPassword: 'AnotherPassword2026!',
      );
      expect(replayReset.success, isFalse);
      expect(replayReset.errorMessage?.toLowerCase(), contains('invalid'));
    });
  });

  group('Requirement 4 & 5: Botanical Data & Search Preservation', () {
    test('Botanical archive contains standard Catanduanes specimen catalog', () async {
      final appState = createTestAppState();

      expect(appState.allPlants.length, greaterThanOrEqualTo(5));
      final sambong = appState.allPlants.firstWhere((p) => p.name.contains('Sambong'));
      expect(sambong.scientificName, equals('Blumea balsamifera (L.) DC.'));
      expect(sambong.isDohApproved, isTrue);
      expect(sambong.indications, isNotEmpty);
      expect(sambong.preparations, isNotEmpty);
    });

    test('Search and category filtering work correctly', () async {
      final appState = createTestAppState();

      appState.setSearchQuery('cough');
      expect(appState.filteredPlants, isNotEmpty);
      for (final plant in appState.filteredPlants) {
        final matches = plant.name.toLowerCase().contains('cough') ||
            plant.scientificName.toLowerCase().contains('cough') ||
            plant.medicinalUses.toLowerCase().contains('cough') ||
            plant.municipality.toLowerCase().contains('cough') ||
            plant.localNames.any((n) => n.toLowerCase().contains('cough'));
        expect(matches, isTrue);
      }

      appState.setSearchQuery('');
      appState.setSelectedCategory('respiratory');
      for (final plant in appState.filteredPlants) {
        expect(plant.therapeuticCategory, equals('respiratory'));
      }
    });
  });
}
