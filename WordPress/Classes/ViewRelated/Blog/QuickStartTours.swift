import Gridicons

protocol QuickStartTour {
    typealias WayPoint = (element: QuickStartTourElement, description: NSAttributedString)

    var key: String { get }
    var title: String { get }
    var titleMarkedCompleted: String { get } // assists VoiceOver users
    var analyticsKey: String { get }
    var description: String { get }
    var icon: UIImage { get }
    var suggestionNoText: String { get }
    var suggestionYesText: String { get }
    var waypoints: [WayPoint] { get }
    var accessibilityHintText: String { get }
    var showWaypointNotices: Bool { get }
}

extension QuickStartTour {
    var waypoints: [WayPoint] {
        get {
            return []
        }
    }

    var showWaypointNotices: Bool {
        get {
            return true
        }
    }
}

private struct Strings {
    static let notNow = NSLocalizedString("Not now", comment: "Phrase displayed to dismiss a quick start tour suggestion.")
    static let yesShowMe = NSLocalizedString("Yes, show me", comment: "Phrase displayed to begin a quick start tour that's been suggested.")
}

struct QuickStartChecklistTour: QuickStartTour {
    let key = "quick-start-checklist-tour"
    let analyticsKey = "view_list"
    let title = NSLocalizedString("Continue with site setup", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Continue with site setup", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Time to finish setting up your site! Our checklist walks you through the next steps.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.external)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to see your checklist", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Quick Start", comment: "The menu item to select during a guided tour.")
        return [(element: .checklist, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.listCheckmark)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of setting up your site.", comment: "This value is used to set the accessibility hint text for setting up the user's site.")
}

struct QuickStartCreateTour: QuickStartTour {
    let key = "quick-start-create-tour"
    let analyticsKey = "create_site"
    let title = NSLocalizedString("Create your site", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Create your site", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Get your site up and running", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.plus)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    let waypoints: [QuickStartTour.WayPoint] = [(element: .noSuchElement, description: NSAttributedString(string: "This tour should never display as interactive."))]

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating your site.", comment: "This value is used to set the accessibility hint text for creating the user's site.")
}

struct QuickStartViewTour: QuickStartTour {
    let key = "quick-start-view-tour"
    let analyticsKey = "view_site"
    let title = NSLocalizedString("View your site", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: View your site", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Preview your new site to see what your visitors will see.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.external)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to preview", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("View Site", comment: "The menu item to select during a guided tour.")
        return [(element: .viewSite, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.house)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of previewing your site.", comment: "This value is used to set the accessibility hint text for previewing a user's site.")
}

struct QuickStartThemeTour: QuickStartTour {
    let key = "quick-start-theme-tour"
    let analyticsKey = "browse_themes"
    let title = NSLocalizedString("Choose a theme", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Choose a theme", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Browse all our themes to find your perfect fit.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.themes)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to discover new themes", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Themes", comment: "The menu item to select during a guided tour.")
        return [(element: .themes, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.themes)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of choosing a theme for your site.", comment: "This value is used to set the accessibility hint text for choosing a theme for the user's site.")
}

struct QuickStartShareTour: QuickStartTour {
    let key = "quick-start-share-tour"
    let analyticsKey = "share_site"
    let title = NSLocalizedString("Social sharing", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Social sharing", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Automatically share new posts to your social media accounts.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.share)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Select %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step1DescriptionTarget = NSLocalizedString("Sharing", comment: "The menu item to select during a guided tour.")
        let step1: WayPoint = (element: .sharing, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: .gridicon(.share)))

        let step2DescriptionBase = NSLocalizedString("Select the %@ to add your social media accounts", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step2DescriptionTarget = NSLocalizedString("connections", comment: "The menu item to select during a guided tour.")
        let step2: WayPoint = (element: .connections, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: nil))

        return [step1, step2]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartPublishTour: QuickStartTour {
    let key = "quick-start-publish-tour"
    let analyticsKey = "publish_post"
    let title = NSLocalizedString("Publish a post", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Publish a post", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Draft and publish a post.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.create)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let showWaypointNotices = false

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to create a new post", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        return [(element: .newpost, description: descriptionBase.highlighting(phrase: "", icon: .gridicon(.create)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of publishing a new post on your site.", comment: "This value is used to set the accessibility hint text for publishing a new post on the user's site.")
}

struct QuickStartFollowTour: QuickStartTour {
    let key = "quick-start-follow-tour"
    let analyticsKey = "follow_site"
    let title = NSLocalizedString("Follow other sites", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Follow other sites", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Find sites that speak to you, and follow them to get updates when they publish.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.readerFollow)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Select %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step1DescriptionTarget = NSLocalizedString("Reader", comment: "The menu item to select during a guided tour.")
        let step1: WayPoint = (element: .readerTab, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: .gridicon(.reader)))

        let step2DescriptionBase = NSLocalizedString("Select %@ to look for sites with similar interests", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step2DescriptionTarget = NSLocalizedString("Search", comment: "The menu item to select during a guided tour.")
        let step2: WayPoint = (element: .readerSearch, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: .gridicon(.search)))

        return [step1, step2]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of following other sites.", comment: "This value is used to set the accessibility hint text for following the sites of other users.")

    func setupReaderTab() {
        guard let tabBar = WPTabBarController.sharedInstance() else {
            return
        }

        tabBar.resetReaderTab()
    }
}

struct QuickStartSiteTitleTour: QuickStartTour {
    let key = "quick-start-site-title-tour"
    let analyticsKey = "site_title"
    let title = NSLocalizedString("Check your site title", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Check your site title", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Give your site a name that reflects its personality and topic. First impressions count!",
                                        comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.pencil)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] {
        let descriptionBase = NSLocalizedString("Select %@ to set a new title.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let placeholder = NSLocalizedString("Site Title", comment: "The item to select during a guided tour.")
        let descriptionTarget = WPTabBarController.sharedInstance()?.currentOrLastBlog()?.title ?? placeholder
        return [(element: .siteTitle, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))]
    }

    let accessibilityHintText = NSLocalizedString("Guides you through the process of setting a title for your site.", comment: "This value is used to set the accessibility hint text for setting the site title.")
}

struct QuickStartSiteIconTour: QuickStartTour {
    let key = "quick-start-site-icon-tour"
    let analyticsKey = "site_icon"
    let title = NSLocalizedString("Choose a unique site icon", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Choose a unique site icon", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Shown in your visitor's browser tab and other places online.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.globe)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to upload a new one.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Your Site Icon", comment: "The item to select during a guided tour.")
        return [(element: .siteIcon, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of uploading an icon for your site.", comment: "This value is used to set the accessibility hint text for uploading a site icon.")
}

struct QuickStartReviewPagesTour: QuickStartTour {
    let key = "quick-start-review-pages-tour"
    let analyticsKey = "review_pages"
    let title = NSLocalizedString("Review site pages", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Review site pages", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Change, add, or remove your site's pages.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.pages)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to see your page list.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Pages", comment: "The item to select during a guided tour.")
        return [(element: .pages, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.pages)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartEditHomepageTour: QuickStartTour {
    let key = "quick-start-edit-homepage-tour"
    let analyticsKey = "edit_homepage"
    let title = NSLocalizedString("Edit your homepage", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Edit your homepage", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Change, add, or remove content from your site's homepage.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.house)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to see your page list.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Pages", comment: "The item to select during a guided tour.")
        let descriptionHomepage = NSLocalizedString("Select %@ to edit your Homepage.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let homepageTarget = NSLocalizedString("Homepage", comment: "The item to select during a guided tour.")
        return [
            (element: .pages, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.pages))),
            (element: .editHomepage, description: descriptionHomepage.highlighting(phrase: homepageTarget, icon: .gridicon(.house)))
        ]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartCheckStatsTour: QuickStartTour {
    let key = "quick-start-check-stats-tour"
    let analyticsKey = "check_stats"
    let title = NSLocalizedString("Check your site stats", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Check your site stats", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Keep up to date on your site’s performance.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.statsAlt)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to see how your site is performing.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Stats", comment: "The item to select during a guided tour.")
        return [(element: .stats, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.stats)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of reviewing statistics for your site.", comment: "This value is used to set the accessibility hint text for viewing Stats on the user's site.")
}

struct QuickStartExplorePlansTour: QuickStartTour {
    let key = "quick-start-explore-plans-tour"
    let analyticsKey = "explore_plans"
    let title = NSLocalizedString("Explore plans", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Explore plans", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Learn about the marketing and SEO tools in our paid plans.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.plans)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to see your current plan and other available plans.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Plan", comment: "The item to select during a guided tour.")
        return [(element: .plans, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.plans)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of exploring plans for your site.", comment: "This value is used to set the accessibility hint text for exploring plans on the user's site.")
}

private let congratsTitle = NSLocalizedString("Congrats on finishing Quick Start  🎉", comment: "Title of a Quick Start Tour")
private let congratsDescription = NSLocalizedString("doesn’t it feel good to cross things off a list?", comment: "subhead shown to users when they complete all Quick Start items")
struct QuickStartCongratulationsTour: QuickStartTour {
    let key = "quick-start-congratulations-tour"
    let analyticsKey = "congratulations"
    let title = congratsTitle
    let titleMarkedCompleted = ""  // Not applicable for this tour type
    let description = congratsDescription
    let icon = UIImage.gridicon(.plus)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    let waypoints: [QuickStartTour.WayPoint] = [(element: .congratulations, description: NSAttributedString(string: congratsTitle))]

    let accessibilityHintText = ""  // Not applicable for this tour type
}

private extension String {
    func highlighting(phrase: String, icon: UIImage?) -> NSAttributedString {
        let normalParts = components(separatedBy: "%@")
        guard normalParts.count > 0 else {
            // if the provided base doesn't contain %@ then we don't know where to place the highlight
            return NSAttributedString(string: self)
        }

        let resultString = NSMutableAttributedString(string: normalParts[0], attributes: [.font: Fonts.regular])

        let highlightStr = NSAttributedString(string: phrase, attributes: [.foregroundColor: Appearance.highlightColor, .font: Fonts.highlight])

        if let icon = icon {
            let iconAttachment = NSTextAttachment()
            iconAttachment.image = icon.withTintColor(Appearance.highlightColor)
            iconAttachment.bounds = CGRect(x: 0.0, y: Fonts.regular.descender + Appearance.iconOffset, width: Appearance.iconSize, height: Appearance.iconSize)
            let iconStr = NSAttributedString(attachment: iconAttachment)

            switch UIView.userInterfaceLayoutDirection(for: .unspecified) {
            case .rightToLeft:
                resultString.append(highlightStr)
                resultString.append(NSAttributedString(string: " "))
                resultString.append(iconStr)
            default:
                resultString.append(iconStr)
                resultString.append(NSAttributedString(string: " "))
                resultString.append(highlightStr)
            }
        } else {
            resultString.append(highlightStr)
        }

        if normalParts.count > 1 {
            resultString.append(NSAttributedString(string: normalParts[1], attributes: [.font: Fonts.regular]))
        }

        return resultString
    }

    private enum Fonts {
        static let regular = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .medium)
        static let highlight = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
    }

    private enum Appearance {
        static let iconOffset: CGFloat = 1.0
        static let iconSize: CGFloat = 16.0
        static var highlightColor: UIColor {
            .invertedLabel
        }
    }
}
