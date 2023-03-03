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

    var buttonTitle: String {
        switch source {
        case .dashboardCard:
            fallthrough
        case .menuItem:
            return Strings.blazeButtonTitle
        case .postsList:
            fallthrough
        case .pagesList:
            return Strings.blazePostButtonTitle
        }
    }

    func bulletedDescription(font: UIFont, textColor: UIColor) -> NSAttributedString {
        let bullet = "•  "

        var descriptions: [String] = [
            Strings.description1,
            Strings.description2,
            Strings.description3
        ]
        var mappedDescriptions = descriptions.map { return bullet + $0 }

        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = font
        attributes[.foregroundColor] = textColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = (bullet as NSString).size(withAttributes: attributes).width
        attributes[.paragraphStyle] = paragraphStyle

        let string = mappedDescriptions.joined(separator: "\n\n")
        return  NSAttributedString(string: string, attributes: attributes)
    }

    private enum Strings {
        static let title = NSLocalizedString("blaze.overlay.title", value: "Drive more traffic to your site with Blaze", comment: "Title for the Blaze overlay.")

        static let description1 = NSLocalizedString("blaze.overlay.descriptionOne", value: "Promote any post or page in only a few minutes for just a few dollars a day.", comment: "Description for the Blaze overlay.")
        static let description2 = NSLocalizedString("blaze.overlay.descriptionTwo", value: "Your content will appear on millions of WordPress and Tumblr sites.", comment: "Description for the Blaze overlay.")
        static let description3 = NSLocalizedString("blaze.overlay.descriptionThree", value: "Track your campaigns performance and cancel at anytime.", comment: "Description for the Blaze overlay.")

        static let blazeButtonTitle = NSLocalizedString("blaze.overlay.buttonTitle", value: "Blaze a post now", comment: "Button title for a Blaze overlay prompting users to select a post to blaze.")
        static let blazePostButtonTitle = NSLocalizedString("blaze.overlay.withPost.buttonTitle", value: "Blaze this post", comment: "Button title for the Blaze overlay prompting users to blaze the selected post.")
    }
}
