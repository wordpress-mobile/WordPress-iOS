import Foundation

enum HomepageType: String {
    case page
    case posts

    var title: String {
        switch self {
        case .page:
            return NSLocalizedString("Static Homepage", comment: "Name of setting configured when a site uses a static page as its homepage")
        case .posts:
            return NSLocalizedString("Classic Blog", comment: "Name of setting configured when a site uses a list of blog posts as its homepage")
        }
    }

    var remoteType: RemoteHomepageType {
        switch self {
        case .page:
            return .page
        case .posts:
            return .posts
        }
    }
}

extension Blog {
    private enum OptionsKeys {
        static let homepageType = "show_on_front"
        static let homepageID = "page_on_front"
        static let postsPageID = "page_for_posts"
    }

    /// The type of homepage used for the site: blog posts, or static pages
    ///
    var homepageType: HomepageType? {
        get {
            guard let options = options,
                !options.isEmpty,
                let type = getOptionString(name: OptionsKeys.homepageType)
                else {
                    return nil
            }

            return HomepageType(rawValue: type)
        }
        set {
            if let value = newValue?.rawValue {
                setValue(value, forOption: OptionsKeys.homepageType)
            }
        }
    }

    /// The ID of the page to use for the site's 'posts' page,
    /// if `homepageType` is set to `.posts`
    ///
    var homepagePostsPageID: Int? {
        get {
            guard let options = options,
                !options.isEmpty,
                let pageID = getOptionNumeric(name: OptionsKeys.postsPageID)
                else {
                    return nil
            }

            return pageID.intValue
        }
        set {
            let number: NSNumber?
            if let newValue = newValue {
                number = NSNumber(integerLiteral: newValue)
            } else {
                number = nil
            }
            setValue(number as Any, forOption: OptionsKeys.postsPageID)
        }
    }

    /// The ID of the page to use for the site's homepage,
    /// if `homepageType` is set to `.page`
    ///
    var homepagePageID: Int? {
        get {
            guard let options = options,
                !options.isEmpty,
                let pageID = getOptionNumeric(name: OptionsKeys.homepageID)
                else {
                    return nil
            }

            return pageID.intValue
        }
        set {
            let number: NSNumber?
            if let newValue = newValue {
                number = NSNumber(integerLiteral: newValue)
            } else {
                number = nil
            }
            setValue(number as Any, forOption: OptionsKeys.homepageID)
        }
    }
}
