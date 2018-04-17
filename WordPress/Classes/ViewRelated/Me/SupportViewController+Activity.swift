import Foundation

extension SupportViewController {
    @objc func createUserActivity() {
        // Set the userActivity property of UIResponder
        userActivity = WPActivityType.createUserActivity(with: .support)
    }
}
