import Foundation

enum PrivacySettingsAnalytics: String {
    // Privacy Settings
    case privacySettingsOpened = "privacy_settings_opened"
    case privacySettingsReportCrashesToggled = "privacy_settings_report_crashes_toggled"

    // Privacy Choices Banner
    case privacyChoicesBannerPresented = "privacy_choices_banner_presented"
    case prviacyChoicesBannerSettingsButtonTapped = "privacy_choices_banner_settings_button_tapped"
    case privacyChoicesBannerSaveButtonTapped = "privacy_choices_banner_save_button_tapped"
}
