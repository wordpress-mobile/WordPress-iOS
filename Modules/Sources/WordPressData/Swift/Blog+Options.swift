import Foundation

extension Blog {
    public static let postFormatStandard = "standard"

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

    public var isWPComStagingSite: Bool {
        getOptionBoolean(name: "is_wpcom_staging_site")
    }

    // MARK: - Options Access

    @objc public func getOptionValue(_ name: String) -> Any? {
        var optionValue: Any?
        managedObjectContext?.performAndWait {
            let currentOption = self.options?[name] as? [AnyHashable: Any]
            optionValue = currentOption?["value"]
        }
        return optionValue
    }

    @objc public func setValue(_ value: Any, forOption name: String) {
        managedObjectContext?.performAndWait {
            var mutableOptions: [AnyHashable: Any] = self.options ?? [:]
            mutableOptions[name] = ["value": value]
            self.options = mutableOptions
        }
    }

    // MARK: - Helpers

    func getOptionBoolean(name: String) -> Bool {
        (getOptionValue(name) as? NSNumber)?.boolValue ?? false
    }

    func getOption<T>(name: String) -> T? {
        getOptionValue(name) as? T
    }

    public func getOptionString(name: String) -> String? {
        (getOption(name: name) as NSString?).map(String.init)
    }

    /// - warning: DO NOT USE. This doesn't work for negative values, e.g. "-11"
    /// and potentially other scenarios.
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
