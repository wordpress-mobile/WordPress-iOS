public enum PostVisibility: Identifiable, CaseIterable {
    case `public`
    case `private`
    case protected

    public init(post: AbstractPost) {
        self.init(status: post.status ?? .draft, password: post.password)
    }

    init(status: AbstractPost.Status, password: String?) {
        if let password, !password.isEmpty {
            self = .protected
        } else if status == .publishPrivate {
            self = .private
        } else {
            self = .public
        }
    }

    public var id: PostVisibility { self }

    public var localizedTitle: String {
        switch self {
        case .public: NSLocalizedString("postVisibility.public.title", value: "Public", comment: "Title for a 'Public' (default) privacy setting")
        case .protected: NSLocalizedString("postVisibility.protected.title", value: "Password protected", comment: "Title for a 'Password Protected' privacy setting")
        case .private: NSLocalizedString("postVisibility.private.title", value: "Private", comment: "Title for a 'Private' privacy setting")
        }
    }

    public var localizedDetails: String {
        switch self {
        case .public: NSLocalizedString("postVisibility.public.details", value: "Visible to everyone", comment: "Details for a 'Public' (default) privacy setting")
        case .protected: NSLocalizedString("postVisibility.protected.details", value: "Visibile to everyone but requires a password", comment: "Details for a 'Password Protected' privacy setting")
        case .private: NSLocalizedString("postVisibility.private.details", value: "Only visible to site admins and editors", comment: "Details for a 'Private' privacy setting")
        }
    }
}
