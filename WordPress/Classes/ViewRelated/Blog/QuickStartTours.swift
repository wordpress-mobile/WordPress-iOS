import Gridicons

protocol QuickStartTour {
    var key: String { get }
    var title: String { get }
    var description: String { get }
    var icon: UIImage { get }
}

struct QuickStartCreateTour: QuickStartTour {
    let key = "quick-start-create-tour"
    let title = NSLocalizedString("Create your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Get your site up and running", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.globe)
}

struct QuickStartViewTour: QuickStartTour {
    let key = "quick-start-view-tour"
    let title = NSLocalizedString("View your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Preview your new site to see what your visitors will see.", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.globe)
}

struct QuickStartThemeTour: QuickStartTour {
    let key = "quick-start-theme-tour"
    let title = NSLocalizedString("Choose a theme", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Browse all our themes to find your perfect fit.", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.themes)
}

struct QuickStartCustomizeTour: QuickStartTour {
    let key = "quick-start-customize-tour"
    let title = NSLocalizedString("Customize your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Change colors, fonts, and images for a perfectly personalized site.", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.themes)
}

struct QuickStartShareTour: QuickStartTour {
    let key = "quick-start-share-tour"
    let title = NSLocalizedString("Share your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Connect to your social media accounts -- your site will automatically share new posts.", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.share)
}

struct QuickStartPublishTour: QuickStartTour {
    let key = "quick-start-publish-tour"
    let title = NSLocalizedString("Publish a post", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("It's time! Draft and publish your very first post.", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.create)
}

struct QuickStartFollowTour: QuickStartTour {
    let key = "quick-start-follow-tour"
    let title = NSLocalizedString("Follow other sites", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Find sites that speak to you, and follow them to get updates when they publish.", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.reader)
}
