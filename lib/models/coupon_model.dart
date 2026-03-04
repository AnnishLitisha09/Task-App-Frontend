class CouponDashboard {
  final bool success;
  final int score;
  final int count;
  final List<Coupon> coupons;

  CouponDashboard({
    required this.success,
    required this.score,
    required this.count,
    required this.coupons,
  });

  factory CouponDashboard.fromJson(Map<String, dynamic> json) {
    return CouponDashboard(
      success: json['success'] ?? json['status'] ?? false,
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      coupons: (json['coupons'] as List? ?? [])
          .map((i) => Coupon.fromJson(i))
          .toList(),
    );
  }
}

class Coupon {
  final int id;
  final String name;
  final String validity;
  final String status;
  final int totalCount;
  final int remainingCount;
  final int points;
  final String createdAt;
  final String updatedAt;

  Coupon({
    required this.id,
    required this.name,
    required this.validity,
    required this.status,
    required this.totalCount,
    required this.remainingCount,
    required this.points,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      validity: json['validity'] ?? '',
      status: json['status'] ?? '',
      totalCount: int.tryParse(json['total_count']?.toString() ?? '0') ?? 0,
      remainingCount:
          int.tryParse(json['remaining_count']?.toString() ?? '0') ?? 0,
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class RedeemedCouponDashboard {
  final bool success;
  final UserScores userScores;
  final int count;
  final List<RedeemedItem> items;

  RedeemedCouponDashboard({
    required this.success,
    required this.userScores,
    required this.count,
    required this.items,
  });

  factory RedeemedCouponDashboard.fromJson(Map<String, dynamic> json) {
    return RedeemedCouponDashboard(
      success: json['success'] ?? json['status'] ?? false,
      userScores: UserScores.fromJson(json['user_scores'] ?? {}),
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      items: (json['items'] as List? ?? [])
          .map((i) => RedeemedItem.fromJson(i))
          .toList(),
    );
  }
}

class UserScores {
  final int currentNetScore;
  final int cumulativeGrossTotal;
  final int totalPenalty;

  UserScores({
    required this.currentNetScore,
    required this.cumulativeGrossTotal,
    required this.totalPenalty,
  });

  factory UserScores.fromJson(Map<String, dynamic> json) {
    return UserScores(
      currentNetScore:
          int.tryParse(json['current_net_score']?.toString() ?? '0') ?? 0,
      cumulativeGrossTotal:
          int.tryParse(json['cumulative_gross_total']?.toString() ?? '0') ?? 0,
      totalPenalty: int.tryParse(json['total_penalty']?.toString() ?? '0') ?? 0,
    );
  }
}

class RedeemedItem {
  final int redemptionId;
  final String couponName;
  final int pointsDeducted;
  final Coupon couponDetails;

  RedeemedItem({
    required this.redemptionId,
    required this.couponName,
    required this.pointsDeducted,
    required this.couponDetails,
  });

  factory RedeemedItem.fromJson(Map<String, dynamic> json) {
    return RedeemedItem(
      redemptionId: int.tryParse(json['redemption_id']?.toString() ?? '0') ?? 0,
      couponName: json['coupon_name'] ?? '',
      pointsDeducted:
          int.tryParse(json['points_deducted']?.toString() ?? '0') ?? 0,
      couponDetails: Coupon.fromJson(json['coupon_details'] ?? {}),
    );
  }
}
