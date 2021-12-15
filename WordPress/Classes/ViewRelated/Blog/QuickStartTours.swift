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
    static let notNow = AppLocalizedString("Not now", comment: "Phrase displayed to dismiss a quick start tour suggestion.")
    static let yesShowMe = AppLocalizedString("Yes, show me", comment: "Phrase displayed to begin a quick start tour that's been suggested.")
}

struct QuickStartChecklistTour: QuickStartTour {
    let key = "quick-start-checklist-tour"
    let analyticsKey = "view_list"
    let title = AppLocalizedString("Continue with site setup", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Continue with site setup", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Time to finish setting up your site! Our checklist walks you through the next steps.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.external)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to see your checklist", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("Quick Start", comment: "The menu item to select during a guided tour.")
        return [(element: .checklist, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.listCheckmark)))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of setting up your site.", comment: "This value is used to set the accessibility hint text for setting up the user's site.")
}

struct QuickStartCreateTour: QuickStartTour {
    let key = "quick-start-create-tour"
    let analyticsKey = "create_site"
    let title = AppLocalizedString("Create your site", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Create your site", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Get your site up and running", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.plus)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    let waypoints: [QuickStartTour.WayPoint] = [(element: .noSuchElement, description: NSAttributedString(string: "This tour should never display as interactive."))]

    let accessibilityHintText = AppLocalizedString("Guides you through the process of creating your site.", comment: "This value is used to set the accessibility hint text for creating the user's site.")
}

struct QuickStartViewTour: QuickStartTour {
    let key = "quick-start-view-tour"
    let analyticsKey = "view_site"
    let title = AppLocalizedString("View your site", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: View your site", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Preview your new site to see what your visitors will see.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.external)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to preview", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("View Site", comment: "The menu item to select during a guided tour.")
        return [(element: .viewSite, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.house)))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of previewing your site.", comment: "This value is used to set the accessibility hint text for previewing a user's site.")
}

struct QuickStartThemeTour: QuickStartTour {
    let key = "quick-start-theme-tour"
    let analyticsKey = "browse_themes"
    let title = AppLocalizedString("Choose a theme", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Choose a theme", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Browse all our themes to find your perfect fit.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.themes)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to discover new themes", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("Themes", comment: "The menu item to select during a guided tour.")
        return [(element: .themes, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.themes)))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of choosing a theme for your site.", comment: "This value is used to set the accessibility hint text for choosing a theme for the user's site.")
}

struct QuickStartShareTour: QuickStartTour {
    let key = "quick-start-share-tour"
    let analyticsKey = "share_site"
    let title = AppLocalizedString("Social sharing", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Social sharing", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Automatically share new posts to your social media accounts.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.share)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = AppLocalizedString("Select %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step1DescriptionTarget = AppLocalizedString("Sharing", comment: "The menu item to select during a guided tour.")
        let step1: WayPoint = (element: .sharing, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: .gridicon(.share)))

        let step2DescriptionBase = AppLocalizedString("Select the %@ to add your social media accounts", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step2DescriptionTarget = AppLocalizedString("connections", comment: "The menu item to select during a guided tour.")
        let step2: WayPoint = (element: .connections, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: nil))

        return [step1, step2]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartPublishTour: QuickStartTour {
    let key = "quick-start-publish-tour"
    let analyticsKey = "publish_post"
    let title = AppLocalizedString("Publish a post", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Publish a post", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Draft and publish a post.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.create)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let showWaypointNotices = false

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to create a new post", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        return [(element: .newpost, description: descriptionBase.highlighting(phrase: "", icon: .gridicon(.create)))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of publishing a new post on your site.", comment: "This value is used to set the accessibility hint text for publishing a new post on the user's site.")
}

struct QuickStartFollowTour: QuickStartTour {
    let key = "quick-start-follow-tour"
    let analyticsKey = "follow_site"
    let title = AppLocalizedString("Follow other sites", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Follow other sites", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Find sites that speak to you, and follow them to get updates when they publish.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.readerFollow)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = AppLocalizedString("Select %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step1DescriptionTarget = AppLocalizedString("Reader", comment: "The menu item to select during a guided tour.")
        let step1: WayPoint = (element: .readerTab, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: .gridicon(.reader)))

        let step2DescriptionBase = AppLocalizedString("Select %@ to look for sites with similar interests", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step2DescriptionTarget = AppLocalizedString("Search", comment: "The menu item to select during a guided tour.")
        let step2: WayPoint = (element: .readerSearch, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: .gridicon(.search)))

        return [step1, step2]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of following other sites.", comment: "This value is used to set the accessibility hint text for following the sites of other users.")

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
    let title = AppLocalizedString("Check your site title", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Check your site title", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Give your site a name that reflects its personality and topic. First impressions count!",
                                        comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.pencil)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] {
        let descriptionBase = AppLocalizedString("Select %@ to set a new title.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let placeholder = AppLocalizedString("Site Title", comment: "The item to select during a guided tour.")
        let descriptionTarget = WPTabBarController.sharedInstance()?.currentOrLastBlog()?.title ?? placeholder
        return [(element: .siteTitle, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))]
    }

    let accessibilityHintText = AppLocalizedString("Guides you through the process of setting a title for your site.", comment: "This value is used to set the accessibility hint text for setting the site title.")
}

struct QuickStartSiteIconTour: QuickStartTour {
    let key = "quick-start-site-icon-tour"
    let analyticsKey = "site_icon"
    let title = AppLocalizedString("Choose a unique site icon", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Choose a unique site icon", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Shown in your visitor's browser tab and other places online.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.globe)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to upload a new one.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("Your Site Icon", comment: "The item to select during a guided tour.")
        return [(element: .siteIcon, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of uploading an icon for your site.", comment: "This value is used to set the accessibility hint text for uploading a site icon.")
}

struct QuickStartReviewPagesTour: QuickStartTour {
    let key = "quick-start-review-pages-tour"
    let analyticsKey = "review_pages"
    let title = AppLocalizedString("Review site pages", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Review site pages", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Change, add, or remove your site's pages.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.pages)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to see your page list.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("Pages", comment: "The item to select during a guided tour.")
        return [(element: .pages, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.pages)))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartEditHomepageTour: QuickStartTour {
    let key = "quick-start-edit-homepage-tour"
    let analyticsKey = "edit_homepage"
    let title = AppLocalizedString("Edit your homepage", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Edit your homepage", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Change, add, or remove content from your site's homepage.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.house)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to see your page list.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("Pages", comment: "The item to select during a guided tour.")
        let descriptionHomepage = AppLocalizedString("Select %@ to edit your Homepage.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let homepageTarget = AppLocalizedString("Homepage", comment: "The item to select during a guided tour.")
        return [
            (element: .pages, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.pages))),
            (element: .editHomepage, description: descriptionHomepage.highlighting(phrase: homepageTarget, icon: .gridicon(.house)))
        ]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartCheckStatsTour: QuickStartTour {
    let key = "quick-start-check-stats-tour"
    let analyticsKey = "check_stats"
    let title = AppLocalizedString("Check your site stats", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Check your site stats", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Keep up to date on your site’s performance.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.statsAlt)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to see how your site is performing.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("Stats", comment: "The item to select during a guided tour.")
        return [(element: .stats, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.stats)))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of reviewing statistics for your site.", comment: "This value is used to set the accessibility hint text for viewing Stats on the user's site.")
}

struct QuickStartExplorePlansTour: QuickStartTour {
    let key = "quick-start-explore-plans-tour"
    let analyticsKey = "explore_plans"
    let title = AppLocalizedString("Explore plans", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = AppLocalizedString("Completed: Explore plans", comment: "The Quick Start Tour title after the user finished the step.")
    let description = AppLocalizedString("Learn about the marketing and SEO tools in our paid plans.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.plans)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = AppLocalizedString("Select %@ to see your current plan and other available plans.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = AppLocalizedString("Plan", comment: "The item to select during a guided tour.")
        return [(element: .plans, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.plans)))]
    }()

    let accessibilityHintText = AppLocalizedString("Guides you through the process of exploring plans for your site.", comment: "This value is used to set the accessibility hint text for exploring plans on the user's site.")
}

private let congratsTitle = AppLocalizedString("Congrats on finishing Quick Start  🎉", comment: "Title of a Quick Start Tour")
private let congratsDescription = AppLocalizedString("doesn’t it feel good to cross things off a list?", comment: "subhead shown to users when they complete all Quick Start items")
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
