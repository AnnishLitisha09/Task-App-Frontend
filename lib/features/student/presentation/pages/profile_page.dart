import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/custom_button.dart';
import 'profile_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Keep white background for content
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Curved Header Section
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Background Curve
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColorDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                
                // Content inside Header
                Positioned(
                  top: 60,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const BackButton(color: Colors.white),
                       Text("My Profile", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       IconButton(
                         icon: const Icon(Icons.settings_outlined, color: Colors.white),
                         onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage()));
                         },
                       ),
                    ],
                  ),
                ),

                // Floating Profile Card
                Positioned(
                  top: 140, // Overlapping the curve
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=student'),
                        ),
                      ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 12),
                      Text(
                        "Annish Litisha",
                        style: GoogleFonts.inter(
                          color: Colors.white, 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                        ),
                      ),
                      Text(
                        "Computer Science • Year 3",
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100), // Spacing for the overlapping content

            // Stats Grid (Unique Layout)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFloatingStat(context, "Score", "850", Colors.amber),
                  _buildFloatingStat(context, "Tasks", "12", Colors.blue),
                  _buildFloatingStat(context, "Rank", "#5", Colors.purple),
                ],
              ),
            ).animate().slideY(begin: 0.5, end: 0, delay: 200.ms),

            const SizedBox(height: 32),

            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Personal Info", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoCard(context, Icons.email_outlined, "Email", "student@university.edu"),
                  _buildInfoCard(context, Icons.badge_outlined, "Student ID", "CS-2023-001"),
                  _buildInfoCard(context, Icons.phone_outlined, "Phone", "+1 234 567 890"),
                  _buildInfoCard(context, Icons.location_on_outlined, "Dorm", "Block A, Room 101"),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: "Logout",
                      backgroundColor: Colors.red.shade50,
                      textColor: Colors.red,
                      onPressed: () {
                         Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingStat(BuildContext context, String label, String value, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            value, 
            style: GoogleFonts.inter(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: color
            )
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 12, 
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500
            )
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
