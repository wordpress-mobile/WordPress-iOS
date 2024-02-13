import Gridicons
import Foundation
import UIKit

protocol QuickStartTour {
    typealias WayPoint = (element: QuickStartTourElement, description: NSAttributedString)

    var key: String { get }
    var title: String { get }
    var titleMarkedCompleted: String { get } // assists VoiceOver users
    var analyticsKey: String { get }
    var description: String { get }
    var icon: UIImage { get }
    var iconColor: UIColor { get }
    var suggestionNoText: String { get }
    var suggestionYesText: String { get }
    var waypoints: [WayPoint] { get set }
    var accessibilityHintText: String { get }
    var showWaypointNotices: Bool { get }
    var taskCompleteDescription: NSAttributedString? { get }
    var showDescriptionInQuickStartModal: Bool { get }

    /// Represents where the tour can be shown from.
    var possibleEntryPoints: Set<QuickStartTourEntryPoint> { get }

    var mustBeShownInBlogDetails: Bool { get }
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

    var taskCompleteDescription: NSAttributedString? {
        get {
            return nil
        }
    }

    var mustBeShownInBlogDetails: Bool {
        get {
            return possibleEntryPoints == [.blogDetails]
        }
    }

    var showDescriptionInQuickStartModal: Bool {
        get {
            return false
        }
    }
}

private struct Strings {
    static let notNow = NSLocalizedString("Not now", comment: "Phrase displayed to dismiss a quick start tour suggestion.")
    static let yesShowMe = NSLocalizedString("Yes, show me", comment: "Phrase displayed to begin a quick start tour that's been suggested.")
}

struct QuickStartSiteMenu {
    private static let descriptionBase = NSLocalizedString("Select %@ to continue.", comment: "A step in a guided tour for quick start. %@ will be the name of the segmented control item to select on the Site Menu screen.")
    private static let descriptionTarget = NSLocalizedString("quickStart.moreMenu", value: "More", comment: "The quick tour actions item to select during a guided tour.")
    static let waypoint = QuickStartTour.WayPoint(element: .siteMenu, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))
}

struct QuickStartCreateTour: QuickStartTour {
    let key = "quick-start-create-tour"
    let analyticsKey = "create_site"
    let title = NSLocalizedString("Create your site", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Create your site", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Get your site up and running", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.plus)
    let iconColor = UIColor.systemGray4
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var waypoints: [QuickStartTour.WayPoint] = [(element: .noSuchElement, description: NSAttributedString(string: "This tour should never display as interactive."))]

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating your site.", comment: "This value is used to set the accessibility hint text for creating the user's site.")
}

struct QuickStartViewTour: QuickStartTour {
    let key = "quick-start-view-tour"
    let analyticsKey = "view_site"
    let title = NSLocalizedString("View your site", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: View your site", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Preview your site to see what your visitors will see.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.external)
    let iconColor = UIColor.muriel(color: MurielColor(name: .yellow, shade: .shade20))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var waypoints: [WayPoint]

    let accessibilityHintText = NSLocalizedString("Guides you through the process of previewing your site.", comment: "This value is used to set the accessibility hint text for previewing a user's site.")

    init(blog: Blog) {
        let descriptionBase = NSLocalizedString("Select %@ to view your site", comment: "A step in a guided tour for quick start. %@ will be the site url.")
        let placeholder = NSLocalizedString("Site URL", comment: "The item to select during a guided tour.")
        let descriptionTarget = (blog.displayURL as String?) ?? placeholder

        self.waypoints = [
            (element: .viewSite, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))
        ]
    }
}

struct QuickStartShareTour: QuickStartTour {
    let key = "quick-start-share-tour"
    let analyticsKey = "share_site"
    let title = NSLocalizedString("Social sharing", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Social sharing", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Automatically share new posts to your social media accounts.", comment: "Description of a Quick Start Tour")
    let icon = UIImage(named: "site-menu-social") ?? UIImage()
    let iconColor = UIColor.muriel(color: MurielColor(name: .blue, shade: .shade40)).color(for: UITraitCollection(userInterfaceStyle: .light))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails]

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Select %@ to continue", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step1DescriptionTarget = NSLocalizedString("Social", comment: "The menu item to select during a guided tour.")
        let step1: WayPoint = (element: .sharing, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: UIImage(named: "site-menu-social")))

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
    let iconColor = UIColor.muriel(color: MurielColor(name: .green, shade: .shade30))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let showWaypointNotices = false
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDashboard]

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to create a new post", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        return [(element: .newpost, description: descriptionBase.highlighting(phrase: "", icon: .gridicon(.plus)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of publishing a new post on your site.", comment: "This value is used to set the accessibility hint text for publishing a new post on the user's site.")
}

struct QuickStartFollowTour: QuickStartTour {
    let key = "quick-start-follow-tour"
    let analyticsKey = "follow_site"
    let title = NSLocalizedString("Connect with other sites", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Connect with other sites", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Discover and follow sites that inspire you.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.readerFollow)
    let iconColor = UIColor.muriel(color: MurielColor(name: .pink, shade: .shade40))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Select %@ to find other sites.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step1DescriptionTarget = NSLocalizedString("Reader", comment: "The menu item to select during a guided tour.")
        let step1: WayPoint = (element: .readerTab,
                               description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget,
                                                                              icon: UIImage(named: "tab-bar-reader-selected")))

        let step2DiscoverDescriptionBase = NSLocalizedString("Use %@ to find sites and tags.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step2DiscoverDescriptionTarget = NSLocalizedString("Discover", comment: "The menu item to select during a guided tour.")
        let step2DiscoverDescription = step2DiscoverDescriptionBase.highlighting(phrase: step2DiscoverDescriptionTarget, icon: nil)

        let step2SubscriptionDescriptionBase = NSLocalizedString(
            "quick.start.reader.2.subscriptions.base",
            value: "Try selecting %@ to view subscribed content and manage your subscriptions.",
            comment: "A step in a guided tour for quick start. %@ will be a bolded Subscriptions text."
        )
        let step2SubscriptionDescriptionTarget = NSLocalizedString(
            "quick.start.reader.2.subscriptions.target",
            value: "Subscriptions",
            comment: "The bolded Subscriptions text in the Reader step 2 description for the quick start tour."
        )
        let step2SubscriptionDescription = step2SubscriptionDescriptionBase.highlighting(
            phrase: step2SubscriptionDescriptionTarget,
            icon: nil
        )

        /// Combined description for step 2
        let step2Format = NSAttributedString(string: "%@ %@")
        let step2Description = NSAttributedString(format: step2Format,
                                                  args: step2DiscoverDescription, step2SubscriptionDescription)

        let step2: WayPoint = (element: .readerDiscoverSubscriptions, description: step2Description)

        return [step1, step2]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of following other sites.", comment: "This value is used to set the accessibility hint text for following the sites of other users.")

    func setupReaderTab() {
        RootViewCoordinator.sharedPresenter.resetReaderTab()
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
    let iconColor = UIColor.muriel(color: MurielColor(name: .red, shade: .shade40))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var waypoints: [WayPoint]

    let accessibilityHintText = NSLocalizedString("Guides you through the process of setting a title for your site.", comment: "This value is used to set the accessibility hint text for setting the site title.")

    init(blog: Blog) {
        let descriptionBase = NSLocalizedString("Select %@ to set a new title.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let placeholder = NSLocalizedString("Site Title", comment: "The item to select during a guided tour.")
        let descriptionTarget = blog.title ?? placeholder

        self.waypoints = [
            (element: .siteTitle, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: nil))
        ]
    }
}

struct QuickStartSiteIconTour: QuickStartTour {
    let key = "quick-start-site-icon-tour"
    let analyticsKey = "site_icon"
    let title = NSLocalizedString("Choose a unique site icon", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Choose a unique site icon", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Used across the web: in browser tabs, social media previews, and the WordPress.com Reader.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.globe)
    let iconColor = UIColor.muriel(color: MurielColor(name: .purple, shade: .shade40))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]
    let showDescriptionInQuickStartModal = true

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
    let icon = UIImage(named: "site-menu-pages") ?? UIImage()
    let iconColor = UIColor.muriel(color: MurielColor(name: .celadon, shade: .shade30))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to see your page list.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Pages", comment: "The item to select during a guided tour.")
        return [(element: .pages, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: UIImage(named: "site-menu-pages")))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of creating a new page for your site.", comment: "This value is used to set the accessibility hint text for creating a new page for the user's site.")
}

struct QuickStartCheckStatsTour: QuickStartTour {
    let key = "quick-start-check-stats-tour"
    let analyticsKey = "check_stats"
    let title = NSLocalizedString("Check your site stats", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Check your site stats", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Keep up to date on your site’s performance.", comment: "Description of a Quick Start Tour")
    let icon = UIImage(named: "site-menu-stats") ?? UIImage()
    let iconColor = UIColor.muriel(color: MurielColor(name: .orange, shade: .shade30))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var taskCompleteDescription: NSAttributedString? = {
        let descriptionBase = NSLocalizedString("%@ Return to My Site screen when you're ready for the next task.", comment: "Title of the task complete hint for the Quick Start Tour")
        let descriptionTarget = NSLocalizedString("Task complete.", comment: "A hint about the completed guided tour.")
        return descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.checkmark))
    }()

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select %@ to see how your site is performing.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Stats", comment: "The item to select during a guided tour.")
        return [(element: .stats, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: UIImage(named: "site-menu-stats")))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of reviewing statistics for your site.", comment: "This value is used to set the accessibility hint text for viewing Stats on the user's site.")
}

struct QuickStartNotificationsTour: QuickStartTour {
    let key = "quick-start-notifications-tour"
    let analyticsKey = "notifications"
    let title = NSLocalizedString("Check your notifications", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Check your notifications", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Get real time updates from your pocket.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.bell)
    let iconColor = UIColor.muriel(color: MurielColor(name: .purple, shade: .shade40))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var taskCompleteDescription: NSAttributedString? = {
        let descriptionBase = NSLocalizedString("%@ Tip: get updates faster by enabling push notifications.", comment: "Title of the task complete hint for the Quick Start Tour")
        let descriptionTarget = NSLocalizedString("Task complete.", comment: "A hint about the completed guided tour.")
        return descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.checkmark))
    }()

    var waypoints: [WayPoint] = {
        let descriptionBase = NSLocalizedString("Select the %@ tab to get updates on the go.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let descriptionTarget = NSLocalizedString("Notifications", comment: "The item to select during a guided tour.")
        return [(element: .notifications, description: descriptionBase.highlighting(phrase: descriptionTarget, icon: .gridicon(.bell)))]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of checking your notifications.", comment: "This value is used to set the accessibility hint text for viewing the user's notifications.")
}

struct QuickStartMediaUploadTour: QuickStartTour {
    let key = "quick-start-media-upload-tour"
    let analyticsKey = "media"
    let title = NSLocalizedString("Upload photos or videos", comment: "Title of a Quick Start Tour")
    let titleMarkedCompleted = NSLocalizedString("Completed: Upload photos or videos", comment: "The Quick Start Tour title after the user finished the step.")
    let description = NSLocalizedString("Bring media straight from your device or camera to your site.", comment: "Description of a Quick Start Tour")
    let icon = UIImage.gridicon(.addImage)
    let iconColor = UIColor.muriel(color: MurielColor(name: .celadon, shade: .shade30))
    let suggestionNoText = Strings.notNow
    let suggestionYesText = Strings.yesShowMe
    let possibleEntryPoints: Set<QuickStartTourEntryPoint> = [.blogDetails, .blogDashboard]

    var waypoints: [WayPoint] = {
        let step1DescriptionBase = NSLocalizedString("Select %@ to see your current library.", comment: "A step in a guided tour for quick start. %@ will be the name of the item to select.")
        let step1DescriptionTarget = NSLocalizedString("Media", comment: "The menu item to select during a guided tour.")
        let step1: WayPoint = (element: .mediaScreen, description: step1DescriptionBase.highlighting(phrase: step1DescriptionTarget, icon: UIImage(named: "site-menu-media")))

        let step2DescriptionBase = NSLocalizedString("Select %@to upload media. You can add it to your posts / pages from any device.", comment: "A step in a guided tour for quick start. %@ will be a plus icon.")
        let step2DescriptionTarget = ""
        let step2: WayPoint = (element: .mediaUpload, description: step2DescriptionBase.highlighting(phrase: step2DescriptionTarget, icon: .gridicon(.plus)))

        return [step1, step2]
    }()

    let accessibilityHintText = NSLocalizedString("Guides you through the process of uploading new media.", comment: "This value is used to set the accessibility hint text for viewing the user's notifications.")
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

private extension NSAttributedString {
    convenience init(format: NSAttributedString, args: NSAttributedString...) {
        let mutableNSAttributedString = NSMutableAttributedString(attributedString: format)

        args.forEach { (attributedString) in
            let range = NSString(string: mutableNSAttributedString.string).range(of: "%@")
            mutableNSAttributedString.replaceCharacters(in: range, with: attributedString)
        }
        self.init(attributedString: mutableNSAttributedString)
    }
}
