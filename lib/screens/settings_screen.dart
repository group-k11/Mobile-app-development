import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.cardDecoration,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Unknown User',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: authProvider.isOwner
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          authProvider.isOwner ? '👑 Owner' : '🏪 Staff',
                          style: TextStyle(
                            fontSize: 12,
                            color: authProvider.isOwner
                                ? AppColors.accent
                                : AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Staff Management (Owner only)
          if (authProvider.isOwner) ...[
            _buildSectionTitle('Staff Management'),
            _buildSettingsTile(
              icon: Icons.person_add_outlined,
              title: 'Create Staff Account',
              subtitle: 'Add a new cashier to your store',
              onTap: () => _showCreateStaffDialog(context),
            ),
            _buildSettingsTile(
              icon: Icons.people_outlined,
              title: 'Manage Staff',
              subtitle: 'View and manage existing staff',
              onTap: () => _showManageStaffDialog(context),
            ),
            const SizedBox(height: 20),
          ],

          // App Info
          _buildSectionTitle('App Information'),
          _buildSettingsTile(
            icon: Icons.info_outlined,
            title: 'About $kAppName',
            subtitle: kAppTagline,
            onTap: () => _showAboutAppDialog(context),
          ),
          _buildSettingsTile(
            icon: Icons.code,
            title: 'Version',
            subtitle: '2.0.0',
            onTap: null,
          ),
          const SizedBox(height: 20),

          // Account section
          _buildSectionTitle('Account'),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            color: AppColors.error,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppDecorations.cardDecoration,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primaryLight).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? AppColors.primaryLight, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: onTap != null
            ? Icon(Icons.chevron_right, color: Colors.grey[400])
            : null,
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── Create Staff Dialog (Simplified — no owner password) ──
  void _showCreateStaffDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Staff Account'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: AppDecorations.inputDecoration(
                    'Staff Full Name',
                    icon: Icons.person_outlined,
                  ),
                  validator: (v) => validateRequired(v, 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: AppDecorations.inputDecoration(
                    'Staff Email',
                    icon: Icons.email_outlined,
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: AppDecorations.inputDecoration(
                    'Staff Password',
                    icon: Icons.lock_outlined,
                  ),
                  obscureText: true,
                  validator: validatePassword,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await authProvider.createStaffAccount(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                password: passwordController.text,
              );

              if (ctx.mounted) Navigator.pop(ctx);

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Staff account created!'
                      : authProvider.error ?? 'Failed to create account'),
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ─── Manage Staff Dialog ──────────────────────────────
  void _showManageStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.people, color: AppColors.primaryLight),
            SizedBox(width: 8),
            Text('Staff Members'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<UserModel>>(
            stream: Provider.of<AuthProvider>(context, listen: false)
                .staffStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final staffList = snapshot.data ?? [];

              if (staffList.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No staff members yet',
                          style: AppTextStyles.bodySecondary),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: staffList.length,
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        staff.name.isNotEmpty
                            ? staff.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(staff.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(staff.email,
                        style: AppTextStyles.caption),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () => _confirmDeleteStaff(ctx, staff),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStaff(BuildContext dialogCtx, UserModel staff) {
    showDialog(
      context: dialogCtx,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Staff?'),
        content: Text(
            'Are you sure you want to remove ${staff.name} from your store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.deleteStaff(staff.userId);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '${staff.name} removed'
                        : 'Failed to remove staff'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_rounded,
                  color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(kAppName, style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            const Text(kAppTagline, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 16),
            const Text(
              'ShelfSense helps small shop owners manage products, track sales, monitor stock levels, and view analytics — all from one app.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              await authProvider.signOut();
              navigator.pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
