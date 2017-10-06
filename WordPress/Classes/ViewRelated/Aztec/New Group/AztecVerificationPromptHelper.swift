//
//  AztecVerificationPromptHelper.swift
//  WordPress
//
//  Created by Jan Klausa on 05.10.17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

internal class AztecVerificationPromptHelper: NSObject {

    private let managedObjectContext: NSManagedObjectContext
    private let accountService: AccountService
    private let wpComAccount: WPAccount

    private weak var displayedAlert: FancyAlertViewController?

    init?(managedObjectContext: NSManagedObjectContext, for account: WPAccount?) {
        self.managedObjectContext = managedObjectContext
        self.accountService = AccountService(managedObjectContext: managedObjectContext)

        guard let wpComAccount = self.accountService.defaultWordPressComAccount(),
                  wpComAccount == account,
                  !(wpComAccount.emailVerified.boolValue) else {
                    // if the post the user is trying to compose isn't on a WP.com account,
                    // or they're already verified, then the verification prompt is irrelevant.
                return nil
        }

        self.wpComAccount = wpComAccount

        super.init()

        NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] _ in
            self?.updateVerificationStatus()
        }
    }

    func neeedsVerification(before action: PostEditorAction) -> Bool {
        guard action == .publish else {
            return false
        }


        return !wpAccount.emailVerified.boolValue
        return !wpComAccount.emailVerified.boolValue
    }

    func displayVerificationPrompt(from presentingViewController: UIViewController,
                                   then: @escaping () -> ()) {


        let fancyAlert = FancyAlertViewController.verificationPromptController(completion: then)
    
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = self
        presentingViewController.present(fancyAlert, animated: true)

        displayedAlert = fancyAlert
    }

    func updateVerificationStatus() {

        accountService.updateUserDetails(for: wpComAccount,
                                         success: { [weak self] in

                                            guard let updatedAccount = self?.accountService.defaultWordPressComAccount(),
                                                     updatedAccount.emailVerified.boolValue else { return }

                                            self?.displayedAlert?.dismiss(animated: true, completion: nil)
            }, failure: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - UIViewControllerTransitioningDelegate
//
extension AztecVerificationPromptHelper: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented is FancyAlertViewController {
            return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
        }

        return nil
    }
}
