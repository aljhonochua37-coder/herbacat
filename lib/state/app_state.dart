import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../models/biosphere_zone_model.dart';
import '../models/order_model.dart';
import '../models/recipe_model.dart';
import '../services/auth_database.dart';
import '../services/firebase_service.dart';

enum UserRole {
  guest,
  communityMember,
  healthWorker,
  researcher,
  administrator,
}

class UserProfile {
  final String name;
  final String email;
  final String municipality;
  final UserRole role;
  final String adminId;
  final bool isEmailVerified;

  const UserProfile({
    required this.name,
    required this.email,
    required this.municipality,
    required this.role,
    this.adminId = '',
    this.isEmailVerified = true,
  });

  bool get isGuest => role == UserRole.guest;
  bool get isAdmin => role == UserRole.administrator;
  bool get isCommunityMember => role == UserRole.communityMember;
  bool get canAccessAdmin => role == UserRole.administrator;

  String get roleDisplayName {
    switch (role) {
      case UserRole.guest:
        return 'Guest Explorer';
      case UserRole.communityMember:
        return 'Community Member';
      case UserRole.healthWorker:
        return 'Barangay Health Worker';
      case UserRole.researcher:
        return 'Botanical Researcher';
      case UserRole.administrator:
        return 'System Administrator';
    }
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? municipality,
    UserRole? role,
    String? adminId,
    bool? isEmailVerified,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      municipality: municipality ?? this.municipality,
      role: role ?? this.role,
      adminId: adminId ?? this.adminId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

class AppState extends ChangeNotifier {
  final AuthDatabase authDatabase;
  final FirebaseService firebaseService;

  UserProfile _currentUser = const UserProfile(
    name: 'Maria Santos',
    email: 'maria.santos@catanduanes.gov.ph',
    municipality: 'Virac',
    role: UserRole.administrator,
    adminId: '#1042',
    isEmailVerified: true,
  );

  bool _isOfflineActive = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedHabitat = 'all';

  AppState({
    AuthDatabase? authDatabase,
    FirebaseService? firebaseService,
  })  : authDatabase = authDatabase ?? AuthDatabase(),
        firebaseService = firebaseService ?? FirebaseService() {
    final defaultAdmin = this.authDatabase.getUserByEmail('maria.santos@catanduanes.gov.ph');
    if (defaultAdmin != null) {
      _currentUser = UserProfile(
        name: defaultAdmin.name,
        email: defaultAdmin.email,
        municipality: defaultAdmin.municipality,
        role: defaultAdmin.role,
        adminId: defaultAdmin.adminId,
        isEmailVerified: defaultAdmin.isEmailVerified,
      );
    }
  }

  UserProfile get currentUser => _currentUser;
  bool get isOfflineActive => _isOfflineActive;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedHabitat => _selectedHabitat;

  void setOfflineMode(bool active) {
    _isOfflineActive = active;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedHabitat(String habitat) {
    _selectedHabitat = habitat;
    notifyListeners();
  }

  /// Authenticate against Firebase Auth with AuthDatabase fallback
  Future<AuthResult> login({required String email, required String password}) async {
    if (FirebaseService.isFirebaseInitialized) {
      final fbResult = await firebaseService.loginWithFirebase(
        email: email,
        password: password,
      );
      if (fbResult.success && fbResult.user != null) {
        final user = fbResult.user!;
        _currentUser = UserProfile(
          name: user.name,
          email: user.email,
          municipality: user.municipality,
          role: user.role,
          adminId: user.adminId,
          isEmailVerified: user.isEmailVerified,
        );
        notifyListeners();
        return fbResult;
      }
    }

    final result = authDatabase.authenticate(email: email, password: password);
    if (result.success && result.user != null) {
      final user = result.user!;
      _currentUser = UserProfile(
        name: user.name,
        email: user.email,
        municipality: user.municipality,
        role: user.role,
        adminId: user.adminId,
        isEmailVerified: user.isEmailVerified,
      );
      notifyListeners();
    }
    return result;
  }

  /// Continue browsing as guest
  void continueAsGuest() {
    _currentUser = const UserProfile(
      name: 'Guest Forager',
      email: '',
      municipality: 'Catanduanes Island Access',
      role: UserRole.guest,
      isEmailVerified: false,
    );
    notifyListeners();
  }

  /// Logout resets to guest session
  Future<void> logout() async {
    if (FirebaseService.isFirebaseInitialized) {
      await firebaseService.signOut();
    }
    continueAsGuest();
  }

  /// Register user in Firebase Authentication / Firestore
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String municipality,
    required UserRole role,
  }) async {
    // Community users can NEVER register as administrator
    final safeRole = role == UserRole.administrator ? UserRole.communityMember : role;

    if (FirebaseService.isFirebaseInitialized) {
      final fbResult = await firebaseService.registerWithFirebase(
        name: name,
        email: email,
        password: password,
        municipality: municipality,
        role: safeRole,
      );
      if (fbResult.success && fbResult.user != null) {
        final user = fbResult.user!;
        _currentUser = UserProfile(
          name: user.name,
          email: user.email,
          municipality: user.municipality,
          role: user.role,
          adminId: user.adminId,
          isEmailVerified: user.isEmailVerified,
        );
        notifyListeners();
        return fbResult;
      }
    }

    final result = await authDatabase.registerUser(
      name: name,
      email: email,
      password: password,
      municipality: municipality,
      role: safeRole,
    );

    if (result.success && result.user != null) {
      final user = result.user!;
      _currentUser = UserProfile(
        name: user.name,
        email: user.email,
        municipality: user.municipality,
        role: user.role,
        adminId: user.adminId,
        isEmailVerified: user.isEmailVerified,
      );
      notifyListeners();
    }
    return result;
  }

  /// Verify email token (handles both manual token code and link confirmation)
  VerificationResult verifyEmail(String token) {
    final res = authDatabase.verifyEmail(token);
    if (res.success) {
      final updatedUser = authDatabase.getUserByEmail(_currentUser.email);
      if (updatedUser != null && updatedUser.isEmailVerified) {
        _currentUser = _currentUser.copyWith(isEmailVerified: true);
      }
      notifyListeners();
    }
    return res;
  }

  /// Check live verification status in Firebase (e.g. after clicking email link)
  Future<bool> checkFirebaseVerificationStatus() async {
    if (FirebaseService.isFirebaseInitialized) {
      final isVerified = await firebaseService.reloadAndCheckVerification();
      if (isVerified && !_currentUser.isEmailVerified) {
        _currentUser = _currentUser.copyWith(isEmailVerified: true);
        notifyListeners();
      }
      return isVerified;
    }
    return _currentUser.isEmailVerified;
  }

  /// Resend verification email via Firebase or AuthDatabase
  Future<VerificationResult> resendVerificationEmail([String? email]) async {
    if (FirebaseService.isFirebaseInitialized) {
      return await firebaseService.sendFirebaseEmailVerification();
    }
    final targetEmail = email ?? _currentUser.email;
    return await authDatabase.resendVerificationEmail(targetEmail);
  }

  /// Request password reset link via Firebase or AuthDatabase
  Future<AuthResult> requestPasswordReset(String email) async {
    if (FirebaseService.isFirebaseInitialized) {
      final fbResult = await firebaseService.sendFirebasePasswordReset(email);
      if (fbResult.success) {
        return fbResult;
      }
    }
    return await authDatabase.requestPasswordReset(email);
  }

  /// Validate password reset token
  ResetTokenStatus validateResetToken(String token) {
    return authDatabase.validateResetToken(token);
  }

  /// Reset password with new password
  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (FirebaseService.isFirebaseInitialized) {
      final fbResult = await firebaseService.confirmPasswordReset(
        code: token,
        newPassword: newPassword,
      );
      if (fbResult.success) {
        return fbResult;
      }
    }
    return await authDatabase.resetPassword(token: token, newPassword: newPassword);
  }

  final List<Plant> _plants = [
    Plant(
      id: 'lagundi',
      name: 'Lagundi',
      localNames: ['Dangla', 'Kamalan'],
      scientificName: 'Vitex negundo L.',
      family: 'Lamiaceae',
      growthForm: 'Lowland Shrub',
      partsUsed: ['Leaves', 'Flowers'],
      therapeuticCategory: 'respiratory',
      categoryLabel: 'Cough & Respiratory',
      isDohApproved: true,
      specimenNumber: '#014',
      municipality: 'Virac',
      habitatZone: 'coastal',
      habitatLabel: 'Coastal & Lowland Plains',
      description:
          'A large branched shrub growing up to 2 to 5 meters in height with quadrangular stems and distinctive 5-foliolate palmately compound leaves, bearing small blue-violet flowers in terminal branched inflorescences. Leaves release a warm aromatic scent when gently crushed.',
      medicinalUses:
          'Relief of cough, acute colds, bronchial asthma, fever, and pharyngitis. Contains chrysoplenol D and potent anti-histaminic bioflavonoids formally endorsed by the Philippine Department of Health (DOH).',
      indications: ['Bronchodilator', 'Antipyretic (Fever)', 'Analgesic', 'Anti-asthmatic'],
      preparations: [
        const PreparationMethod(
          title: 'Decoction (Laga)',
          instruction:
              'Wash fresh leaves thoroughly. Boil 4 tablespoons of chopped leaves in 2 glasses of water for 15 minutes uncovered on medium heat. Cool and strain.',
          dosage: 'Drink 1/2 glass 3 times daily for adults; 1/4 glass for children (7-12 yrs).',
        ),
        const PreparationMethod(
          title: 'Warm Leaf Poultice (Tapal)',
          instruction:
              'Crush fresh leaves and heat slightly over embers or warm pan with a touch of coconut oil.',
          dosage: 'Apply directly over the chest and forehead for fever or localized muscle aches.',
        ),
      ],
      precautions:
          'Do not exceed recommended daily dosage. Avoid during first trimester of pregnancy unless guided by a licensed health professional.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAyy3jqI1_F4HnQUyJUfodi4hcQpX3HYGV4hwIGIh9Rg5YnukPWpNbzNMX1TBpQC6TjP6Xr2BMQRRBGu2vq1RwGglh6rvZzdPHHiij-yUw1BLDKHq2eGTpWWaAh5BGaUtwY3uPmtBM5YGTl19iLCJ8Hhd1tZX9pdPy6Gn_Dl7uk2ahnl0cN0hPmCQvSvHjGBfNkhsF2oreAYik_vr1Lb7A3X10TH0vJDFzlUCflHe2w',
      isSaved: true,
    ),
    Plant(
      id: 'sambong',
      name: 'Sambong',
      localNames: ['Subusob', 'Alibhon', 'Blumea Camphor'],
      scientificName: 'Blumea balsamifera (L.) DC.',
      family: 'Asteraceae',
      growthForm: 'Aromatic Subshrub',
      partsUsed: ['Leaves'],
      therapeuticCategory: 'kidney',
      categoryLabel: 'Kidney & Urinary',
      isDohApproved: true,
      specimenNumber: '#019',
      municipality: 'Baras',
      habitatZone: 'montane',
      habitatLabel: 'Rainforest Slopes & Foothills',
      description:
          'Coarse, tall aromatic shrub with densely hairy, serrated leaves and yellow flowering heads. Known locally across Catanduanes for its strong camphor fragrance and medicinal properties.',
      medicinalUses:
          'Clinically validated diuretic and anti-urolithiasis agent. Dissolves or facilitates the passage of calcium oxalate renal stones (kidney stones) and alleviates edema.',
      indications: ['Diuretic', 'Kidney Stones (Urolithiasis)', 'Edema Relief', 'Hypertension Support'],
      preparations: [
        const PreparationMethod(
          title: 'Diuretic Decoction (Laga)',
          instruction:
              'Boil 4 tablespoons of chopped clean leaves in 2 glasses of water for 15 minutes. Strain.',
          dosage: 'Drink 1 glass every 8 hours. Ensure abundant fluid intake throughout the day.',
        ),
      ],
      precautions:
          'Sambong is a supplementary herbal treatment and not a substitute for clinical dialysis in end-stage renal disease. Consult your nephrologist if symptoms persist.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDQapLcQmfGHWuh1mZ7MGqR_dm69kjRm4Bo8zBgEBV7fIbnEf_Ar8Gh8pnuTN6KfshRzlOWfDK_MagBjjnwRTC1oCiZMJx_SUVcWfBcQjRuY7Y7cd5I_xIJARPc5BCRRDc9jNyR97aRM-TtKur283F-vsuACkLbuLZBLdUCkJgZMPllen516nwZrwvzxKgcHWCF8x84-oYwDH04m23Yr7Soc1-YPzeI7PFccTVZKxeA',
      isSaved: true,
    ),
    Plant(
      id: 'akapulko',
      name: 'Akapulko',
      localNames: ['Katandá', 'Bayabas-bayabasan', 'Ringworm Bush'],
      scientificName: 'Senna alata (L.) Roxb.',
      family: 'Fabaceae',
      growthForm: 'Coarse Erect Shrub',
      partsUsed: ['Fresh Leaves'],
      therapeuticCategory: 'skin',
      categoryLabel: 'Skin & Antifungal',
      isDohApproved: true,
      specimenNumber: '#028',
      municipality: 'San Andres',
      habitatZone: 'coastal',
      habitatLabel: 'Coastal Plains',
      description:
          'Shrub with dense, oblong pinnate leaves and vibrant candle-like spikes of golden yellow flowers. Contains chrysophanic acid, a powerful natural antifungal agent.',
      medicinalUses:
          'Traditional and clinically proven remedy for dermatophyte infections: ringworm (buni), athlete’s foot (alipunga), tinea flava (an-an), and scabies.',
      indications: ['Antifungal', 'Ringworm (Buni)', 'Tinea Versicolor (An-an)', 'Eczema Soother'],
      preparations: [
        const PreparationMethod(
          title: 'Fresh Leaf Crush / Extract',
          instruction:
              'Wash fresh leaves, pound in clean mortar until juice expresses freely.',
          dosage: 'Apply expressed juice or paste directly to washed and dried affected area 2 times daily for 3 weeks.',
        ),
      ],
      precautions:
          'For external topical use only. Do not apply near eyes or on open weeping wounds. Discontinue if localized dermatitis develops.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDPhtaqd2GiNim6-c4up-wqJUYxEi1w5AWvJWB2FskRtRFxaVckUNvNu7RlC5a3HYlyK0uuqs9An2OKNy5yXxS7PG2f-yflNolEY4jApubhV320PoWbvDySBO2eIpi70LLyjuIWflJK4Quvg8cklFrYQeEmr13I6giZ4w44xv45b-Tl3tKhsxP7mVgAqITraDJEus4GACoHLSCXwLUD-FA4A3k8ttM--gNDtkcivUTU',
      isSaved: false,
    ),
    Plant(
      id: 'tsaang-gubat',
      name: 'Tsaang Gubat',
      localNames: ['Putputay', 'Alangitngit', 'Wild Tea'],
      scientificName: 'Carmona retusa (Vahl) Masam.',
      family: 'Boraginaceae',
      growthForm: 'Small Shrub',
      partsUsed: ['Leaves'],
      therapeuticCategory: 'digestive',
      categoryLabel: 'Digestive & Oral Care',
      isDohApproved: true,
      specimenNumber: '#033',
      municipality: 'Pandan',
      habitatZone: 'montane',
      habitatLabel: 'Northern Forest Sanctuary',
      description:
          'Erect shrub with small, dark green clustered leaves that are rough on top and glossy underneath, producing tiny white flowers and orange fleshy drupes.',
      medicinalUses:
          'Alleviates stomach cramps, intestinal colic, and mild gastroenteritis. Contains rosmarinic acid. Also used as an oral gargle to prevent dental caries and heal bleeding gums.',
      indications: ['Antispasmodic', 'Stomachache / Kabag', 'Oral Antiseptic', 'Anti-diarrheal'],
      preparations: [
        const PreparationMethod(
          title: 'Stomach Soothing Tea (Infusion)',
          instruction:
              'Boil 2 tablespoons of chopped dried or fresh leaves in 1 glass of water for 10 minutes.',
          dosage: 'Sip warm tea after meals or whenever abdominal cramping occurs.',
        ),
      ],
      precautions:
          'If acute diarrhea is accompanied by high fever or severe dehydration, seek urgent primary care at the nearest Rural Health Unit.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAXPJrj8xs6w3mAfcugJ_rbG8ww288aY8TMhM_PLNFoicSQN3K4FedKrdjduT12InN_iSG9SDTUaGW0tlKa2ctXUevP3f-BO1LsDWC1EZ6o9mrIMKdKzm2mt-2sM17qYhfPRMq-MpOIpG5NYQxwRz3_Xuukj8epfsdppYvfzYgkPAi7QsOcDY2FN9J5dlu80KvZ1-6q0FzfEOaCbwdLdfdQGu_hdRRlL4clL1vAxDVN',
      isSaved: false,
    ),
    Plant(
      id: 'bayabas',
      name: 'Bayabas',
      localNames: ['Guava', 'Tayabas'],
      scientificName: 'Psidium guajava L.',
      family: 'Myrtaceae',
      growthForm: 'Small Tree',
      partsUsed: ['Leaves', 'Bark'],
      therapeuticCategory: 'skin',
      categoryLabel: 'Antiseptic & Wound Care',
      isDohApproved: true,
      specimenNumber: '#041',
      municipality: 'Viga',
      habitatZone: 'coastal',
      habitatLabel: 'Windward Pacific Coastal Ridge',
      description:
          'Widely cultivated and naturalized small tree with smooth peeling copper-colored bark, opposite aromatic leaves, and fragrant white flowers.',
      medicinalUses:
          'High tannin content provides astringent, antimicrobial, and wound-cleansing benefits. Widely applied in rural circumcision healing, postpartum baths, and toothache relief.',
      indications: ['Antiseptic Wash', 'Astringent', 'Postpartum Hygiene', 'Gingivitis'],
      preparations: [
        const PreparationMethod(
          title: 'Antiseptic Leaf Decoction',
          instruction:
              'Boil a handful of clean mature leaves in 4 glasses of water for 15 minutes. Cool until comfortably warm.',
          dosage: 'Use as a topical cleansing rinse for wounds or gargle warm liquid for mouth sores.',
        ),
      ],
      precautions:
          'Do not ingest large concentrated decoctions without water dilution to prevent severe constipation.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAn1DWhILCE7aHOFmXmRcwkjgeiVNlmvLfKhIVAoTpoxQEgnSy6TkYcwP3I2VFBwjPzGM9jPmmB6wLiKlm_7RPjWC_75GcZ5ogAZN_iRoVfSTJFXEkn5EGlRn24xjyc8qUILKStRd_P67wKly9u6uNvAc3nKAF48JU-V3cCxhbMVlzckqdyPtIScbuALAPscB8YzhmEXAM7lzS_91zrolCVkJDxXgJU_BVGFHWvG09v',
      isSaved: false,
    ),
  ];

  final List<BiosphereZone> _zones = const [
    BiosphereZone(
      id: 'zone-1',
      title: 'Virac, Bato & San Andres',
      sector: 'Coastal & Lowland Plains',
      municipalities: 'Southern Catanduanes Corridor',
      description: 'Sandy littoral dunes, river delta alluvium, and lowland rural thickets.',
      speciesCount: 14,
      keyTaxa: ['Lagundi (Vitex negundo)', 'Akapulko (Senna alata)', 'Tanglad', 'Pandan Dagat'],
      iconName: 'beach_access',
    ),
    BiosphereZone(
      id: 'zone-2',
      title: 'Baras, Gigmoto & San Miguel',
      sector: 'Rainforest Slopes & Foothills',
      municipalities: 'Eastern Central Ridge',
      description: 'Mist-drenched montane ridges, high-humidity canopy, and wet mossy undergrowth.',
      speciesCount: 19,
      keyTaxa: ['Sambong (Blumea balsamifera)', 'Alagaw (Premna)', 'Gotu Kola', 'Dita Bark'],
      iconName: 'landscape',
    ),
    BiosphereZone(
      id: 'zone-3',
      title: 'Pandan & Caramoran',
      sector: 'Northern Forest Sanctuary',
      municipalities: 'Northern Watershed Protected Area',
      description: 'Primary dipterocarp rainforest, moist limestone ravines, and protected springs.',
      speciesCount: 22,
      keyTaxa: ['Tsaang Gubat (Carmona retusa)', 'Pakong Kalabaw', 'Banaba', 'Luyang Dilaw'],
      iconName: 'forest',
    ),
    BiosphereZone(
      id: 'zone-4',
      title: 'Viga & Bagamanoc',
      sector: 'Windward Pacific Coastal Ridge',
      municipalities: 'Northeast Pacific Bluff Zone',
      description: 'Salt-spray seaward limestone bluffs, coastal mangrove fringes, and exposed cliffs.',
      speciesCount: 11,
      keyTaxa: ['Bayabas (Psidium guajava)', 'Pandan Dagat', 'Bitaog (Calophyllum)', 'Talisi'],
      iconName: 'air',
    ),
  ];

  List<Plant> get allPlants => List.unmodifiable(_plants);
  List<BiosphereZone> get biosphereZones => List.unmodifiable(_zones);

  List<Plant> get savedPlants => _plants.where((p) => p.isSaved).toList();

  List<Plant> get filteredPlants {
    return _plants.where((p) {
      if (_selectedCategory != 'all' && p.therapeuticCategory != _selectedCategory) {
        return false;
      }
      if (_selectedHabitat != 'all' && p.habitatZone != _selectedHabitat) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchSci = p.scientificName.toLowerCase().contains(q);
        final matchUses = p.medicinalUses.toLowerCase().contains(q);
        final matchMun = p.municipality.toLowerCase().contains(q);
        final matchLoc = p.localNames.any((n) => n.toLowerCase().contains(q));
        if (!matchName && !matchSci && !matchUses && !matchMun && !matchLoc) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Toggle saving a specimen to user field journal.
  /// Enforces that only verified accounts can save to field journal.
  bool toggleSave(String plantId) {
    if (_currentUser.isGuest) {
      return false;
    }
    if (!_currentUser.isEmailVerified) {
      return false;
    }

    final idx = _plants.indexWhere((p) => p.id == plantId);
    if (idx != -1) {
      final newSaved = !_plants[idx].isSaved;
      _plants[idx] = _plants[idx].copyWith(isSaved: newSaved);
      notifyListeners();

      if (FirebaseService.isFirebaseInitialized) {
        final uid = _currentUser.adminId.isNotEmpty ? _currentUser.adminId : _currentUser.email;
        firebaseService.syncFavorite(
          userId: uid,
          herbId: plantId,
          isFavorite: newSaved,
        );
      }
    }
    return true;
  }

  /// Administrator restricted operation
  void addPlant(Plant plant) {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Community users cannot add botanical records.');
    }
    _plants.insert(0, plant);
    notifyListeners();

    if (FirebaseService.isFirebaseInitialized) {
      firebaseService.saveHerb(plant);
    }
  }

  /// Administrator restricted operation
  void updatePlant(Plant updated) {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Community users cannot modify botanical records.');
    }
    final idx = _plants.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _plants[idx] = updated;
      notifyListeners();

      if (FirebaseService.isFirebaseInitialized) {
        firebaseService.saveHerb(updated);
      }
    }
  }

  /// Administrator restricted operation
  void deletePlant(String plantId) {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Community users cannot delete botanical records.');
    }
    _plants.removeWhere((p) => p.id == plantId);
    notifyListeners();

    if (FirebaseService.isFirebaseInitialized) {
      firebaseService.deleteHerb(plantId);
    }
  }

  /// Administrator operation to update stock and inventory
  void updateHerbStock({
    required String herbId,
    required bool inStock,
    required int stockQuantity,
  }) {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Only administrators can update inventory.');
    }
    final idx = _plants.indexWhere((p) => p.id == herbId);
    if (idx != -1) {
      _plants[idx] = _plants[idx].copyWith(
        inStock: inStock,
        stockQuantity: stockQuantity,
      );
      notifyListeners();

      if (FirebaseService.isFirebaseInitialized) {
        firebaseService.updateHerbStock(
          herbId: herbId,
          inStock: inStock,
          stockQuantity: stockQuantity,
        );
      }
    }
  }

  /// Upload herb photo to Firebase Storage
  Future<String> uploadHerbImage(Uint8List bytes, String fileName) async {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Only administrators can upload herb images.');
    }
    return await firebaseService.uploadHerbImage(bytes: bytes, fileName: fileName);
  }

  // ==========================================
  // RECIPES / PREPARATION GUIDES
  // ==========================================

  final List<HerbRecipe> _recipes = [
    HerbRecipe(
      id: 'rec_lagundi_decoction',
      herbId: 'lagundi',
      herbName: 'Lagundi (Vitex negundo L.)',
      title: 'Decoction for Cough & Asthma Relief (Laga)',
      instruction:
          'Wash 4 tablespoons of clean chopped fresh Lagundi leaves. Bring to a boil in 2 glasses of water for 15 minutes in an uncovered earthen pot. Cool and strain through clean gauze.',
      dosage: 'Adults: 1/2 glass 3 times daily; Children (7-12 yrs): 1/4 glass 3 times daily.',
      category: 'Decoction',
      preparationTime: '15 mins',
      createdAt: DateTime.now(),
    ),
    HerbRecipe(
      id: 'rec_lagundi_poultice',
      herbId: 'lagundi',
      herbName: 'Lagundi (Vitex negundo L.)',
      title: 'Warm Leaf Poultice for Arthritic Pain (Tapal)',
      instruction:
          'Lightly heat fresh crushed leaves over medium charcoal or in an ungreased pan. Moisten with a few drops of virgin coconut oil.',
      dosage: 'Apply directly over affected joints or back while pleasantly warm; secure with cotton wrap.',
      category: 'Poultice',
      preparationTime: '10 mins',
      createdAt: DateTime.now(),
    ),
    HerbRecipe(
      id: 'rec_sambong_infusion',
      herbId: 'sambong',
      herbName: 'Sambong (Blumea balsamifera)',
      title: 'Renal & Diuretic Infusion (Pampaihi / Anti-urolithiasis)',
      instruction:
          'Chop fresh mature Sambong leaves. Boil 1 cup of chopped leaves in 2 glasses of water for 15 minutes. Strain and cool.',
      dosage: 'Divide into 3 equal doses taken after meals. Maintain adequate daily water hydration.',
      category: 'Infusion',
      preparationTime: '20 mins',
      createdAt: DateTime.now(),
    ),
    HerbRecipe(
      id: 'rec_akapulko_extract',
      herbId: 'akapulko',
      herbName: 'Akapulko (Senna alata)',
      title: 'Fresh Leaf Extract for Tinea Flava / Buni & Buni',
      instruction:
          'Pound 10-15 fresh clean Akapulko leaves with a mortar until fine and juicy. Do not dilute with excess water.',
      dosage: 'Apply expressed green sap directly onto affected skin patches twice daily after cleansing.',
      category: 'Poultice',
      preparationTime: '5 mins',
      createdAt: DateTime.now(),
    ),
    HerbRecipe(
      id: 'rec_tsaang_gubat_brew',
      herbId: 'tsaang-gubat',
      herbName: 'Tsaang Gubat (Carmona retusa)',
      title: 'Digestive Antispasmodic Tea (Pampakalma ng Tiyan)',
      instruction:
          'Boil 2 tablespoons of chopped leaves in 1 glass of water for 15 minutes. Cool slightly and sip slowly.',
      dosage: '1 glass every 4 hours for acute intestinal colicky stomach pain or diarrhea.',
      category: 'Decoction',
      preparationTime: '15 mins',
      createdAt: DateTime.now(),
    ),
  ];

  List<HerbRecipe> get recipes => List.unmodifiable(_recipes);

  List<HerbRecipe> getRecipesForHerb(String herbId) =>
      _recipes.where((r) => r.herbId == herbId).toList();

  Future<void> addRecipe(HerbRecipe recipe) async {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Only administrators can add recipes.');
    }
    _recipes.insert(0, recipe);
    notifyListeners();

    if (FirebaseService.isFirebaseInitialized) {
      await firebaseService.saveRecipe(recipe);
    }
  }

  Future<void> updateRecipe(HerbRecipe recipe) async {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Only administrators can modify recipes.');
    }
    final idx = _recipes.indexWhere((r) => r.id == recipe.id);
    if (idx != -1) {
      _recipes[idx] = recipe;
      notifyListeners();

      if (FirebaseService.isFirebaseInitialized) {
        await firebaseService.saveRecipe(recipe);
      }
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Only administrators can delete recipes.');
    }
    _recipes.removeWhere((r) => r.id == recipeId);
    notifyListeners();

    if (FirebaseService.isFirebaseInitialized) {
      await firebaseService.deleteRecipe(recipeId);
    }
  }

  // ==========================================
  // ORDERS & COMMERCE FLOW
  // ==========================================

  final List<HerbOrder> _orders = [
    HerbOrder(
      id: 'ord_demo_001',
      userId: 'maria.santos@catanduanes.gov.ph',
      userEmail: 'maria.santos@catanduanes.gov.ph',
      userName: 'Maria Santos',
      shippingAddress: 'Barangay Rawis, Virac Coastal Outpost',
      municipality: 'Virac',
      status: OrderStatus.shipped,
      items: [
        const OrderItem(
          herbId: 'lagundi',
          herbName: 'Lagundi Specimen & Dried Leaf Kit',
          quantity: 2,
          price: 120.0,
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAyy3jqI1_F4HnQUyJUfodi4hcQpX3HYGV4hwIGIh9Rg5YnukPWpNbzNMX1TBpQC6TjP6Xr2BMQRRBGu2vq1RwGglh6rvZzdPHHiij-yUw1BLDKHq2eGTpWWaAh5BGaUtwY3uPmtBM5YGTl19iLCJ8Hhd1tZX9pdPy6Gn_Dl7uk2ahnl0cN0hPmCQvSvHjGBfNkhsF2oreAYik_vr1Lb7A3X10TH0vJDFzlUCflHe2w',
        ),
      ],
      totalAmount: 240.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
  ];

  List<HerbOrder> get allOrders => List.unmodifiable(_orders);

  List<HerbOrder> get userOrders {
    final email = _currentUser.email.toLowerCase();
    final adminId = _currentUser.adminId;
    return _orders.where((o) =>
        o.userId.toLowerCase() == email ||
        o.userEmail.toLowerCase() == email ||
        (adminId.isNotEmpty && o.userId == adminId)).toList();
  }

  // ==========================================
  // SHOPPING CART STATE
  // ==========================================

  final Map<String, int> _cart = {};

  Map<String, int> get cart => Map.unmodifiable(_cart);

  int get cartItemCount => _cart.values.fold(0, (sum, q) => sum + q);

  double get cartTotalAmount {
    double total = 0.0;
    _cart.forEach((herbId, qty) {
      final p = _plants.firstWhere(
        (plant) => plant.id == herbId,
        orElse: () => _plants.first,
      );
      total += p.price * qty;
    });
    return total;
  }

  List<MapEntry<Plant, int>> get cartItems {
    final list = <MapEntry<Plant, int>>[];
    _cart.forEach((herbId, qty) {
      final p = _plants.firstWhere(
        (plant) => plant.id == herbId,
        orElse: () => _plants.first,
      );
      list.add(MapEntry(p, qty));
    });
    return list;
  }

  void addToCart(String herbId, [int quantity = 1]) {
    _cart[herbId] = (_cart[herbId] ?? 0) + quantity;
    notifyListeners();
  }

  void updateCartQuantity(String herbId, int quantity) {
    if (quantity <= 0) {
      _cart.remove(herbId);
    } else {
      _cart[herbId] = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(String herbId) {
    _cart.remove(herbId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<HerbOrder?> checkoutCart({
    required String shippingAddress,
    required String municipality,
  }) async {
    if (_cart.isEmpty) return null;

    final items = <OrderItem>[];
    for (final entry in _cart.entries) {
      final plant = _plants.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => _plants.first,
      );
      items.add(OrderItem(
        herbId: plant.id,
        herbName: plant.name,
        quantity: entry.value,
        price: plant.price,
        imageUrl: plant.imageUrl,
      ));

      // Decrement stock
      final idx = _plants.indexWhere((p) => p.id == plant.id);
      if (idx != -1) {
        final newQty = (_plants[idx].stockQuantity - entry.value).clamp(0, 9999);
        _plants[idx] = _plants[idx].copyWith(
          stockQuantity: newQty,
          inStock: newQty > 0,
        );
        if (FirebaseService.isFirebaseInitialized) {
          await firebaseService.updateHerbStock(
            herbId: plant.id,
            inStock: newQty > 0,
            stockQuantity: newQty,
          );
        }
      }
    }

    final order = HerbOrder(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser.adminId.isNotEmpty ? _currentUser.adminId : _currentUser.email,
      userEmail: _currentUser.email,
      userName: _currentUser.name,
      shippingAddress: shippingAddress,
      municipality: municipality.isNotEmpty ? municipality : _currentUser.municipality,
      status: OrderStatus.pending,
      items: items,
      totalAmount: cartTotalAmount,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, order);
    _cart.clear();

    if (FirebaseService.isFirebaseInitialized) {
      await firebaseService.createOrder(order);
    }

    notifyListeners();
    return order;
  }

  Future<HerbOrder> placeOrder({
    required Plant plant,
    required int quantity,
    required String shippingAddress,
    required String municipality,
  }) async {
    final order = HerbOrder(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser.adminId.isNotEmpty ? _currentUser.adminId : _currentUser.email,
      userEmail: _currentUser.email,
      userName: _currentUser.name,
      shippingAddress: shippingAddress,
      municipality: municipality.isNotEmpty ? municipality : _currentUser.municipality,
      status: OrderStatus.pending,
      items: [
        OrderItem(
          herbId: plant.id,
          herbName: plant.name,
          quantity: quantity,
          price: plant.price,
          imageUrl: plant.imageUrl,
        ),
      ],
      totalAmount: plant.price * quantity,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, order);

    // Decrement stock quantity
    final idx = _plants.indexWhere((p) => p.id == plant.id);
    if (idx != -1) {
      final newQty = (_plants[idx].stockQuantity - quantity).clamp(0, 9999);
      _plants[idx] = _plants[idx].copyWith(
        stockQuantity: newQty,
        inStock: newQty > 0,
      );
      if (FirebaseService.isFirebaseInitialized) {
        await firebaseService.updateHerbStock(
          herbId: plant.id,
          inStock: newQty > 0,
          stockQuantity: newQty,
        );
      }
    }

    if (FirebaseService.isFirebaseInitialized) {
      await firebaseService.createOrder(order);
    }

    notifyListeners();
    return order;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (!_currentUser.isAdmin) {
      throw StateError('Unauthorized: Only administrators can update order status.');
    }
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    if (FirebaseService.isFirebaseInitialized) {
      await firebaseService.updateOrderStatus(orderId: orderId, status: newStatus);
    }
  }

  // ==========================================
  // METRICS & OVERVIEW
  // ==========================================

  int get totalHerbsCount => _plants.length;
  int get lowStockCount =>
      _plants.where((p) => !p.inStock || p.stockQuantity <= 5).length;
  int get totalOrdersCount => _orders.length;
  int get activeOrdersCount => _orders
      .where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.shipped)
      .length;
}
