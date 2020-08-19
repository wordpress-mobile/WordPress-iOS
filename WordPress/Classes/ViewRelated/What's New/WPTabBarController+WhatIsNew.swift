/// dependency container for the What's New / Feature Announcements scene
extension WPTabBarController {

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView)
    }

    private func makeWhatIsNewView() -> WhatIsNewView {

        let version = Bundle.main.shortVersionString() != nil ?
            WhatIsNewStrings.versionPrefix + Bundle.main.shortVersionString() : ""

        let textContent = WhatIsNewTextContent(title: WhatIsNewStrings.title,
                                               version: version,
                                               moreContentButtonTitle: WhatIsNewStrings.moreContentButtonTitle,
                                               continueButtonTitle: WhatIsNewStrings.continueButtonTitle)

        return WhatIsNewView(textContent: textContent)
    }

    private enum WhatIsNewStrings {
        static let title = NSLocalizedString("What's New in WordPress", comment: "Title of the What's new page.")
        static let versionPrefix = NSLocalizedString("Version ", comment: "Description for the version label in the What's new page.")
        static let moreContentButtonTitle = NSLocalizedString("Find out more", comment: "Title for the Find out more button in the What's new page.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title for the continue button in the What's New page.")
    }
}
