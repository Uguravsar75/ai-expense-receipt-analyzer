import 'package:flutter/material.dart';

import '../auth/auth_storage.dart';
import '../screens/home_screen.dart';
import '../screens/import_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/stats_screen.dart';
import '../utils/app_strings.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onRefresh;

  const SharedAppBar({super.key, required this.title, this.onRefresh});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = AppStrings.of(ctx);
        return AlertDialog(
          title: Text(s.profileLogout),
          content: Text(AppStrings.current.profileLogout == 'Log Out'
              ? 'Are you sure you want to log out?'
              : 'Çıkış yapmak istediğine emin misin?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.profileLogout),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await AuthStorage.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
    );
  }

  Future<void> _go(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: s.navHome,
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false,
          ),
        ),
        IconButton(
          tooltip: s.navStats,
          icon: const Icon(Icons.bar_chart),
          onPressed: () => _go(context, const StatsScreen()),
        ),
        IconButton(
          tooltip: s.navImport,
          icon: const Icon(Icons.upload_file),
          onPressed: () => _go(context, const ImportScreen()),
        ),
        IconButton(
          tooltip: s.navProfile,
          icon: const Icon(Icons.person),
          onPressed: () => _go(context, const ProfileScreen()),
        ),
        IconButton(
          tooltip: s.profileLogout,
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
        ),
      ],
    );
  }
}
