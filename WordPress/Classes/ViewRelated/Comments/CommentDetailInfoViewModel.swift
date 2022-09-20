import Foundation

protocol CommentDetailInfoViewModelInputs {
    func fetchUserDetails() -> [CommentDetailInfoUserDetails]
}

typealias CommentDetailInfoViewModelType = CommentDetailInfoViewModelInputs

struct CommentDetailInfoUserDetails {
    let title: String
    let description: String
}

final class CommentDetailInfoViewModel: CommentDetailInfoViewModelType {
    private let url: URL?
    private let email: String?
    private let ipAddress: String?

    init(url: URL?, email: String?, ipAddress: String?) {
        self.url = url
        self.email = email
        self.ipAddress = ipAddress
    }

    func fetchUserDetails() -> [CommentDetailInfoUserDetails] {
        var details: [CommentDetailInfoUserDetails] = []
        if let url = url {
            details.append(CommentDetailInfoUserDetails(title: Strings.addressLabelText, description: url.absoluteString))
        }

        if let email = email {
            details.append(CommentDetailInfoUserDetails(title: Strings.emailAddressLabelText, description: email))
        }

        if let ipAddress = ipAddress {
            details.append(CommentDetailInfoUserDetails(title: Strings.ipAddressLabelText, description: ipAddress))
        }

        return details
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
