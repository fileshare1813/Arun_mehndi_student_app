import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/helpers/storage_helper.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _hasError = false;

  static const String _base = "https://api.aktuhub.in/api";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse("$_base/user?action=profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _user = body['data'] ?? body;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _loading = false; _hasError = true; });
      }
    } catch (e) {
      debugPrint("PROFILE ERROR: $e");
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _logout() async {
    await StorageHelper.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoutSheet(onLogout: _logout),
    );
  }

  void _showEditProfile() {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
    ).then((_) => _fetchProfile());
  }

  void _showChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black54),
            onPressed: _showEditProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMenuSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("Failed to load profile",
              style: TextStyle(
                  color: Colors.grey, fontSize: 16, fontFamily: 'Inter')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProfile,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Retry",
                style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _user?['name']?.toString() ?? '';
    final email = _user?['email']?.toString() ?? '';
    final phone = _user?['phone']?.toString() ?? '';
    final image = _user?['profile_image']?.toString();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        children: [
          // Avatar with gold ring border
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.4),
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.gold.withOpacity(0.2),
                    backgroundImage: image != null && image.isNotEmpty
                        ? NetworkImage(
                        "https://api.aktuhub.in/uploads/profile_images/$image")
                        : NetworkImage(
                        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=D4AF37&color=fff&size=200"),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _showEditProfile,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name.isNotEmpty
                ? name[0].toUpperCase() + name.substring(1)
                : 'Student',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontFamily: 'Inter'),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              phone,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  fontFamily: 'Inter'),
            ),
          ],
          const SizedBox(height: 16),
          // Student badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: const Text(
              "STUDENT",
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("ACCOUNT"),
          _menuCard([
            _menuItem(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: _showEditProfile,
            ),
            _menuItem(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: _showChangePassword,
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel("GENERAL"),
          _menuCard([
            _menuItem(
              icon: Icons.school_outlined,
              title: "My Certificates",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CertificatesScreen()),
              ),
            ),
            _menuItem(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),
          _menuCard([
            _menuItem(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.red,
              onTap: _showLogoutDialog,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
        fontFamily: 'Inter',
      ),
    ),
  );

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                  color: Colors.grey.shade100,
                  height: 1,
                  indent: 56,
                  endIndent: 0,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Colors.black87;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 19),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 15,
            color: c,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter'),
      ),
      trailing:
      Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey.shade300),
      onTap: onTap,
    );
  }
}

// ─── EDIT PROFILE ─────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user['name']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: widget.user['phone']?.toString() ?? '');
    _bioCtrl = TextEditingController(text: widget.user['bio']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _msg("Name is required");
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.post(
        Uri.parse("https://api.aktuhub.in/api/user?action=update"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": _nameCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "bio": _bioCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final userJson = await StorageHelper.getUser();
        if (userJson != null) {
          final map = jsonDecode(userJson) as Map<String, dynamic>;
          map['name'] = _nameCtrl.text.trim();
          map['phone'] = _phoneCtrl.text.trim();
          await StorageHelper.saveUser(jsonEncode(map));
        }
        if (mounted) {
          _msg("Profile updated");
          Navigator.pop(context);
        }
      } else {
        _msg(body['message'] ?? "Update failed");
      }
    } catch (e) {
      _msg("Server error. Please try again.");
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text("Edit Profile",
            style: TextStyle(color: Colors.white, fontFamily: 'PlayfairDisplay')),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _field("Full Name", Icons.person, _nameCtrl),
            const SizedBox(height: 16),
            _field("Phone Number", Icons.phone, _phoneCtrl,
                keyboard: TextInputType.phone),
            const SizedBox(height: 16),
            _field("Bio", Icons.info_outline, _bioCtrl, maxLines: 3),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _loading ? null : _save,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Changes",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Inter'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, IconData icon, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Inter'),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── CHANGE PASSWORD ──────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _hideOld = true;
  bool _hideNew = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_oldCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      _msg("All fields required");
      return;
    }
    if (_newCtrl.text.length < 6) {
      _msg("New password must be at least 6 characters");
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _msg("Passwords do not match");
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.post(
        Uri.parse("https://api.aktuhub.in/api/user?action=change-password"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "old_password": _oldCtrl.text,
          "new_password": _newCtrl.text,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        _msg("Password changed successfully");
        if (mounted) Navigator.pop(context);
      } else {
        _msg(body['message'] ?? "Failed to change password");
      }
    } catch (_) {
      _msg("Server error. Please try again.");
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF221011),
      appBar: AppBar(
        backgroundColor: const Color(0xFF221011),
        title: const Text("Change Password",
            style: TextStyle(color: Colors.white, fontFamily: 'PlayfairDisplay')),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: Colors.red, size: 36),
            ),
            const SizedBox(height: 30),
            _pwField("Old Password", _oldCtrl, _hideOld,
                    () => setState(() => _hideOld = !_hideOld)),
            const SizedBox(height: 16),
            _pwField("New Password", _newCtrl, _hideNew,
                    () => setState(() => _hideNew = !_hideNew)),
            const SizedBox(height: 16),
            _pwField("Confirm New Password", _confirmCtrl, _hideNew,
                    () => setState(() => _hideNew = !_hideNew)),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Password",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Inter')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(String hint, TextEditingController ctrl, bool hide,
      VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: hide,
      style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Inter'),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        suffixIcon: IconButton(
          icon: Icon(hide ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─── CERTIFICATES SCREEN ──────────────────────────────────
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<dynamic> _certs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse("https://api.aktuhub.in/api/student-dashboard"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (mounted) {
          setState(() {
            _certs = data['certificates'] ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("My Certificates",
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay')),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _certs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text("No certificates yet",
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Text(
              "Complete a course to earn your certificate",
              style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 13,
                  fontFamily: 'Inter'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: _certs.length,
        itemBuilder: (_, i) {
          final cert = _certs[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: AppColors.gold, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert['course_title']?.toString() ?? 'Certificate',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${cert['certificate_number'] ?? ''}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (cert['issued_at'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Issued: ${cert['issued_at'].toString().substring(0, 10)}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.download_outlined,
                    color: AppColors.gold, size: 22),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── LOGOUT SHEET ─────────────────────────────────────────
class _LogoutSheet extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutSheet({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1405),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF3A1F1F),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, color: Colors.red, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            "Logout Confirmation",
            style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay'),
          ),
          const SizedBox(height: 10),
          const Text(
            "Are you sure you want to log out of Arun Mehndi Studio?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Log Out",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Inter')),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Cancel",
                  style: TextStyle(
                      color: Colors.white70, fontFamily: 'Inter')),
            ),
          ),
        ],
      ),
    );
  }
}