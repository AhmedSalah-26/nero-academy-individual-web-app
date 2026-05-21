import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/phone_input_field.dart';

class ParentEntranceScreen extends StatefulWidget {
  const ParentEntranceScreen({super.key});

  @override
  State<ParentEntranceScreen> createState() => _ParentEntranceScreenState();
}

class _ParentEntranceScreenState extends State<ParentEntranceScreen> {
  final _phoneCtrl = TextEditingController();
  String _countryDialCode = '+20';
  final bool _isLoading = false;

  void _onEnter() {
    if (_phoneCtrl.text.trim().isEmpty) return;

    final phone = '$_countryDialCode${_phoneCtrl.text.trim()}';
    context.push('/parent_dashboard', extra: phone);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.locale.languageCode == 'ar'
            ? 'بوابة ولي الأمر'
            : 'Parent Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                context.locale.languageCode == 'ar'
                    ? 'تابع تقدم أبنائك'
                    : 'Track Your Children\'s Progress',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.locale.languageCode == 'ar'
                    ? 'أدخل رقم هاتفك المسجل لدى أبنائك للاطلاع على دوراتهم ونتائجهم'
                    : 'Enter your phone number registered with your children to view their courses and results',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PhoneInputField(
                controller: _phoneCtrl,
                label: context.locale.languageCode == 'ar'
                    ? 'رقم الهاتف'
                    : 'Phone Number',
                onCountryCodeChanged: (code) {
                  setState(() {
                    _countryDialCode = code;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onEnter,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          context.locale.languageCode == 'ar'
                              ? 'دخول'
                              : 'Enter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
