import Foundation

struct BlazeOverlayViewModel {

    let source: BlazeSource
    let blog: Blog
    let post: AbstractPost?

    var iconName: String {
        return "flame-circle"
    }

    var title: String {
        return Strings.title
    }

    var buttonTitle: NSAttributedString {
        switch source {
        case .dashboardCard:
            fallthrough
        case .menuItem:
            return buttonTitleWithIcon(title: Strings.blazeButtonTitle)
        case .postsList:
            return buttonTitleWithIcon(title: Strings.blazePostButtonTitle)
        case .pagesList:
            return buttonTitleWithIcon(title: Strings.blazePageButtonTitle)
        }
    }

    func bulletedDescription(font: UIFont, textColor: UIColor) -> NSAttributedString {
        let bullet = "•  "

        let descriptions: [String] = [
            Strings.description1,
            Strings.description2,
            Strings.description3
        ]
        let mappedDescriptions = descriptions.map { return bullet + $0 }

        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = font
        attributes[.foregroundColor] = textColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = (bullet as NSString).size(withAttributes: attributes).width
        attributes[.paragraphStyle] = paragraphStyle

        let string = mappedDescriptions.joined(separator: "\n\n")
        return  NSAttributedString(string: string, attributes: attributes)
    }

    private func buttonTitleWithIcon(title: String) -> NSAttributedString {
        let string = NSMutableAttributedString(string: "\(title)  ")

        let imageAttachment = NSTextAttachment()
        imageAttachment.bounds = CGRect(x: 0.0, y: -Metrics.iconOffset, width: Metrics.iconSize, height: Metrics.iconSize)
        let iconSize = CGSize(width: Metrics.iconSize, height: Metrics.iconSize)
        imageAttachment.image = UIImage(named: "icon-blaze")

        let imageString = NSAttributedString(attachment: imageAttachment)
        string.append(imageString)

        return string
    }

    private enum Strings {
        static let title = NSLocalizedString("blaze.overlay.title", value: "Drive more traffic to your site with Blaze", comment: "Title for the Blaze overlay.")

        static let description1 = NSLocalizedString("blaze.overlay.descriptionOne", value: "Promote any post or page in only a few minutes for just a few dollars a day.", comment: "Description for the Blaze overlay.")
        static let description2 = NSLocalizedString("blaze.overlay.descriptionTwo", value: "Your content will appear on millions of WordPress and Tumblr sites.", comment: "Description for the Blaze overlay.")
        static let description3 = NSLocalizedString("blaze.overlay.descriptionThree", value: "Track your campaigns performance and cancel at anytime.", comment: "Description for the Blaze overlay.")

        static let blazeButtonTitle = NSLocalizedString("blaze.overlay.buttonTitle", value: "Blaze a post now", comment: "Button title for a Blaze overlay prompting users to select a post to blaze.")
        static let blazePostButtonTitle = NSLocalizedString("blaze.overlay.withPost.buttonTitle", value: "Blaze this post", comment: "Button title for the Blaze overlay prompting users to blaze the selected post.")
        static let blazePageButtonTitle = NSLocalizedString("blaze.overlay.withPage.buttonTitle", value: "Blaze this page", comment: "Button title for the Blaze overlay prompting users to blaze the selected page.")

    }

    private enum Metrics {
        static let iconSize: CGFloat = 24.0
        static let iconOffset: CGFloat = 5.0
    }
}
