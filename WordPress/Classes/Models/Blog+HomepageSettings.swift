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
}

extension Blog {
    private enum OptionsKeys {
        static let homepageType = "show_on_front"
    }

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
}
