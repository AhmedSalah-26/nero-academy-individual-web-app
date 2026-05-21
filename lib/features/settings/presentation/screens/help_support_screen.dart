import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../widgets/help_support/help_search_bar.dart';
import '../widgets/help_support/help_topics_grid.dart';
import '../widgets/help_support/help_faq_section.dart';
import '../widgets/help_support/help_contact_section.dart';

/// Help & Support Screen
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _searchController = TextEditingController();

  List<HelpTopic> get _topics => [
        HelpTopic(
            id: 'account',
            title: 'help_support.account'.tr(),
            icon: Icons.person_outline),
        HelpTopic(
            id: 'payment',
            title: 'help_support.payment'.tr(),
            icon: Icons.credit_card_outlined),
        HelpTopic(
            id: 'courses',
            title: 'help_support.courses'.tr(),
            icon: Icons.play_circle_outline),
        HelpTopic(
            id: 'certificate',
            title: 'help_support.certificate'.tr(),
            icon: Icons.verified_outlined),
      ];

  List<FaqItem> get _faqItems => [
        FaqItem(question: 'help_support.faq_refund'.tr()),
        FaqItem(question: 'help_support.faq_certificate'.tr()),
        FaqItem(question: 'help_support.faq_offline'.tr()),
        FaqItem(question: 'help_support.faq_login'.tr()),
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _buildAppBar(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(isDark),
                  const SizedBox(height: 24),
                  HelpSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    hintText: 'help_support.search_placeholder'.tr(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  _buildTopicsSection(isDark),
                  const SizedBox(height: 32),
                  HelpFaqSection(
                    title: 'help_support.top_questions'.tr(),
                    items: _faqItems,
                    onViewAll: _viewAllFaqs,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  HelpContactSection(
                    onLiveChat: _openLiveChat,
                    onEmail: _sendEmail,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  _buildFooterLinks(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : AppColors.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.grey800.withValues(alpha: 0.5)
                : AppColors.grey200.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          Expanded(
            child: Text(
              'help_support.title'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      'help_support.how_can_we_help'.tr(),
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      ),
    );
  }

  Widget _buildTopicsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'help_support.common_topics'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 12),
        HelpTopicsGrid(
          topics: _topics,
          onTopicTap: _onTopicTap,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildFooterLinks(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _openPrivacyPolicy,
          child: Text(
            'settings.privacy_policy'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
          ),
        ),
        Text(
          '•',
          style: TextStyle(
            color: isDark ? AppColors.grey700 : AppColors.grey300,
          ),
        ),
        TextButton(
          onPressed: _openTermsOfService,
          child: Text(
            'settings.terms_of_service'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    AppLogger.i('[HelpSupportScreen] Search: $query');
    // Implement search functionality
  }

  void _onTopicTap(HelpTopic topic) {
    HapticFeedback.lightImpact();
    AppLogger.i('[HelpSupportScreen] Topic tapped: ${topic.id}');
    // Navigate to topic details
  }

  void _viewAllFaqs() {
    HapticFeedback.lightImpact();
    AppLogger.i('[HelpSupportScreen] View all FAQs');
    // Navigate to FAQs screen
  }

  void _openLiveChat() {
    HapticFeedback.mediumImpact();
    AppLogger.i('[HelpSupportScreen] Open live chat');
    // Open live chat
  }

  void _sendEmail() {
    HapticFeedback.mediumImpact();
    AppLogger.i('[HelpSupportScreen] Send email');
    // Open email client
  }

  void _openPrivacyPolicy() {
    AppLogger.i('[HelpSupportScreen] Open privacy policy');
    // Navigate to privacy policy
  }

  void _openTermsOfService() {
    AppLogger.i('[HelpSupportScreen] Open terms of service');
    // Navigate to terms of service
  }
}
