import Foundation

enum MigrationEvent: String {
    // Email
    case emailTriggered = "migration_email_triggered"
    case emailSent = "migration_email_sent"
    case emailFailed = "migration_email_failed"
}
