import Foundation

enum MigrationEvent: String {
    // Content Import
    case contentImportEligibility = "migration_content_import_eligibility"
    case contentImportSucceeded = "migration_content_import_succeeded"
    case contentImportFailed = "migration_content_import_failed"

    // Email
    case emailTriggered = "migration_email_triggered"
    case emailSent = "migration_email_sent"
    case emailFailed = "migration_email_failed"

    // Welcome Screen
    case welcomeScreenShown = "migration_welcome_screen_shown"
    case welcomeScreenContinueTapped = "migration_welcome_screen_continue_button_tapped"
    case welcomeScreenHelpButtonTapped = "migration_welcome_screen_help_button_tapped"
    case welcomeScreenAvatarTapped = "migration_welcome_screen_avatar_tapped"

    // Notifications Screen
    case notificationsScreenShown = "migration_notifications_screen_shown"
    case notificationsScreenContinueTapped = "migration_notifications_screen_continue_button_tapped"
    case notificationsScreenDecideLaterButtonTapped = "migration_notifications_screen_decide_later_button_tapped"
    case notificationsScreenPermissionGranted = "migration_notifications_screen_permission_granted"
    case notificationsScreenPermissionDenied = "migration_notifications_screen_permission_denied"

    // Thanks Screen
    case thanksScreenShown = "migration_thanks_screen_shown"
    case thanksScreenFinishTapped = "migration_thanks_screen_finish_button_tapped"

    // Please Delete WordPress Card & Screen
    case pleaseDeleteWordPressCardShown = "migration_please_delete_wordpress_card_shown"
    case pleaseDeleteWordPressCardHidden = "migration_please_delete_wordpress_card_hidden"
    case pleaseDeleteWordPressCardTapped = "migration_please_delete_wordpress_card_tapped"
    case pleaseDeleteWordPressScreenShown = "migration_please_delete_wordpress_screen_shown"
    case pleaseDeleteWordPressScreenGotItTapped = "migration_please_delete_wordpress_screen_gotit_tapped"
    case pleaseDeleteWordPressScreenHelpTapped = "migration_please_delete_wordpress_screen_help_tapped"
    case pleaseDeleteWordPressScreenCloseTapped = "migration_please_delete_wordpress_screen_close_tapped"

    // WordPress Migratable Stat
    case wordPressDetected = "migration_wordpressapp_detected"
}
