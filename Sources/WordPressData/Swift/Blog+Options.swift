import Foundation

extension Blog {
    @objc public var isAtomic: Bool {
        getOptionBoolean(name: "is_wpcom_atomic")
    }

    @objc public var isWPForTeams: Bool {
        getOptionBoolean(name: "is_wpforteams_site")
    }

    public var isAutomatedTransfer: Bool {
        getOptionBoolean(name: "is_automated_transfer")
    }

    @objc public var canBlaze: Bool {
        getOptionBoolean(name: "can_blaze") && isAdmin
    }

    @objc public var supportsFeaturedImages: Bool {
        getOptionBoolean(name: "post_thumbnail")
    }

    public var isWPComStagingSite: Bool {
        getOptionBoolean(name: "is_wpcom_staging_site")
    }

    // MARK: - Internal

    func getOptionBoolean(name: String) -> Bool {
        (getOptionValue(name) as? NSNumber)?.boolValue ?? false
    }

    func getOption<T>(name: String) -> T? {
        getOptionValue(name) as? T
    }

    public func getOptionString(name: String) -> String? {
        (getOption(name: name) as NSString?).map(String.init)
    }

    func getOptionNumeric(name: String) -> NSNumber? {
        switch getOptionValue(name) {
        case let numericValue as NSNumber:
            return numericValue
        case let stringValue as NSString:
            return stringValue.numericValue()
        default:
            return nil
        }
    }
}
