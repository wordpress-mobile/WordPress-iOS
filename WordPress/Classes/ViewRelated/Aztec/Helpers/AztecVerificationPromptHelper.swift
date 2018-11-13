import UIKit


typealias VerificationPromptCompletion = (Bool) -> ()

protocol VerificationPromptHelper {

    func updateVerificationStatus()

    func displayVerificationPrompt(from presentingViewController: UIViewController,
                                   then: VerificationPromptCompletion?)

    func needsVerification(before action: PostEditorAction) -> Bool
}

class AztecVerificationPromptHelper: NSObject, VerificationPromptHelper {

    private let accountService: AccountService
    private let wpComAccount: WPAccount

    private weak var displayedAlert: FancyAlertViewController?
    private var completionBlock: VerificationPromptCompletion?

    @objc init?(account: WPAccount?) {
        guard let passedAccount = account,
              let managedObjectContext = account?.managedObjectContext else {
                return nil
        }

        accountService = AccountService(managedObjectContext: managedObjectContext)

        guard accountService.isDefaultWordPressComAccount(passedAccount),
              passedAccount.needsEmailVerification else {
                // if the post the user is trying to compose isn't on a WP.com account,
                // or they're already verified, then the verification prompt is irrelevant.
                return nil
        }

        wpComAccount = passedAccount

        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateVerificationStatus),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func needsVerification(before action: PostEditorAction) -> Bool {
        guard action == .publish else {
            return false
        }

        return wpComAccount.needsEmailVerification
    }

    /// - parameter presentingViewController: UIViewController that the prompt should be presented from.
    /// - parameter then: Completion callback to be called after the user dismisses the prompt.
    /// **Note**: The callback fires only when the user tapped "OK" or we silently verified the account in background. It isn't fired when user attempts to resend the verification email.
    @objc func displayVerificationPrompt(from presentingViewController: UIViewController,
                                         then: VerificationPromptCompletion?) {

        let fancyAlert = FancyAlertViewController.verificationPromptController { [weak self] in
            let needsVerification = self?.wpComAccount.needsEmailVerification ?? true
            then?(!needsVerification)
        }

        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = self
        presentingViewController.present(fancyAlert, animated: true)

        updateVerificationStatus()
        // Silently kick off the request to make sure the user still actually needs to be verified.
        // If in the meantime user has been verified, we'll dismiss the prompt,
        // call the completion block and let caller handle the new situation.

        displayedAlert = fancyAlert
        completionBlock = then
    }

    @objc func updateVerificationStatus() {
        accountService.updateUserDetails(for: wpComAccount,
                                         success: { [weak self] in

                                            // Let's make sure the alert is still on the screen and
                                            // the verification status has changed, before we call the callback.
                                            guard let displayedAlert = self?.displayedAlert,
                                                  let updatedAccount = self?.accountService.defaultWordPressComAccount(),
                                                  !updatedAccount.needsEmailVerification else {
                                                        return
                                            }

                                            displayedAlert.dismiss(animated: true, completion: nil)
                                            self?.completionBlock?(!updatedAccount.needsEmailVerification)
            }, failure: nil)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
//
extension AztecVerificationPromptHelper: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
