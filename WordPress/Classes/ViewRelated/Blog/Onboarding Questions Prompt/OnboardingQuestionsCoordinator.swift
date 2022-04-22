import Foundation
import UIKit

enum OnboardingOption {
    case stats
    case writing
    case notifications
    case reader
    case showMeAround

    case skip
}

extension NSNotification.Name {
    static let onboardingPromptWasDismissed = NSNotification.Name(rawValue: "OnboardingPromptWasDismissed")
}

class OnboardingQuestionsCoordinator {
    var navigationController: UINavigationController?
    var onDismiss: ((_ selection: OnboardingOption) -> Void)?

    func dismiss(selection: OnboardingOption) {
        onDismiss?(selection)
    }

    func didSelect(option: OnboardingOption) {
        // Check if notification's are already enabled
        // If they are just dismiss, if not then prompt
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { [weak self] settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .notDetermined, let self = self else {
                    self?.dismiss(selection: option)
                    return
                }

                let controller = OnboardingEnableNotificationsViewController(with: self, option: option)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        })
    }
}
