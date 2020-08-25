
/// dependency container for the What's New / Feature Announcements scene
extension WPTabBarController {

    func makeWhatIsNewViewController() -> WhatIsNewViewController {
        return WhatIsNewViewController(whatIsNewViewFactory: makeWhatIsNewView)
    }

    private func makeWhatIsNewView() -> WhatIsNewView {

        let version = Bundle.main.shortVersionString() != nil ?
            WhatIsNewStrings.versionPrefix + Bundle.main.shortVersionString() : ""

        let viewTitles = WhatIsNewViewTitles(header: WhatIsNewStrings.title,
                                             version: version,
                                             continueButtonTitle: WhatIsNewStrings.continueButtonTitle)

        return WhatIsNewView(viewTitles: viewTitles, dataSource: makeDataSource())
    }

    private func makeDataSource() -> AnnouncementsDataSource {
        return FeatureAnnouncementsDataSource(announcements: WhatIsNewStrings.fakeAnnouncements,
                                              cellTypes: ["announcementCell": AnnouncementCell.self, "findOutMoreCell": FindOutMoreCell.self],
                                              findOutMoreLink: WhatIsNewStrings.temporaryAnnouncementsLink)
    }

    private enum WhatIsNewStrings {
        static let title = NSLocalizedString("What's New in WordPress", comment: "Title of the What's new page.")
        static let versionPrefix = NSLocalizedString("Version ", comment: "Description for the version label in the What's new page.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title for the continue button in the What's New page.")

        // TODO - WHATSNEW: to be removed when the real data come in
        static let fakeAnnouncements = [Announcement(heading: "Heading with a single line",
                                                     subHeading: "Try to write subheadings that run to a max of three lines. See how the icon is centered.",
                                                     image: nil,
                                                     imageUrl: nil),
                                        Announcement(heading: "Heading with a single line",
                                                     subHeading: "Subheading with only one line.",
                                                     image: nil,
                                                     imageUrl: nil),
                                        Announcement(heading: "Try write headings that don't go beyond 2 lines",
                                                     subHeading: "If combined with three lines of subheading this is the longest an item should be.",
                                                     image: nil,
                                                     imageUrl: nil),
                                        Announcement(heading: "Heading with a single line",
                                                     subHeading: "Try to write subheadings that run to a max of three lines. See how the icon is centered.",
                                                     image: nil,
                                                     imageUrl: nil),
                                        Announcement(heading: "Heading with a single line",
                                                     subHeading: "Subheading with only one line.",
                                                     image: nil,
                                                     imageUrl: nil),
                                        Announcement(heading: "Try write headings that don't go beyond 2 lines",
                                                     subHeading: "If combined with three lines of subheading this is the longest an item should be.",
                                                     image: nil,
                                                     imageUrl: nil)]
        // TODO - WHATSNEW: to be removed when the real data come in
        static let temporaryAnnouncementsLink = "https://wordpress.com/"
    }
}
