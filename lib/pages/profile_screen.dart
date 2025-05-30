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