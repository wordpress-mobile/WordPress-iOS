/// dependency container for the What's New / Feature Announcements scene
extension WPTabBarController {

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView)
    }

    private func makeWhatIsNewView() -> WhatIsNewView {

        var version = ""
        if let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            version = NSLocalizedString("Version ", comment: "") + versionNumber
        }

        let textContent = WhatIsNewTextContent(title: NSLocalizedString("What's New in WordPress",
                                                                        comment: "Title of the What's new page."),
                                               version: version,
                                               moreContentButtonTitle: NSLocalizedString("Find out more",
                                                                                         comment: "Title for the Find out more button in the What's new page."),
                                               continueButtonTitle: NSLocalizedString("Continue",
                                                                                      comment: "Title for the continue button in the What's New page."))

        return WhatIsNewView(textContent: textContent)
    }
}
