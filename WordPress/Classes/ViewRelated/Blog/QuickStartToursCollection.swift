import Foundation

enum QuickStartType {
    case newUser
    case existingUser
}

struct QuickStartToursCollection {
    let title: String
    let hint: String
    let completedImageName: String
    let analyticsKey: String
    let tours: [QuickStartTour]

    private static func customizeToursCollection(blog: Blog) -> QuickStartToursCollection {
        let title = NSLocalizedString("Customize Your Site",
                                      comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        let hint = NSLocalizedString("A series of steps showing you how to add a theme, site icon and more.",
                                     comment: "A VoiceOver hint to explain what the user gets when they select the 'Customize Your Site' button.")
        let completedImageName = "wp-illustration-tasks-complete-site"
        let analyticsKey = "customize"
        let tours: [QuickStartTour] = [
            QuickStartCreateTour(),
            QuickStartSiteTitleTour(blog: blog),
            QuickStartSiteIconTour(),
            QuickStartEditHomepageTour(),
            QuickStartReviewPagesTour(),
            QuickStartViewTour(blog: blog)
        ]
        return QuickStartToursCollection(title: title, hint: hint, completedImageName: completedImageName, analyticsKey: analyticsKey, tours: tours)
    }

    private static func growToursCollection() -> QuickStartToursCollection {
        let title = NSLocalizedString("Grow Your Audience",
                                      comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        let hint = NSLocalizedString("A series of steps to assist with growing your site's audience.",
                                     comment: "A VoiceOver hint to explain what the user gets when they select the 'Grow Your Audience' button.")
        let completedImageName = "wp-illustration-tasks-complete-audience"
        let analyticsKey = "grow"
        let tours: [QuickStartTour] = [
            QuickStartShareTour(),
            QuickStartPublishTour(),
            QuickStartFollowTour(),
            QuickStartCheckStatsTour()
    // Temporarily disabled
    //        QuickStartExplorePlansTour()
        ]
        return QuickStartToursCollection(title: title, hint: hint, completedImageName: completedImageName, analyticsKey: analyticsKey, tours: tours)
    }

    static func collections(for blog: Blog) -> [QuickStartToursCollection] {
        // TODO: Save QuickStartType in blog. Retrieve it here and return collections accordingly
        return [customizeToursCollection(blog: blog), growToursCollection()]
    }
}
