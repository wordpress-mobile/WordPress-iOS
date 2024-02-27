import Foundation

extension MySiteViewController {
    func startObservingOnboardingPrompt() {
        NotificationCenter.default.addObserver(self, selector: #selector(onboardingPromptWasDismissed(_:)), name: .onboardingPromptWasDismissed, object: nil)
    }

    @objc func onboardingPromptWasDismissed(_ notification: NSNotification) {
        guard
            let userInfo = notification.userInfo,
            let option = userInfo["option"] as? OnboardingOption
        else {
            return
        }

        switch option {
        case .stats:
            // Show the stats view for the current blog
            if let blog = blog {
                RootViewCoordinator.sharedPresenter.mySitesCoordinator.showStats(for: blog, source: .onboarding, timePeriod: .insights)
            }
        case .writing:
            // Open the editor
            let presenter = RootViewCoordinator.sharedPresenter
            presenter.showPostTab(completion: { [weak self] in
                self?.startAlertTimer()
            })

        case .showMeAround:
            // Start the quick start
            if let blog = blog {
                QuickStartTourGuide.shared.setup(for: blog, type: .existingSite)
            }

        case .skip, .reader, .notifications:
            // Skip: Do nothing
            // Reader and notifications will be handled by:
            // WPAuthenticationManager.handleOnboardingQuestionsWillDismiss
            break
        }
    }
}
