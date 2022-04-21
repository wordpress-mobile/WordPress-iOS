import Foundation

protocol QuickStartToursCollection {
    var title: String { get }
    var hint: String { get }
    var completedImageName: String { get }
    var analyticsKey: String { get }
    var tours: [QuickStartTour] { get }

    init(blog: Blog)
}

struct QuickStartCustomizeToursCollection: QuickStartToursCollection {
    let title: String
    let hint: String
    let completedImageName: String
    let analyticsKey: String
    let tours: [QuickStartTour]

    init(blog: Blog) {
        self.title = NSLocalizedString("Customize Your Site",
                                      comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        self.hint = NSLocalizedString("A series of steps showing you how to add a theme, site icon and more.",
                                     comment: "A VoiceOver hint to explain what the user gets when they select the 'Customize Your Site' button.")
        self.completedImageName = "wp-illustration-tasks-complete-site"
        self.analyticsKey = "customize"
        self.tours = [
            QuickStartCreateTour(),
            QuickStartSiteTitleTour(blog: blog),
            QuickStartSiteIconTour(),
            QuickStartEditHomepageTour(),
            QuickStartReviewPagesTour(),
            QuickStartViewTour(blog: blog)
        ]
    }
}

struct QuickStartGrowToursCollection: QuickStartToursCollection {
    let title: String
    let hint: String
    let completedImageName: String
    let analyticsKey: String
    let tours: [QuickStartTour]

    init(blog: Blog) {
        self.title = NSLocalizedString("Grow Your Audience",
                                      comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        self.hint = NSLocalizedString("A series of steps to assist with growing your site's audience.",
                                     comment: "A VoiceOver hint to explain what the user gets when they select the 'Grow Your Audience' button.")
        self.completedImageName = "wp-illustration-tasks-complete-audience"
        self.analyticsKey = "grow"
        self.tours = [
            QuickStartShareTour(),
            QuickStartPublishTour(),
            QuickStartFollowTour(),
            QuickStartCheckStatsTour()
    // Temporarily disabled
    //        QuickStartExplorePlansTour()
        ]
    }
}

struct QuickStartGetToKnowAppCollection: QuickStartToursCollection {
    let title: String
    let hint: String
    let completedImageName: String
    let analyticsKey: String
    let tours: [QuickStartTour]

    init(blog: Blog) {
        self.title = NSLocalizedString("Get to know the WordPress app",
                                      comment: "Name of the Quick Start list that guides users through a few tasks to explore the WordPress app.")
        self.hint = NSLocalizedString("A series of steps helping you to explore the app.",
                                     comment: "A VoiceOver hint to explain what the user gets when they select the 'Get to know the WordPress app' button.")
        self.completedImageName = "wp-illustration-tasks-complete-site" // TODO: Could be changed
        self.analyticsKey = "get-to-know"
        self.tours = [
            QuickStartCheckStatsTour(),
            QuickStartViewTour(blog: blog),
            QuickStartFollowTour()
        ]
    }
}
