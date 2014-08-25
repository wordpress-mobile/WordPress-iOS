import Foundation


extension Notification
{
    public func sectionIdentifier() -> String {
        // Normalize Dates: Time must not be considered. Just the raw dates
        let fromDate                = timestampAsDate.normalizedDate()
        let toDate                  = NSDate().normalizedDate()

        // Analyze the Delta-Components
        let calendar                = NSCalendar.currentCalendar()
        let flags: NSCalendarUnit   = .DayCalendarUnit | .WeekOfYearCalendarUnit | .MonthCalendarUnit
        let components              = calendar.components(flags, fromDate: fromDate, toDate: toDate, options: nil)
        
        var identifier: (kind: Int, value: Int)

        // Months
        if components.month > 1 {
            identifier = (Sections.Months, components.month)
        } else if components.month == 1 {
            identifier = (Sections.Month, components.month)
            
        // Weeks
        } else if components.weekOfYear > 1 {
            identifier = (Sections.Weeks, components.weekOfYear)
        } else if components.weekOfYear == 1 {
            identifier = (Sections.Week, components.weekOfYear)
            
        // Days
        } else if components.day > 1 {
            identifier = (Sections.Days, components.day)
        } else if components.day == 1 {
            identifier = (Sections.Yesterday, components.day)
        } else {
            identifier = (Sections.Today, components.day)
        }
        
        return String(format: "%d:%d", identifier.kind, identifier.value)
    }
    
    public class func descriptionForSectionIdentifier(identifier: String) -> String {
        let components      = identifier.componentsSeparatedByString(":")
        let wrappedKind     = components.first?.toInt()
        let wrappedPayload  = components.last?.toInt()

        if wrappedKind == nil || wrappedPayload == nil {
            return String()
        }
        
        let kind    = wrappedKind!
        let payload = wrappedPayload!
        
        switch kind {
        case Sections.Months:
            return String(format: "%d %@", payload, NSLocalizedString("Months Ago", comment: ""))
        case Sections.Month:
            return NSLocalizedString("One Month Ago", comment: "")
        case Sections.Weeks:
            return String(format: "%d %@", payload, NSLocalizedString("Weeks Ago", comment: ""))
        case Sections.Week:
            return NSLocalizedString("One Week Ago", comment: "")
        case Sections.Days:
            return String(format: "%d %@", payload, NSLocalizedString("Days Ago", comment: ""))
        case Sections.Yesterday:
            return NSLocalizedString("Yesterday", comment: "")
        default:
            return NSLocalizedString("Today", comment: "")
        }
    }
        
    // FIXME: Turn this into an enum, when llvm is fixed
    private struct Sections
    {
        static let Months       = 0
        static let Month        = 1
        static let Weeks        = 2
        static let Week         = 3
        static let Days         = 4
        static let Yesterday    = 5
        static let Today        = 6
    }
}
