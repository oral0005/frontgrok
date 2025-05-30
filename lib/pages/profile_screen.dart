import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<User> _userProfile;

  // Для диалога настроек:
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _avatarUrl;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  String _selectedLanguageCode = 'en';
  bool _isLoading = false;
  final List<Map<String, String>> languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'kk', 'label': 'Қазақша'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  String getAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return '';
    if (avatarUrl.startsWith('http')) return avatarUrl;
    // Используем актуальный baseUrl
    return '$serverBaseUrl$avatarUrl';
  }

  Future<void> _loadUserProfile() async {
    _userProfile = _apiService.getUserProfile();
    final user = await _userProfile;
    setState(() {
      _avatarUrl = user.avatarUrl;
      _nameController.text = user.name;
      _surnameController.text = user.surname;
      _selectedLanguageCode = user.language ?? 'en';
    });
    // Устанавливаем локаль из профиля пользователя
    if (mounted) {
      context.setLocale(Locale(user.language ?? 'en'));
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _userProfile = _apiService.getUserProfile();
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image'.tr())));
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() { _isLoading = true; });
    try {
      String? avatarUrl = _avatarUrl;
      if (_imageFile != null) {
        avatarUrl = await _apiService.uploadAvatar(_imageFile!);
      }
      await _apiService.updateProfile(
        name: _nameController.text,
        surname: _surnameController.text,
        avatarUrl: avatarUrl,
        language: _selectedLanguageCode,
      );
      if (mounted) {
        Navigator.pop(context);
        _refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('settings_saved')));
      }
    } catch (e, stack) {
      print('Error saving settings: $e');
      print('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_saving_settings')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        File? localImageFile = _imageFile;
        String? localName = _nameController.text;
        String? localSurname = _surnameController.text;
        String localLanguage = languages.firstWhere(
          (lang) => lang['code'] == _selectedLanguageCode,
          orElse: () => languages[0],
        )['label']!;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFEF7FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('settings'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (pickedFile != null) {
                          setStateDialog(() {
                            localImageFile = File(pickedFile.path);
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: localImageFile != null
                                  ? FileImage(localImageFile!)
                                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                                      ? NetworkImage(getAvatarUrl(_avatarUrl))
                                      : const AssetImage('assets/default_avatar.png')) as ImageProvider,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'name'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person),
                      ),
                      style: const TextStyle(fontFamily: 'Montserrat'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _surnameController,
                      decoration: InputDecoration(
                        labelText: 'surname'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      style: const TextStyle(fontFamily: 'Montserrat'),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguageCode,
                          isExpanded: true,
                          items: languages.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang['code'],
                              child: Text(lang['label']!, style: const TextStyle(fontFamily: 'Montserrat')),
                            );
                          }).toList(),
                          onChanged: _onLanguageChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr(), style: TextStyle(fontFamily: 'Montserrat', color: Colors.grey)),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text('logout'.tr(), style: TextStyle(color: Colors.red, fontFamily: 'Montserrat')),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('token');
                          await prefs.remove('userId');
                          if (mounted) {
                            Navigator.pop(context);
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                          }
                        },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showChangePasswordDialog();
                  },
                  child: Text('change_password'.tr(), style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _imageFile = localImageFile;
                          });
                          _saveSettings();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF201731),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text('save'.tr(), style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Montserrat',
          fontFamilyFallback: ['Roboto'],
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF7FF),
        appBar: AppBar(
          title: Text('profile'.tr(), style: TextStyle(fontFamily: 'Montserrat')),
          centerTitle: true,
          backgroundColor: const Color(0xFFFEF7FF),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: FutureBuilder<User>(
            future: _userProfile,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: \\${snapshot.error}', style: const TextStyle(fontFamily: 'Montserrat'), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF201731),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text('retry'.tr(), style: TextStyle(fontFamily: 'Montserrat')),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Center(child: Text('no_profile_data'.tr(), style: TextStyle(fontFamily: 'Montserrat')));
              }
              final user = snapshot.data!;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Аватар с рамкой и тенью
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(getAvatarUrl(user.avatarUrl))
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Имя пользователя
                      Text(
                        '${user.name} ${user.surname}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          color: Color(0xFF201731),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Username
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Карточки с информацией
                      _buildInfoCard(Icons.phone, 'phone'.tr(), user.phoneNumber),
                      const SizedBox(height: 16),
                      // Статус верификации
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: user.isVerified ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: user.isVerified ? Colors.green : Colors.red, width: 2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              user.isVerified ? Icons.verified : Icons.sms_failed_rounded,
                              color: user.isVerified ? Colors.green : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                user.isVerified
                                    ? 'phone_verified'.tr()
                                    : 'phone_not_verified'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                  color: user.isVerified ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            if (!user.isVerified)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VerificationScreen(
                                        phoneNumber: user.phoneNumber,
                                        onVerificationSuccess: () {
                                          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                                        },
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.sms, size: 18, color: Colors.white),
                                label: Text('verify_phone'.tr(), style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Montserrat')),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Montserrat')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }
}