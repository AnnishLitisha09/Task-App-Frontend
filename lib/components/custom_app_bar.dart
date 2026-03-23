import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/common/notifications_page.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final String? date;
  final int notificationCount;
  final String? profileImageUrl;
  final int? venueId;

  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.date,
    this.notificationCount = 0,
    this.profileImageUrl,
    this.venueId,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.brandAccent,
                    AppTheme.brandAccent.withOpacity(0.2),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  profileImageUrl ?? 'https://i.pravatar.cc/150?u=user',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null)
                  Text(
                    date!,
                    style: AppTheme.bodySub.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(title, style: AppTheme.h2.copyWith(fontSize: 18)),
              ],
            ),
            const Spacer(),
            if (actions != null) ...actions!,
            const SizedBox(width: 8),
            _buildNotificationBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBadge(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationsPage(venueId: venueId)),
        );
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPrimary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.textMain,
              size: 22,
            ),
            if (notificationCount > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
