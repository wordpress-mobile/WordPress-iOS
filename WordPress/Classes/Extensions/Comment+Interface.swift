/// Allows comment objects to be sectioned by relative date.
///
/// This implementation is copied from Notification+Interface.swift. It pains me having to copy paste code,
/// but we should be able clean this up once `Comment` and the view controller displaying it is rewritten in Swift.
/// i.e.: Introduce a protocol with default implementation. Protocol extension doesn't work with @objc!
///
extension Comment {
    /// Returns a Section Identifier that can be sorted. Note that this string is not human
    /// readable, and you should use the *descriptionForSectionIdentifier* method
    /// as well!
    ///
    @objc func relativeDateSectionIdentifier() -> String? {
        guard let dateCreated = dateCreated else {
            return nil
        }

        // Normalize Dates: Time must not be considered. Just the raw dates
        let fromDate = dateCreated.normalizedDate()
        let toDate = Date().normalizedDate()

        // Analyze the Delta-Components
        let calendar = Calendar.current
        let components = [.day, .weekOfYear, .month] as Set<Calendar.Component>
        let dateComponents = calendar.dateComponents(components, from: fromDate, to: toDate)
        let identifier: Sections

        // Months
        if let month = dateComponents.month, month >= 1 {
            identifier = .Months
        // Weeks
        } else if let week = dateComponents.weekOfYear, week >= 1 {
            identifier = .Weeks
        // Days
        } else if let day = dateComponents.day, day > 1 {
            identifier = .Days
        } else if let day = dateComponents.day, day == 1 {
            identifier = .Yesterday
        } else {
            identifier = .Today
        }

        return identifier.rawValue
    }

    /// Translates a relative date section identifier into a human-readable string.
    ///
    @objc static func descriptionForSectionIdentifier(_ identifier: String) -> String {
        guard let section = Sections(rawValue: identifier) else {
            return String()
        }

        return section.description
    }

    // MARK: - Private Helpers

    private enum Sections: String {
        case Months     = "0"
        case Weeks      = "2"
        case Days       = "4"
        case Yesterday  = "5"
        case Today      = "6"

        var description: String {
            switch self {
            case .Months:
                return NSLocalizedString("Older than a Month", comment: "Comments Months Section Header")
            case .Weeks:
                return NSLocalizedString("Older than a Week", comment: "Comments Weeks Section Header")
            case .Days:
                return NSLocalizedString("Older than 2 days", comment: "Comments +2 Days Section Header")
            case .Yesterday:
                return NSLocalizedString("Yesterday", comment: "Comments Yesterday Section Header")
            case .Today:
                return NSLocalizedString("Today", comment: "Comments Today Section Header")
            }
        }
    }
}
