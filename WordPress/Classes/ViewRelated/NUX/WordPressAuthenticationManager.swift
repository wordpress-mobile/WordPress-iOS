import Foundation


// MARK: - WordPressAuthenticationManager
//
class WordPressAuthenticationManager {

}


// MARK: - WordPressAuthenticator Delegate
//
extension WordPressAuthenticationManager: WordPressAuthenticatorDelegate {

    /// Indicates whether if the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return true
    }

    /// Returns an instance of SupportViewController, configured to be displayed from a specified Support Source.
    ///
    func supportViewController(from source: WordPressSupportSourceTag) -> UIViewController {
        let supportViewController = SupportViewController()
        supportViewController.sourceTag = source.toSupportSourceTag()

        let navController = UINavigationController(rootViewController: supportViewController)
        navController.navigationBar.isTranslucent = false
        navController.modalPresentationStyle = .formSheet

        return supportViewController
    }
}
