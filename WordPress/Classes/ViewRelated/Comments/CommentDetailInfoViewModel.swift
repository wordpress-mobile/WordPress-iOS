import Foundation

protocol CommentDetailInfoViewModelInputs {
    func didSelectItem(at index: Int)
}

protocol CommentDetailInfoViewModelOutputs {
    func fetchUserDetails() -> [CommentDetailInfoUserDetails]
}

typealias CommentDetailInfoViewModelType = CommentDetailInfoViewModelInputs & CommentDetailInfoViewModelOutputs

struct CommentDetailInfoUserDetails {
    let title: String
    let description: String
}

final class CommentDetailInfoViewModel: CommentDetailInfoViewModelType {
    private let url: URL?
    private let urlToDisplay: String?
    private let email: String?
    private let ipAddress: String?
    private let isAdmin: Bool

    weak var view: CommentDetailInfoView?

    init(url: URL?, urlToDisplay: String?, email: String?, ipAddress: String?, isAdmin: Bool) {
        self.url = url
        self.urlToDisplay = urlToDisplay
        self.email = email
        self.ipAddress = ipAddress
        self.isAdmin = isAdmin
    }

    func fetchUserDetails() -> [CommentDetailInfoUserDetails] {
        var details: [CommentDetailInfoUserDetails] = []
        // Author URL is publicly visible, but let's hide the row if it's empty or contains invalid URL.
        if let urlToDisplay = urlToDisplay, !urlToDisplay.isEmpty {
            details.append(CommentDetailInfoUserDetails(title: Strings.addressLabelText, description: urlToDisplay))
        }

        // Email address and IP address fields are only visible for Editor or Administrator roles, i.e. when user is allowed to moderate the comment.
        if isAdmin {
            // If the comment is submitted anonymously, the email field may be empty. In this case, let's hide it. Ref: https://git.io/JzKIt
            if let email = email, !email.isEmpty {
                details.append(CommentDetailInfoUserDetails(title: Strings.emailAddressLabelText, description: email))
            }

            if let ipAddress = ipAddress {
                details.append(CommentDetailInfoUserDetails(title: Strings.ipAddressLabelText, description: ipAddress))
            }
        }

        return details
    }

    func didSelectItem(at index: Int) {
        guard fetchUserDetails()[index].title == Strings.addressLabelText, let url = url else {
            return
        }

        view?.showAuthorPage(url: url)
    }

    private enum Strings {
        static let addressLabelText = NSLocalizedString(
            "Web address",
            comment: "Describes the web address section in the comment detail screen."
        )
        static let emailAddressLabelText = NSLocalizedString(
            "Email address",
            comment: "Describes the email address section in the comment detail screen."
        )
        static let ipAddressLabelText = NSLocalizedString(
            "IP address",
            comment: "Describes the IP address section in the comment detail screen."
        )
    }
}
