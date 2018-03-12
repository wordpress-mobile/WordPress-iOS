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

        return navController
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, epilogueInfo: LoginEpilogueUserInfo? = nil, isJetpackLogin: Bool, onDismiss: @escaping () -> Void) {
        let storyboard = UIStoryboard(name: "LoginEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? LoginEpilogueViewController else {
            fatalError()
        }

        epilogueViewController.epilogueUserInfo = epilogueInfo
        epilogueViewController.jetpackLogin = isJetpackLogin
        epilogueViewController.onDismiss = onDismiss

        navigationController.pushViewController(epilogueViewController, animated: true)
    }
}
