import Foundation


extension Notification
{
    public struct Fonts
    {
        public static let noticon           = UIFont(name: "Noticons", size: 16)
        public static let timestamp         = WPFontManager.openSansRegularFontOfSize(14)
        
        private static let subjectSize      = CGFloat(14)
        public static let subjectRegular    = WPFontManager.openSansRegularFontOfSize(subjectSize)
        public static let subjectBold       = WPFontManager.openSansBoldFontOfSize(subjectSize)
        public static let subjectItalics    = WPFontManager.openSansItalicFontOfSize(subjectSize)
        
        private static let blockSizeMedium  = CGFloat(UIDevice.isPad() ? 18 : 16)
        private static let blockSizeSmall   = CGFloat(12)
        public static let blockRegular      = WPFontManager.openSansRegularFontOfSize(blockSizeMedium)
        public static let blockBold         = WPFontManager.openSansBoldFontOfSize(blockSizeMedium)
        public static let blockItalics      = WPFontManager.openSansItalicFontOfSize(blockSizeMedium)
        public static let blockHeader       = WPFontManager.openSansBoldFontOfSize(blockSizeSmall)
        public static let blockSubtitle     = WPFontManager.openSansRegularFontOfSize(blockSizeSmall)
    }

    public struct Colors
    {
        public static let iconRead          = UIColor(red: 0xA4/255.0, green: 0xB9/255.0, blue: 0xC9/255.0, alpha: 0xFF/255.0)
        public static let iconUnread        = UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)
        
        public static let backgroundRead    = UIColor.whiteColor()
        public static let backgroundUnread  = UIColor(red: 0xF1/255.0, green: 0xF6/255.0, blue: 0xF9/255.0, alpha: 0xFF/255.0)
        
        public static let timestamp         = UIColor(red: 0xB7/255.0, green: 0xC9/255.0, blue: 0xD5/255.0, alpha: 0xFF/255.0)
        public static let blockBackground   = UIColor.clearColor()
        public static let blockText         = WPStyleGuide.littleEddieGrey()
        public static let blockLink         = WPStyleGuide.baseLighterBlue()
        public static let blockHeader       = blockText
        public static let blockSubtitle     = WPStyleGuide.baseDarkerBlue()
        public static let quotedText        = WPStyleGuide.allTAllShadeGrey()
    }

    public struct Styles
    {
        private static let subjectParagraph = NSMutableParagraphStyle(minimumLineHeight: 18, maximumLineHeight: 18)
        private static let blockParagraph   = NSMutableParagraphStyle(minimumLineHeight: 24, maximumLineHeight: 24)
        
        public static let subjectRegular    = NSDictionary(objectsAndKeys:
            subjectParagraph,                   NSParagraphStyleAttributeName,
            Fonts.subjectRegular,               NSFontAttributeName
        )
        
        public static let subjectBold       = NSDictionary(objectsAndKeys:
            subjectParagraph,                   NSParagraphStyleAttributeName,
            Fonts.subjectBold,                  NSFontAttributeName
        )
        
        public static let subjectItalics    = NSDictionary(objectsAndKeys:
            subjectParagraph,                   NSParagraphStyleAttributeName,
            Fonts.subjectItalics,               NSFontAttributeName
        )
        
        public static let blockRegular      = NSDictionary(objectsAndKeys:
            blockParagraph,                     NSParagraphStyleAttributeName,
            Fonts.blockRegular,                 NSFontAttributeName,
            Colors.blockText,                   NSForegroundColorAttributeName
        )
        
        public static let blockBold         = NSDictionary(objectsAndKeys:
            blockParagraph,                     NSParagraphStyleAttributeName,
            Fonts.blockBold,                    NSFontAttributeName,
            Colors.blockText,                   NSForegroundColorAttributeName
        )
        
        public static let blockItalics      = NSDictionary(objectsAndKeys:
            blockParagraph,                     NSParagraphStyleAttributeName,
            Fonts.blockItalics,                 NSFontAttributeName,
            Colors.blockText,                   NSForegroundColorAttributeName
        )
        
        public static let quotedItalics     = NSDictionary(objectsAndKeys:
            blockParagraph,                     NSParagraphStyleAttributeName,
            Fonts.blockItalics,                 NSFontAttributeName,
            Colors.quotedText,                  NSForegroundColorAttributeName
        )
    }

    public func sectionIdentifier() -> String {
        let calendar                = NSCalendar.currentCalendar()
        
        let flags: NSCalendarUnit   = .DayCalendarUnit | .WeekOfYearCalendarUnit | .MonthCalendarUnit
        let toDate                  = NSDate()
        let components              = calendar.components(flags, fromDate: timestampAsDate, toDate: toDate, options: nil)
        
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
