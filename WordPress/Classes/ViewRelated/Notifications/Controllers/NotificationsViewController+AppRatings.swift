import StoreKit

// MARK: - App Ratings
//
extension NotificationsViewController {
    static let contactURL = "https://support.wordpress.com/contact/"

    func setupAppRatings() {
        inlinePromptView.setupHeading(AppConstants.AppRatings.prompt)
        let yesTitle = NSLocalizedString("notifications.appRatings.prompt.yes.buttonTitle", value: "I like it",
                                         comment: "This is one of the buttons we display inside of the prompt to review the app")
        let noTitle = NSLocalizedString("notifications.appRatings.prompt.no.buttonTitle", value: "Could improve",
                                        comment: "This is one of the buttons we display inside of the prompt to review the app")

        inlinePromptView.setupYesButton(title: yesTitle) { [weak self] button in
            self?.likedApp()
        }

        inlinePromptView.setupNoButton(title: noTitle) { [weak self] button in
            self?.dislikedApp()
        }

        AppRatingUtility.shared.userWasPromptedToReview()
        WPAnalytics.track(.appReviewsSawPrompt)
    }

    private func likedApp() {
        defer {
            WPAnalytics.track(.appReviewsLikedApp)
        }
        AppRatingUtility.shared.likedCurrentVersion()

        // 1. Show the thank-you, then hide it after a few seconds
        hideInlinePrompt(delay: 3.0)
        inlinePromptView.showBigHeading(title: NSLocalizedString("Great!\n We love to hear from happy users \n😁",
                                                                 comment: "This is the text we display to the user after they've indicated they like the app"))

        // 2. Show the app store ratings alert
        // Note: Optimistically assuming our prompting succeeds since we try to stay
        // in line and not prompt more than two times a year
        AppRatingUtility.shared.ratedCurrentVersion()
        DispatchQueue.main.async {
            SKStoreReviewController.requestReview()
        }
    }

    private func dislikedApp() {
        defer {
            WPAnalytics.track(.appReviewsDidntLikeApp)
        }
        AppRatingUtility.shared.dislikedCurrentVersion()

        // Let's try to find out why they don't like the app
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.inlinePromptView.setupHeading(NSLocalizedString("Could you tell us how we could improve?",
                                                                  comment: "This is the text we display to the user when we ask them for a review and they've indicated they don't like the app"))
            let yesTitle = NSLocalizedString("notifications.appRatings.sendFeedback.yes.buttonTitle", value: "Send feedback",
                                             comment: "This is one of the buttons we display when prompting the user for a review")
            let noTitle = NSLocalizedString("notifications.appRatings.sendFeedback.no.buttonTitle", value: "No thanks",
                                            comment: "This is one of the buttons we display when prompting the user for a review")
            self?.inlinePromptView.setupYesButton(title: yesTitle) { [weak self] button in
                self?.gatherFeedback()
            }
            self?.inlinePromptView.setupNoButton(title: noTitle) { [weak self] button in
                self?.dismissRatingsPrompt()
            }
        }
    }

    private func gatherFeedback() {
        WPAnalytics.track(.appReviewsOpenedFeedbackScreen)
        AppRatingUtility.shared.gaveFeedbackForCurrentVersion()
        hideInlinePrompt(delay: 0.0)

        if ZendeskUtils.zendeskEnabled {
            ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: self, with: .inAppFeedback)
        } else {
            if let contact = URL(string: NotificationsViewController.contactURL) {
                UIApplication.shared.open(contact)
            }
        }
    }

    private func dismissRatingsPrompt() {
        WPAnalytics.track(.appReviewsDeclinedToRateApp)
        AppRatingUtility.shared.declinedToRateCurrentVersion()
        hideInlinePrompt(delay: 0.0)
    }
}
