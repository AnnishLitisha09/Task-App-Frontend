import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnDutyWalletPage extends StatelessWidget {
  const OnDutyWalletPage({super.key});

  // --- Design Tokens ---
  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color couponGold = const Color(0xFFF59E0B);
  final Color successGreen = const Color(0xFF10B981);

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
      body: Column(
        children: [
          _buildBalanceHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                _sectionLabel("Active Coupons"),
                _buildCouponCard(
                  context,
                  title: "Technical Symposium",
                  id: "OD-99281",
                  expiry: "Valid until Feb 12, 2026",
                  status: "Active",
                ),
                _buildCouponCard(
                  context,
                  title: "Inter-College Sports Meet",
                  id: "OD-99244",
                  expiry: "Valid until Feb 15, 2026",
                  status: "Active",
                ),
                const SizedBox(height: 24),
                _sectionLabel("Expired"),
                _buildCouponCard(
                  context,
                  title: "UI/UX Design Workshop",
                  id: "OD-98102",
                  expiry: "Expired Jan 30, 2026",
                  status: "Expired",
                  isExpired: true,
                ),
              ],
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
      height: 180, // Defined height for a better card aspect ratio
      child: Stack(
        children: [
          // 1. The Main Gradient Base
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

          // 2. Abstract "Mesh" Design Decor
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),

          // 3. The Content Layer
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
                    const Text(
                      "12",
                      style: TextStyle(
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
                // 4. Glass-morphic Refresh Badge
                ClipRRect(
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
                            "Next Refresh: March 01",
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
    bool isExpired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isExpired ? surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired ? Colors.transparent : surfaceColor,
          width: 2,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Side Bar Decor
            Container(
              width: 10,
              decoration: BoxDecoration(
                color: isExpired ? slate500.withOpacity(0.2) : brandAccent,
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
                        if (!isExpired)
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
                        color: isExpired ? slate500 : slate900,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        decoration: isExpired
                            ? TextDecoration.lineThrough
                            : null,
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
            // REDEEM BUTTON
            if (!isExpired)
              GestureDetector(
                onTap: () => _showRedeemDialog(context, title),
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
  void _showRedeemDialog(BuildContext context, String title) {
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
                "Confirm use of OD credit for:\n\"$title\"",
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
                        _showSuccessToast(context);
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
