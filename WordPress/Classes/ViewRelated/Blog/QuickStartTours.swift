import Gridicons

protocol QuickStartTour {
    var key: String { get }
    var title: String { get }
    var description: String { get }
    var icon: UIImage { get }
}

fileprivate enum Constants {
    static let iconOffset: CGFloat = 1.0
    static let iconSize: CGFloat = 16.0
    static let highlightColor = WPStyleGuide.lightBlue()
    static var highlightFont: UIFont {
        get {
            return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        }
    }
}


extension QuickStartTour {
    func makeHighlightMessage(base normalString: String, highlight: String, icon: UIImage) -> NSAttributedString {
        let normalParts = normalString.components(separatedBy: "%@")
        guard normalParts.count > 0 else {
            // if the provided base doesn't contain %@ then we don't know where to place the highlight
            return NSAttributedString(string: normalString)
        }
        let resultString = NSMutableAttributedString(string: normalParts[0])

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        let iconAttachment = NSTextAttachment()
        iconAttachment.image = icon.imageWithTintColor(Constants.highlightColor)
        iconAttachment.bounds = CGRect(x: 0.0, y: font.descender + Constants.iconOffset, width: Constants.iconSize, height: Constants.iconSize)
        let iconStr = NSAttributedString(attachment: iconAttachment)

        let highlightStr = NSAttributedString(string: highlight, attributes: [.foregroundColor: Constants.highlightColor, .font: Constants.highlightFont])

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

        if normalParts.count > 1 {
            resultString.append(NSAttributedString(string: normalParts[1]))
        }

        return resultString
    }
}

struct QuickStartCreateTour: QuickStartTour {
    let key = "quick-start-create-tour"
    let title = NSLocalizedString("Create your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Get your site up and running", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.plus)
}

struct QuickStartViewTour: QuickStartTour {
    let key = "quick-start-view-tour"
    let title = NSLocalizedString("View your site", comment: "Title of a Quick Start Tour")
    let description = NSLocalizedString("Preview your new site to see what your visitors will see.", comment: "Description of a Quick Start Tour")
    let icon = Gridicon.iconOfType(.external)
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
    let icon = Gridicon.iconOfType(.customize)
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
    let icon = Gridicon.iconOfType(.readerFollow)
}
