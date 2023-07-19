enum PrivacySettingsAnalytics: String {
    // Privacy Settings
    case privacySettingsOpened = "privacy_settings_opened"
    case privacySettingsReportCrashesToggled = "privacy_settings_report_crashes_toggled"
    case privacySettingsAnalyticsTrackingToggled = "privacy_settings_analytics_tracking_toggled"

    // Privacy Choices Banner
    case privacyChoicesBannerPresented = "privacy_choices_banner_presented"
    case privacyChoicesBannerSettingsButtonTapped = "privacy_choices_banner_settings_button_tapped"
    case privacyChoicesBannerSaveButtonTapped = "privacy_choices_banner_save_button_tapped"
}
