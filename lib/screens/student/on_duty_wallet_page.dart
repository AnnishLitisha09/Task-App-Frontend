import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/student_service.dart';
import '../../models/coupon_model.dart';

class OnDutyWalletPage extends StatefulWidget {
  const OnDutyWalletPage({super.key});

  @override
  State<OnDutyWalletPage> createState() => _OnDutyWalletPageState();
}

class _OnDutyWalletPageState extends State<OnDutyWalletPage> {
  final StudentService _studentService = StudentService();
  bool _isLoading = true;
  int _currentScore = 0;
  List<Coupon> _availableCoupons = [];
  List<RedeemedItem> _redeemedCoupons = [];

  // --- Design Tokens ---
  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color couponGold = const Color(0xFFF59E0B);
  final Color successGreen = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Fetch Available Coupons
    try {
      final availableResponse = await _studentService.getAvailableCoupons();
      if (mounted) {
        setState(() {
          _availableCoupons = availableResponse.coupons;
          _currentScore = availableResponse.score;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Available Coupons Error: $e")));
      }
    }

    // Fetch Redeemed Coupons
    try {
      final redeemedResponse = await _studentService.getRedeemedCoupons();
      if (mounted) {
        setState(() {
          _redeemedCoupons = redeemedResponse.items;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Redeemed Coupons Error: $e")));
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRedeem(int couponId, String title) async {
    try {
      final success = await _studentService.redeemCoupon(couponId);
      if (success && mounted) {
        _showSuccessToast(context);
        _fetchData(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Redemption failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: slate900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "On-Duty Wallet",
          style: TextStyle(
            color: slate900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBalanceHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (_availableCoupons.isNotEmpty) ...[
                          _sectionLabel("Available Coupons"),
                          ..._availableCoupons.map(
                            (coupon) => _buildCouponCard(
                              context,
                              id: "OD-${coupon.id}",
                              title: coupon.name,
                              expiry: "Cost: ${coupon.points} Credits",
                              status: "Available",
                              couponId: coupon.id,
                              points: coupon.points,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_redeemedCoupons.isNotEmpty) ...[
                          _sectionLabel("Redeemed"),
                          ..._redeemedCoupons.map(
                            (item) => _buildCouponCard(
                              context,
                              id: "RD-${item.redemptionId}",
                              title: item.couponName,
                              expiry:
                                  "Deducted: ${item.pointsDeducted} Credits",
                              status: "Redeemed",
                              isRedeemed: true,
                            ),
                          ),
                        ],
                        if (_availableCoupons.isEmpty &&
                            _redeemedCoupons.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 100),
                              child: Text(
                                "No coupons available",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- TOP BALANCE CARD ---
  Widget _buildBalanceHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      height: 180,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandAccent, const Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: brandAccent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CURRENT BALANCE",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$_currentScore",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 8),
                      child: Text(
                        "Credits",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Synced with Wallet",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(curve: Curves.easeOutBack);
  }

  // --- COUPON TICKET WIDGET ---
  Widget _buildCouponCard(
    BuildContext context, {
    required String title,
    required String id,
    required String expiry,
    required String status,
    bool isRedeemed = false,
    int? couponId,
    int? points,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRedeemed ? surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRedeemed ? Colors.transparent : surfaceColor,
          width: 2,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 10,
              decoration: BoxDecoration(
                color: isRedeemed ? slate500.withOpacity(0.2) : brandAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          id,
                          style: TextStyle(
                            color: slate500,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isRedeemed)
                          Icon(
                            Icons.verified_rounded,
                            color: couponGold,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: isRedeemed ? slate500 : slate900,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 12, color: slate500),
                        const SizedBox(width: 4),
                        Text(
                          expiry,
                          style: TextStyle(
                            color: slate500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isRedeemed && couponId != null)
              GestureDetector(
                onTap: () =>
                    _showRedeemDialog(context, title, couponId, points ?? 0),
                child: Container(
                  width: 75,
                  decoration: BoxDecoration(
                    color: brandAccent.withOpacity(0.05),
                    border: Border(
                      left: BorderSide(color: surfaceColor, width: 2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_num_rounded,
                        color: brandAccent,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "REDEEM",
                        style: TextStyle(
                          color: brandAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.1, end: 0, delay: 100.ms);
  }

  // --- REDEMPTION DIALOG ---
  void _showRedeemDialog(
    BuildContext context,
    String title,
    int couponId,
    int cost,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brandAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: brandAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Redeem Coupon?",
                style: TextStyle(
                  color: slate900,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Confirm use of $cost credits for:\n\"$title\"",
                textAlign: TextAlign.center,
                style: TextStyle(color: slate500, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: slate500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleRedeem(couponId, title);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Redeem",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 200.ms),
    );
  }

  void _showSuccessToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Coupon redeemed successfully!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: successGreen,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: slate500,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
