// Made by Dr Ali
// Domain models for auth — mirrors /v1 public user shape (no passwordHash).

class ObicAddress {
  const ObicAddress({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    this.line2,
    this.district,
    this.notes,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String? district;
  final String? notes;
  final bool isDefault;

  factory ObicAddress.fromJson(Map<String, dynamic> json) {
    return ObicAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      line1: json['line1'] as String,
      line2: json['line2'] as String?,
      city: json['city'] as String,
      district: json['district'] as String?,
      notes: json['notes'] as String?,
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'line1': line1,
        if (line2 != null && line2!.isNotEmpty) 'line2': line2,
        'city': city,
        if (district != null && district!.isNotEmpty) 'district': district,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'isDefault': isDefault,
      };

  String formatted({bool multiline = false}) {
    final parts = <String>[
      line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      if (district != null && district!.isNotEmpty) district!,
      city,
    ];
    return multiline ? parts.join('\n') : parts.join(', ');
  }

  ObicAddress copyWith({
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? district,
    String? notes,
    bool? isDefault,
  }) {
    return ObicAddress(
      id: id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      district: district ?? this.district,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class ObicUser {
  const ObicUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.avatarUrl,
    this.momentsCoverUrl,
    this.momentsCoverFocusY = 0,
    this.city,
    this.country,
    this.gender,
    this.whatsUp,
    this.obicId,
    this.obicIdChangedAt,
    this.obicIdNextChangeAt,
    this.opsAccess = false,
    this.offersAccess = false,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.needsEmailVerification = false,
    this.needsPhoneVerification = false,
    this.staffTitle,
    this.branchLabel,
    this.addresses = const [],
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? phone;
  final String name;
  final String role;
  final String? avatarUrl;

  /// WeChat Moments header cover image URL.
  final String? momentsCoverUrl;

  /// Vertical cover focus (−1 top … 1 bottom) for BoxFit.cover Alignment.y.
  final double momentsCoverFocusY;
  final String? city;
  final String? country;

  /// male | female | other | null
  final String? gender;

  /// WeChat “What's Up” / signature.
  final String? whatsUp;

  /// WeChat-style vanity ID friends use to add you (lowercase).
  final String? obicId;

  /// When OBIC ID was last set/changed.
  final DateTime? obicIdChangedAt;

  /// Earliest next change allowed (null = can change / never set cooldown).
  final DateTime? obicIdNextChangeAt;

  /// Server flag: Employee may open Internal Ops only when true.
  /// SuperAdmin always has Ops regardless of this value.
  final bool opsAccess;

  /// Server flag: Employee may manage hotel/flight offers only when true.
  /// SuperAdmin always may manage offers regardless of this value.
  final bool offersAccess;

  final bool emailVerified;
  final bool phoneVerified;

  /// China cohort without verified email — soft-block until email OTP.
  final bool needsEmailVerification;

  /// China cohort without verified mainland mobile — soft-block until OTP.
  final bool needsPhoneVerification;

  /// Desk title (Secretary, Marketing, …) — display + Yiwu status ACL.
  final String? staffTitle;

  /// Branch label for desk staff (e.g. Yiwu).
  final String? branchLabel;

  final List<ObicAddress> addresses;
  final DateTime? createdAt;

  bool get canChangeObicId {
    if (obicId == null || obicId!.isEmpty) return true;
    final next = obicIdNextChangeAt;
    if (next == null) return true;
    return !next.isAfter(DateTime.now().toUtc());
  }

  ObicAddress? get defaultAddress {
    for (final a in addresses) {
      if (a.isDefault) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  factory ObicUser.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['addresses'];
    final addresses = rawAddresses is List
        ? rawAddresses
            .whereType<Map>()
            .map((m) => ObicAddress.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <ObicAddress>[];
    return ObicUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      momentsCoverUrl: json['momentsCoverUrl'] as String?,
      momentsCoverFocusY: (json['momentsCoverFocusY'] as num?)?.toDouble() ?? 0,
      city: json['city'] as String?,
      country: json['country'] as String?,
      gender: json['gender'] as String?,
      whatsUp: json['whatsUp'] as String?,
      obicId: json['obicId'] as String?,
      obicIdChangedAt: json['obicIdChangedAt'] != null
          ? DateTime.tryParse(json['obicIdChangedAt'] as String)
          : null,
      obicIdNextChangeAt: json['obicIdNextChangeAt'] != null
          ? DateTime.tryParse(json['obicIdNextChangeAt'] as String)
          : null,
      opsAccess: json['opsAccess'] == true,
      offersAccess: json['offersAccess'] == true,
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
      needsEmailVerification: json['needsEmailVerification'] == true,
      needsPhoneVerification: json['needsPhoneVerification'] == true,
      staffTitle: json['staffTitle'] as String?,
      branchLabel: json['branchLabel'] as String?,
      addresses: addresses,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'name': name,
        'role': role,
        'avatarUrl': avatarUrl,
        'momentsCoverUrl': momentsCoverUrl,
        'momentsCoverFocusY': momentsCoverFocusY,
        'city': city,
        'country': country,
        'gender': gender,
        'whatsUp': whatsUp,
        'obicId': obicId,
        'obicIdChangedAt': obicIdChangedAt?.toIso8601String(),
        'obicIdNextChangeAt': obicIdNextChangeAt?.toIso8601String(),
        'opsAccess': opsAccess,
        'offersAccess': offersAccess,
        'emailVerified': emailVerified,
        'phoneVerified': phoneVerified,
        'needsEmailVerification': needsEmailVerification,
        'needsPhoneVerification': needsPhoneVerification,
        'staffTitle': staffTitle,
        'branchLabel': branchLabel,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
      };

  ObicUser copyWith({
    String? avatarUrl,
    String? momentsCoverUrl,
    double? momentsCoverFocusY,
    String? email,
    String? name,
    String? phone,
    String? city,
    String? country,
    String? gender,
    String? whatsUp,
    String? obicId,
    DateTime? obicIdChangedAt,
    DateTime? obicIdNextChangeAt,
    bool? opsAccess,
    bool? offersAccess,
    bool? emailVerified,
    bool? phoneVerified,
    bool? needsEmailVerification,
    bool? needsPhoneVerification,
    String? staffTitle,
    String? branchLabel,
    List<ObicAddress>? addresses,
  }) {
    return ObicUser(
      id: id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      momentsCoverUrl: momentsCoverUrl ?? this.momentsCoverUrl,
      momentsCoverFocusY: momentsCoverFocusY ?? this.momentsCoverFocusY,
      city: city ?? this.city,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      whatsUp: whatsUp ?? this.whatsUp,
      obicId: obicId ?? this.obicId,
      obicIdChangedAt: obicIdChangedAt ?? this.obicIdChangedAt,
      obicIdNextChangeAt: obicIdNextChangeAt ?? this.obicIdNextChangeAt,
      opsAccess: opsAccess ?? this.opsAccess,
      offersAccess: offersAccess ?? this.offersAccess,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      needsEmailVerification:
          needsEmailVerification ?? this.needsEmailVerification,
      needsPhoneVerification:
          needsPhoneVerification ?? this.needsPhoneVerification,
      staffTitle: staffTitle ?? this.staffTitle,
      branchLabel: branchLabel ?? this.branchLabel,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt,
    );
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as String? ?? '900s',
    );
  }
}
