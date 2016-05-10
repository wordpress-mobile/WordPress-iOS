import Foundation


extension Notification
{
    // MARK: - Helper Grouping Methods
    public func sectionIdentifier() -> String {
        // Normalize Dates: Time must not be considered. Just the raw dates
        let fromDate    = timestampAsDate.normalizedDate()
        let toDate      = NSDate().normalizedDate()

        // Analyze the Delta-Components
        let calendar    = NSCalendar.currentCalendar()
        let flags       = [.Day, .WeekOfYear, .Month] as NSCalendarUnit
        let components  = calendar.components(flags, fromDate: fromDate, toDate: toDate, options: .MatchFirst)
        let identifier: Sections

        // Months
        if components.month >= 1 {
            identifier = .Months
        // Weeks
        } else if components.weekOfYear >= 1 {
            identifier = .Weeks
        // Days
        } else if components.day > 1 {
            identifier = .Days
        } else if components.day == 1 {
            identifier = .Yesterday
        } else {
            identifier = .Today
        }

        return "\(identifier.rawValue)"
    }

    public class func descriptionForSectionIdentifier(identifier: String) -> String {
        guard let identifierAsInteger = Int(identifier),
                let kind = Sections(rawValue: identifierAsInteger) else
        {
            return String()
        }

        switch kind {
        case .Months:
            return NSLocalizedString("Older than a Month",  comment: "Notifications Months Section Header")
        case .Weeks:
            return NSLocalizedString("Older than a Week",   comment: "Notifications Weeks Section Header")
        case .Days:
            return NSLocalizedString("Older than 2 days",   comment: "Notifications +2 Days Section Header")
        case .Yesterday:
            return NSLocalizedString("Yesterday",           comment: "Notifications Yesterday Section Header")
        case .Today:
            return NSLocalizedString("Today",               comment: "Notifications Today Section Header")
        }
    }

    private enum Sections : Int {
        case Months       = 0
        case Weeks        = 2
        case Days         = 4
        case Yesterday    = 5
        case Today        = 6
    }
}
