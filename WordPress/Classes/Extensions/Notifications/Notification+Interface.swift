import Foundation


extension Notification
{
    // MARK: - Helper Grouping Methods
    public func sectionIdentifier() -> String {
        // Normalize Dates: Time must not be considered. Just the raw dates
        let fromDate                = timestampAsDate.normalizedDate()
        let toDate                  = NSDate().normalizedDate()

        // Analyze the Delta-Components
        let calendar                = NSCalendar.currentCalendar()
        let flags: NSCalendarUnit   = .DayCalendarUnit | .WeekOfYearCalendarUnit | .MonthCalendarUnit
        let components              = calendar.components(flags, fromDate: fromDate, toDate: toDate, options: nil)
        
        var identifier: Int

        // Months
        if components.month >= 1 {
            identifier = Sections.Months
            
        // Weeks
        } else if components.weekOfYear >= 1 {
            identifier = Sections.Weeks
            
        // Days
        } else if components.day > 1 {
            identifier = Sections.Days
        } else if components.day == 1 {
            identifier = Sections.Yesterday
        } else {
            identifier = Sections.Today
        }
        
        return String(format: "%d", identifier)
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
            return NSLocalizedString("Older than a Month",  comment: "Notifications Months Section Header")
        case Sections.Weeks:
            return NSLocalizedString("Older than a Week",   comment: "Notifications Weeks Section Header")
        case Sections.Days:
            return NSLocalizedString("Older than 2 days",   comment: "Notifications +2 Days Section Header")
        case Sections.Yesterday:
            return NSLocalizedString("Yesterday",           comment: "Notifications Yesterday Section Header")
        default:
            return NSLocalizedString("Today",               comment: "Notifications Today Section Header")
        }
    }
        
    // FIXME: Turn this into an enum, when llvm is fixed
    private struct Sections
    {
        static let Months       = 0
        static let Weeks        = 2
        static let Days         = 4
        static let Yesterday    = 5
        static let Today        = 6
    }
}
