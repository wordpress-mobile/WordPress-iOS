import Gridicons

protocol QuickStartTour {
    typealias WayPoint = (element: QuickStartTourElement, description: NSAttributedString)

    var key: String { get }
    var title: String { get }
    var analyticsKey: String { get }
    var description: String { get }
    var icon: UIImage { get }
    var suggestionNoText: String { get }
    var suggestionYesText: String { get }
    var waypoints: [WayPoint] { get }
    var accessibilityHintText: String { get }
}

extension QuickStartTour {
    var waypoints: [WayPoint] {
        get {
            return []
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
    let description = NSLocalizedString("Time to finish setting up your site! Our checklist walks you through the next steps.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.external)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Tap %@ to see your checklist", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let descriptionTarget = NSLocalizedString("Quick Start", comment: "The menu item to tap during a guided tour.")
        return [(element: .checklist, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.listCheckmark)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of setting up your site.", comment: "This value is used to set the accessibility hint text for setting up the user's site.")
}

struct QuickStartCreateTour: QuickStartTour {
    let key = "quick-start-create-tour"
    let analyticsKey = "create_site"
    let title = NSLocalizedString("Create your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Get your site up and running", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.plus)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    let waypoints: [QuickStartTour.WayPoint] = [(element: .noSuchElement, description: NSAttributedString(string: "This tour should never display as interactive."))]

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating your site.", comment: "This value is used to set the accessibility hint text for creating the user's site.")
}

/// This is used to track when users from v1 are shown the v2 upgrade notice
/// This should also be created when a site is setup for v2
struct QuickStartUpgradeToV2Tour: QuickStartTour {
    let key = "quick-start-upgrade-to-v2"
    let analyticsKey = "upgrade_to_v2"
    let title = ""
    let description = ""
    let icon = UIImage.gridicon(.plus)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    let waypoints: [QuickStartTour.WayPoint] = []

    let accessibilityHintText = ""  // not applicable for this tour type
}

struct QuickStartViewTour: QuickStartTour {
    let key = "quick-start-view-tour"
    let analyticsKey = "view_site"
    let title = NSLocalizedString("View your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Preview your new site to see what your visitors will see.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.external)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Tap %@ to preview", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let descriptionTarget = NSLocalizedString("View Site", comment: "The menu item to tap during a guided tour.")
        return [(element: .viewSite, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.house)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of previewing your site.", comment: "This value is used to set the accessibility hint text for previewing a user's site.")
}

struct QuickStartThemeTour: QuickStartTour {
    let key = "quick-start-theme-tour"
    let analyticsKey = "browse_themes"
    let title = NSLocalizedString("Choose a theme", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Browse all our themes to find your perfect fit.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.themes)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Tap %@ to discover new themes", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let descriptionTarget = NSLocalizedString("Themes", comment: "The menu item to tap during a guided tour.")
        return [(element: .themes, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.themes)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of choosing a theme for your site.", comment: "This value is used to set the accessibility hint text for choosing a theme for the user's site.")
}

struct QuickStartCustomizeTour: QuickStartTour {
    let key = "quick-start-customize-tour"
    let analyticsKey = "customize_site"
    let title = NSLocalizedString("Customize your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Change colors, fonts, and images for a perfectly personalized site.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.customize)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Tap %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let step1DescriptionTarget = NSLocalizedString("Themes", comment: "The menu item to tap during a guided tour.")
        let step1: WayPoint = (element: .themes, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: .gridicon(.themes)))

        let step2DescriptionBase = NSLocalizedString("Tap %@ to start personalising your site", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let step2DescriptionTarget = NSLocalizedString("Customize", comment: "The menu item to tap during a guided tour.")
        let step2: WayPoint = (element: .customize, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: .gridicon(.themes)))

        return [step1, step2]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of customizing your site.", comment: "This value is used to set the accessibility hint text for customizing a user's site.")
}

struct QuickStartShareTour: QuickStartTour {
    let key = "quick-start-share-tour"
    let analyticsKey = "share_site"
    let title = NSLocalizedString("Enable post sharing", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Automatically share new posts to your social media accounts.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.share)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Tap %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let step1DescriptionTarget = NSLocalizedString("Sharing", comment: "The menu item to tap during a guided tour.")
        let step1: WayPoint = (element: .sharing, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: .gridicon(.share)))

        let step2DescriptionBase = NSLocalizedString("Tap the %@ to add your social media accounts", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let step2DescriptionTarget = NSLocalizedString("connections", comment: "The menu item to tap during a guided tour.")
        let step2: WayPoint = (element: .connections, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: nil))

        return [step1, step2]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartPublishTour: QuickStartTour {
    let key = "quick-start-publish-tour"
    let analyticsKey = "publish_post"
    let title = NSLocalizedString("Publish a post", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("It's time! Draft and publish your very first post.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.create)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Tap %@ to create a new post", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        return [(element: .newpost, description: descriptionBase.highlighting(phrase: "", icon: .gridicon(.create)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of publishing a new post on your site.", comment: "This value is used to set the accessibility hint text for publishing a new post on the user's site.")
}

struct QuickStartFollowTour: QuickStartTour {
    let key = "quick-start-follow-tour"
    let analyticsKey = "follow_site"
    let title = NSLocalizedString("Follow other sites", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Find sites that speak to you, and follow them to get updates when they publish.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.readerFollow)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Tap %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let step1DescriptionTarget = NSLocalizedString("Reader", comment: "The menu item to tap during a guided tour.")
        let step1: WayPoint = (element: .readerTab, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: .gridicon(.reader)))

        let step2DescriptionBase = NSLocalizedString("Tap %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let step2DescriptionTarget = NSLocalizedString("Reader", comment: "The menu item to tap during a guided tour.")
        let step2: WayPoint = (element: .readerBack, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: .gridicon(.chevronLeft)))

        let step3DescriptionBase = NSLocalizedString("Tap %@ to look for sites with similar interests", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let step3DescriptionTarget = NSLocalizedString("Search", comment: "The menu item to tap during a guided tour.")
        let step3: WayPoint = (element: .readerSearch, description: step3DescriptionBase.highlighting(phrase: step3DescriptionTarget, icon: .gridicon(.search)))

        return [step1, step2, step3]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of following other sites.", comment: "This value is used to set the accessibility hint text for following the sites of other users.")

    func setupReaderTab() {
        guard let tabBar = WPTabBarController.sharedInstance() else {
            return
        }

        tabBar.resetReaderTab()
    }
}

struct QuickStartSiteIconTour: QuickStartTour {
    let key = "quick-start-site-icon-tour"
    let analyticsKey = "site_icon"
    let title = NSLocalizedString("Upload a site icon", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Your visitors will see your icon in their browser. Add a custom icon for a polished, pro look.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.globe)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Tap %@ to upload a new one.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let descriptionTarget = NSLocalizedString("Your Site Icon", comment: "The item to tap during a guided tour.")
        return [(element: .siteIcon, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of uploading an icon for your site.", comment: "This value is used to set the accessibility hint text for uploading a site icon.")
}

struct QuickStartNewPageTour: QuickStartTour {
    let key = "quick-start-new-page-tour"
    let analyticsKey = "new_page"
    let title = NSLocalizedString("Create a new page", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Add a page for key content — an “About” page is a great start.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.pages)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let pagesStepDesc = NSLocalizedString("Tap %@ to continue.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let pagesStepTarget = NSLocalizedString("Site Pages", comment: "The item to tap during a guided tour.")

        let newStepDesc = NSLocalizedString("Tap %@ to create a new page.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")

        return [
            (element: .pages, description: pagesStepDesc.highlighting(phrase: pagesStepTarget, icon: nil)),
            (element: .newPage, description: newStepDesc.highlighting(phrase: "", icon: .gridicon(.plus)))
        ]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartCheckStatsTour: QuickStartTour {
    let key = "quick-start-check-stats-tour"
    let analyticsKey = "check_stats"
    let title = NSLocalizedString("Check your site stats", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Keep up to date on your site’s performance.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.statsAlt)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Tap %@ to see how your site is performing.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let descriptionTarget = NSLocalizedString("Stats", comment: "The item to tap during a guided tour.")
        return [(element: .stats, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.stats)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of reviewing statistics for your site.", comment: "This value is used to set the accessibility hint text for viewing Stats on the user's site.")
}

struct QuickStartExplorePlansTour: QuickStartTour {
    let key = "quick-start-explore-plans-tour"
    let analyticsKey = "explore_plans"
    let title = NSLocalizedString("Explore plans", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Learn about the marketing and SEO tools in our paid plans.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.plans)
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Tap %@ to see your current plan and other available plans.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to tap.")
        let descriptionTarget = NSLocalizedString("Plan", comment: "The item to tap during a guided tour.")
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

        let highlightStr = NSAttributedString(string: phrase, attributes: [.foregroundColor: Constants.highlightColor, .font: Fonts.highlight])

        if let icon = icon {
            let iconAttachment = NSTextAttachment()
            iconAttachment.image = icon.imageWithTintColor(Constants.highlightColor)
            iconAttachment.bounds = CGRect(x: 0.0, y: Fonts.regular.descender + Constants.iconOffset, width: Constants.iconSize, height: Constants.iconSize)
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

    private enum Constants {
        static let iconOffset: CGFloat = 1.0
        static let iconSize: CGFloat = 16.0
        static let highlightColor: UIColor = .white
    }
}
