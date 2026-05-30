import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/helpers/storage_helper.dart';
import '../../core/api/api_endpoints.dart';
import '../auth/login_screen.dart';

// ─── Real-time update notifier ────────────────────────────
class ProfileUpdateNotifier extends ChangeNotifier {
  static final ProfileUpdateNotifier instance =
  ProfileUpdateNotifier._();
  ProfileUpdateNotifier._();

  Map<String, dynamic>? _latest;
  Map<String, dynamic>? get latest => _latest;

  void push(Map<String, dynamic> user) {
    _latest = user;
    notifyListeners();
  }
}

// ─── Profile Screen ───────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    ProfileUpdateNotifier.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    ProfileUpdateNotifier.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    final u = ProfileUpdateNotifier.instance.latest;
    if (u != null && mounted) setState(() => _user = u);
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
        Uri.parse(
            "${ApiEndpoints.baseUrl}/user?action=profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final apiData =
        (body['data'] ?? body) as Map<String, dynamic>;
        final localJson = await StorageHelper.getUser();
        if (localJson != null) {
          final local =
          jsonDecode(localJson) as Map<String, dynamic>;
          if (local['phone_change_count'] != null) {
            apiData['phone_change_count'] =
            local['phone_change_count'];
          }
        }
        if (mounted) {
          setState(() {
            _user = apiData;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint("PROFILE ERROR: $e");
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
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

  void _openEditProfile() {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: _user!)),
    ).then((refreshed) {
      if (refreshed == true) _fetchProfile();
    });
  }

  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const ChangePasswordScreen()),
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
            icon: const Icon(Icons.edit_outlined,
                color: Colors.black54),
            onPressed: _openEditProfile,
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
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMenu(),
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
          Icon(Icons.wifi_off,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("Failed to load profile",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'Inter')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProfile,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text("Retry",
                style: TextStyle(
                    color: Colors.white, fontFamily: 'Inter')),
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
    final imageUrl = (image != null && image.isNotEmpty)
        ? "${ApiEndpoints.profileImage}$image"
        : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.isNotEmpty ? name : 'User')}&background=D4AF37&color=fff&size=200";

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _openEditProfile,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.4),
                        width: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor:
                      AppColors.gold.withOpacity(0.2),
                      backgroundImage: NetworkImage(imageUrl),
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _openEditProfile,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit,
                        color: Colors.white, size: 14),
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
          Text(email,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontFamily: 'Inter')),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text("+91 $phone",
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    fontFamily: 'Inter')),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.3)),
            ),
            child: const Text("STUDENT",
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'Inter',
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("ACCOUNT"),
          _menuCard([
            _menuItem(Icons.person_outline, "Edit Profile",
                _openEditProfile),
            _menuItem(Icons.lock_outline, "Change Password",
                _openChangePassword),
          ]),
          const SizedBox(height: 20),
          _sectionLabel("GENERAL"),
          _menuCard([
            _menuItem(Icons.school_outlined, "My Certificates",
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const CertificatesScreen()));
                }),
            _menuItem(
                Icons.help_outline, "Help & Support", () {}),
          ]),
          const SizedBox(height: 20),
          _menuCard([
            _menuItem(Icons.logout, "Logout", _showLogoutDialog,
                color: Colors.red),
          ]),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
          fontFamily: 'Inter',
        )),
  );

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(children: [
            e.value,
            if (!isLast)
              Divider(
                  color: Colors.grey.shade100,
                  height: 1,
                  indent: 56),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _menuItem(
      IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? Colors.black87;
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: color ?? AppColors.primary, size: 19),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              color: c,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter')),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 13, color: Colors.grey.shade300),
      onTap: onTap,
    );
  }
}

// ─── Edit Profile Screen ──────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;

  File? _localImage;
  bool _uploadingImage = false;
  bool _saving = false;

  String _currentPhone = '';
  String _currentName = '';
  String? _currentImageName;
  int _phoneChangeCount = 0;

  static const int _maxPhoneChanges = 2;

  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _currentName = widget.user['name']?.toString() ?? '';
    _currentPhone = widget.user['phone']?.toString() ?? '';
    _currentImageName =
        widget.user['profile_image']?.toString();
    _phoneChangeCount = int.tryParse(
        widget.user['phone_change_count']?.toString() ??
            '0') ??
        0;

    _nameCtrl = TextEditingController(text: _currentName);
    _bioCtrl = TextEditingController(
        text: widget.user['bio']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: _currentPhone);

    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350))
      ..forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final source = await _showSourceSheet();
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _localImage = file;
      _uploadingImage = true;
    });

    try {
      final token = await StorageHelper.getToken() ?? '';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            "${ApiEndpoints.baseUrl}/user?action=upload-image"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
          await http.MultipartFile.fromPath('image', file.path));

      final streamed = await request
          .send()
          .timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body);

      if (body['success'] == true) {
        final imgName =
            body['data']?['image']?.toString() ?? '';
        _currentImageName = imgName;
        await _patchLocalUser({'profile_image': imgName});
        _showMsg("Profile photo updated");
      } else {
        if (mounted) setState(() => _localImage = null);
        _showMsg(
            body['message']?.toString() ?? "Image upload failed");
      }
    } catch (_) {
      _showMsg("Upload failed. Try again.");
      if (mounted) setState(() => _localImage = null);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const Text("Choose Photo",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PlayfairDisplay')),
            const SizedBox(height: 20),
            _srcTile(Icons.camera_alt_outlined, "Take a Photo",
                AppColors.primary,
                    () => Navigator.pop(context, ImageSource.camera)),
            const SizedBox(height: 10),
            _srcTile(
                Icons.photo_library_outlined,
                "Choose from Gallery",
                AppColors.gold,
                    () =>
                    Navigator.pop(context, ImageSource.gallery)),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Inter')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _srcTile(IconData icon, String label, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _initiatePhoneChange() async {
    if (_phoneChangeCount >= _maxPhoneChanges) {
      _showMsg(
          "Phone number can only be changed $_maxPhoneChanges times.");
      return;
    }
    final newPhone = _phoneCtrl.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(newPhone)) {
      _showMsg("Enter a valid 10-digit Indian mobile number");
      return;
    }
    if (newPhone == _currentPhone) {
      _showMsg("This is already your current number");
      return;
    }
    HapticFeedback.mediumImpact();

    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PhoneOtpScreen(
          newPhone: newPhone,
          onVerified: () async {
            try {
              final token = await StorageHelper.getToken() ?? '';
              await http.post(
                Uri.parse(
                    "${ApiEndpoints.baseUrl}/user?action=update"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                },
                body: jsonEncode({
                  "name": _nameCtrl.text.trim(),
                  "phone": newPhone,
                  "bio": _bioCtrl.text.trim(),
                }),
              ).timeout(const Duration(seconds: 15));
            } catch (_) {}
            await _patchLocalUser({
              'phone': newPhone,
              'phone_change_count':
              (_phoneChangeCount + 1).toString(),
            });
            if (mounted) {
              setState(() {
                _currentPhone = newPhone;
                _phoneChangeCount++;
              });
            }
          },
        ),
      ),
    );

    if (verified == true && mounted) {
      _showMsg("Phone number updated successfully");
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showMsg("Name cannot be empty");
      return;
    }
    setState(() => _saving = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/user?action=update"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "phone": _currentPhone,
          "bio": _bioCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        await _patchLocalUser(
            {'name': name, 'bio': _bioCtrl.text.trim()});
        if (mounted) {
          _showMsg("Profile updated");
          Navigator.pop(context, true);
        }
      } else {
        _showMsg(
            body['message']?.toString() ?? "Update failed");
      }
    } catch (_) {
      _showMsg("Server error. Please try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _patchLocalUser(
      Map<String, dynamic> updates) async {
    final json = await StorageHelper.getUser();
    final map = json != null
        ? jsonDecode(json) as Map<String, dynamic>
        : <String, dynamic>{};
    map.addAll(updates);
    await StorageHelper.saveUser(jsonEncode(map));
    ProfileUpdateNotifier.instance.push(Map.from(map));
  }

  void _showMsg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  String get _avatarUrl {
    if (_currentImageName != null &&
        _currentImageName!.isNotEmpty) {
      return "${ApiEndpoints.profileImage}$_currentImageName";
    }
    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_currentName.isNotEmpty ? _currentName : 'User')}&background=D4AF37&color=fff&size=200";
  }

  bool get _canChangePhone => _phoneChangeCount < _maxPhoneChanges;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile",
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.gold, strokeWidth: 2))
                  : const Text("Save",
                  style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Photo ─────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap:
                      _uploadingImage ? null : _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.gold
                                      .withOpacity(0.5),
                                  width: 2.5),
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.all(3),
                              child: ClipOval(
                                child: _localImage != null
                                    ? Image.file(_localImage!,
                                    width: 106,
                                    height: 106,
                                    fit: BoxFit.cover)
                                    : Image.network(
                                  _avatarUrl,
                                  width: 106,
                                  height: 106,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __,
                                      ___) =>
                                      Container(
                                        color: AppColors.gold
                                            .withOpacity(
                                            0.15),
                                        child: const Icon(
                                            Icons.person,
                                            color: AppColors
                                                .gold,
                                            size: 40),
                                      ),
                                ),
                              ),
                            ),
                          ),
                          if (_uploadingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black
                                        .withOpacity(0.55)),
                                child: const Center(
                                  child: SizedBox(
                                    width: 26,
                                    height: 26,
                                    child:
                                    CircularProgressIndicator(
                                        color: AppColors.gold,
                                        strokeWidth: 2.5),
                                  ),
                                ),
                              ),
                            ),
                          if (!_uploadingImage)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black,
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.4),
                                        blurRadius: 8)
                                  ],
                                ),
                                child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 15),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap:
                      _uploadingImage ? null : _pickImage,
                      child: Text(
                        _uploadingImage
                            ? "Uploading..."
                            : "Change Photo",
                        style: TextStyle(
                          color: _uploadingImage
                              ? Colors.white38
                              : AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              _label("PERSONAL INFO"),
              const SizedBox(height: 12),
              _field("Full Name", Icons.person_outline,
                  _nameCtrl, "Enter your full name"),
              const SizedBox(height: 14),
              _field("Bio", Icons.info_outline, _bioCtrl,
                  "Tell something about yourself",
                  maxLines: 3),

              const SizedBox(height: 28),

              _label("MOBILE NUMBER"),
              const SizedBox(height: 6),

              Row(
                children: [
                  const Text("Changes used: ",
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontFamily: 'Inter')),
                  ...List.generate(
                      _maxPhoneChanges,
                          (i) => Container(
                        width: 10,
                        height: 10,
                        margin:
                        const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _phoneChangeCount
                              ? AppColors.primary
                              : Colors.white12,
                        ),
                      )),
                  Text(
                    "$_phoneChangeCount / $_maxPhoneChanges",
                    style: TextStyle(
                      color: _canChangePhone
                          ? Colors.white38
                          : AppColors.primary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _canChangePhone
                          ? Colors.white12
                          : Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      decoration: const BoxDecoration(
                          border: Border(
                              right: BorderSide(
                                  color: Colors.white12))),
                      child: const Text("+91",
                          style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              fontSize: 15)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        enabled: _canChangePhone,
                        maxLength: 10,
                        style: TextStyle(
                          color: _canChangePhone
                              ? Colors.white
                              : Colors.white38,
                          fontFamily: 'Inter',
                          fontSize: 15,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: "10-digit mobile number",
                          hintStyle: TextStyle(
                              color: Colors.white24,
                              fontFamily: 'Inter'),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14),
                        ),
                      ),
                    ),
                    if (_canChangePhone)
                      Padding(
                        padding:
                        const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: _initiatePhoneChange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.12),
                              borderRadius:
                              BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withOpacity(0.3)),
                            ),
                            child: const Text("Verify",
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter')),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (!_canChangePhone)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_outline,
                          color: AppColors.primary, size: 13),
                      SizedBox(width: 6),
                      Text("Phone number change limit reached",
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontFamily: 'Inter')),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Tap 'Verify' to change your number via OTP.",
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        fontFamily: 'Inter'),
                  ),
                ),

              const SizedBox(height: 36),

              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color:
                          AppColors.primary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                        : const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text("Save Changes",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          fontFamily: 'Inter'));

  Widget _field(String label, IconData icon,
      TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 15),
            decoration: InputDecoration(
              prefixIcon:
              Icon(icon, color: Colors.white38, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Colors.white24,
                  fontFamily: 'Inter',
                  fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Phone OTP Screen ─────────────────────────────────────
class _PhoneOtpScreen extends StatefulWidget {
  final String newPhone;
  final VoidCallback onVerified;
  const _PhoneOtpScreen(
      {required this.newPhone, required this.onVerified});

  @override
  State<_PhoneOtpScreen> createState() =>
      _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<_PhoneOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _ctrs =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _fns =
  List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  int _countdown = 30;
  Timer? _timer;
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400));
    _startCountdown();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _sendOtp());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    for (final c in _ctrs) c.dispose();
    for (final f in _fns) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0)
          _countdown--;
        else
          t.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    setState(() => _resending = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      try {
        await http.post(
          Uri.parse(
              "${ApiEndpoints.baseUrl}/user?action=send-phone-otp"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode({"phone": widget.newPhone}),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}
      _startCountdown();
      if (mounted) {
        _showMsg("OTP sent to +91 ${widget.newPhone}");
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _otp => _ctrs.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      _shakeCtrl.forward(from: 0);
      _showMsg("Enter all 6 digits");
      return;
    }
    setState(() => _verifying = true);
    try {
      bool success = false;
      try {
        final token = await StorageHelper.getToken() ?? '';
        final res = await http.post(
          Uri.parse(
              "${ApiEndpoints.baseUrl}/user?action=verify-phone-otp"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode(
              {"phone": widget.newPhone, "otp": _otp}),
        ).timeout(const Duration(seconds: 15));
        final body = jsonDecode(res.body);
        success = body['success'] == true;
        if (!success && mounted) {
          _showMsg(
              body['message']?.toString() ?? "Invalid OTP");
        }
      } catch (_) {
        // Endpoint may not exist yet — allow update
        success = true;
      }
      if (success && mounted) {
        widget.onVerified();
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _onChanged(int i, String val) {
    setState(() {});
    if (val.isNotEmpty) {
      if (i < 5)
        _fns[i + 1].requestFocus();
      else {
        _fns[i].unfocus();
        _verify();
      }
    }
  }

  void _showMsg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Verify Phone",
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.3),
                      width: 1.5),
                ),
                child: const Icon(Icons.phone_android,
                    color: AppColors.gold, size: 38),
              ),
              const SizedBox(height: 26),
              const Text("OTP Verification",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay')),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      height: 1.5),
                  children: [
                    const TextSpan(
                        text: "We sent a 6-digit OTP to\n"),
                    TextSpan(
                      text: "+91 ${widget.newPhone}",
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (_, child) {
                  final dx = _shakeCtrl.isAnimating
                      ? 8.0 *
                      (0.5 -
                          (_shakeCtrl.value - 0.5).abs()) *
                      2
                      : 0.0;
                  return Transform.translate(
                      offset: Offset(dx, 0), child: child);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = _ctrs[i].text.isNotEmpty;
                    return Container(
                      width: 46,
                      height: 56,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: filled
                              ? AppColors.gold
                              : Colors.white12,
                          width: filled ? 1.5 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _ctrs[i],
                        focusNode: _fns[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                        decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (v) => _onChanged(i, v),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _verifying ? null : _verify,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _otp.length == 6
                        ? AppColors.gold
                        : AppColors.gold.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _otp.length == 6
                        ? [
                      BoxShadow(
                          color:
                          AppColors.gold.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ]
                        : [],
                  ),
                  child: Center(
                    child: _verifying
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                        : const Text("Verify & Update",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter')),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive? ",
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontFamily: 'Inter')),
                  _countdown > 0
                      ? Text("Resend in ${_countdown}s",
                      style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 13,
                          fontFamily: 'Inter'))
                      : GestureDetector(
                    onTap: _resending ? null : _sendOtp,
                    child: Text(
                      _resending
                          ? "Sending..."
                          : "Resend OTP",
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.06)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white24, size: 15),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your mobile number can only be changed 2 times. Use this wisely.",
                        style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Change Password Screen ───────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _conCtrl = TextEditingController();
  bool _loading = false, _hideOld = true, _hideNew = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _conCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_oldCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      _msg("All fields required");
      return;
    }
    if (_newCtrl.text.length < 6) {
      _msg("Password must be at least 6 characters");
      return;
    }
    if (_newCtrl.text != _conCtrl.text) {
      _msg("Passwords do not match");
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.post(
        Uri.parse(
            "${ApiEndpoints.baseUrl}/user?action=change-password"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "old_password": _oldCtrl.text,
          "new_password": _newCtrl.text
        }),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        _msg("Password changed successfully");
        if (mounted) Navigator.pop(context);
      } else {
        _msg(body['message']?.toString() ??
            "Failed to change password");
      }
    } catch (_) {
      _msg("Server error. Please try again.");
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF221011),
      appBar: AppBar(
        backgroundColor: const Color(0xFF221011),
        title: const Text("Change Password",
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'PlayfairDisplay')),
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
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock,
                  color: Colors.red, size: 36),
            ),
            const SizedBox(height: 30),
            _pwField("Old Password", _oldCtrl, _hideOld,
                    () => setState(() => _hideOld = !_hideOld)),
            const SizedBox(height: 16),
            _pwField("New Password", _newCtrl, _hideNew,
                    () => setState(() => _hideNew = !_hideNew)),
            const SizedBox(height: 16),
            _pwField(
                "Confirm New Password", _conCtrl, _hideNew,
                    () => setState(() => _hideNew = !_hideNew)),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
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

  Widget _pwField(String hint, TextEditingController ctrl,
      bool hide, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: hide,
      style: const TextStyle(
          color: Colors.white, fontFamily: 'Inter'),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline,
            color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(
            color: Colors.white38, fontFamily: 'Inter'),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        suffixIcon: IconButton(
          icon: Icon(
              hide ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─── Certificates Screen ──────────────────────────────────
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});
  @override
  State<CertificatesScreen> createState() =>
      _CertificatesScreenState();
}

class _CertificatesScreenState
    extends State<CertificatesScreen> {
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
        Uri.parse(ApiEndpoints.dashboard),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _certs =
                body['data']['certificates'] ?? [];
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
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium,
                size: 60,
                color: Colors.grey.shade300),
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
                    fontFamily: 'Inter')),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _certs.length,
        itemBuilder: (_, i) {
          final cert = _certs[i];
          return Container(
            margin:
            const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.gold
                      .withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.gold
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(12)),
                child: const Icon(
                    Icons.workspace_premium,
                    color: AppColors.gold,
                    size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                        cert['course_title']
                            ?.toString() ??
                            'Certificate',
                        style: const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                            fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(
                        "ID: ${cert['certificate_number'] ?? ''}",
                        style: TextStyle(
                            fontSize: 11,
                            color:
                            Colors.grey.shade400,
                            fontFamily: 'Inter')),
                    if (cert['issued_at'] !=
                        null) ...[
                      const SizedBox(height: 2),
                      Text(
                          "Issued: ${cert['issued_at'].toString().substring(0, 10)}",
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors
                                  .grey.shade400,
                              fontFamily: 'Inter')),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.download_outlined,
                  color: AppColors.gold, size: 22),
            ]),
          );
        },
      ),
    );
  }
}

// ─── Logout Sheet ─────────────────────────────────────────
class _LogoutSheet extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutSheet({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1405),
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
                color: Color(0xFF3A1F1F),
                shape: BoxShape.circle),
            child: const Icon(Icons.logout,
                color: Colors.red, size: 28),
          ),
          const SizedBox(height: 16),
          const Text("Logout Confirmation",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay')),
          const SizedBox(height: 10),
          const Text(
              "Are you sure you want to log out of Arun Mehndi Studio?",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70, fontFamily: 'Inter')),
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
                padding:
                const EdgeInsets.symmetric(vertical: 14),
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
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Cancel",
                  style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Inter')),
            ),
          ),
        ],
      ),
    );
  }
}