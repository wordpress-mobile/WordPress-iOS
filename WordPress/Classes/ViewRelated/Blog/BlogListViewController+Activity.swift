import Foundation

extension BlogListViewController {
    @objc func createUserActivity() {
        // Set the userActivity property of UIResponder
        userActivity = WPActivityType.createUserActivity(with: .siteList)
    }
}
