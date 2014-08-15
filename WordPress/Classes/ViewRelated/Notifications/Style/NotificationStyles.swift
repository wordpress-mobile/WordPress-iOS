import Foundation


public struct NotificationStyles
{
    private static let subjectParagraphStyle    = NSMutableParagraphStyle(minimumLineHeight: 18, maximumLineHeight: 18)
    private static let blockParagraphStyle      = NSMutableParagraphStyle(minimumLineHeight: 24, maximumLineHeight: 24)
    
    public static let subjectRegular    = NSDictionary(objectsAndKeys:
        subjectParagraphStyle,              NSParagraphStyleAttributeName,
        NotificationFonts.subjectRegular,   NSFontAttributeName
    )
    
    public static let subjectBold       = NSDictionary(objectsAndKeys:
        subjectParagraphStyle,              NSParagraphStyleAttributeName,
        NotificationFonts.subjectBold,      NSFontAttributeName
    )
    
    public static let subjectItalics    = NSDictionary(objectsAndKeys:
        subjectParagraphStyle,              NSParagraphStyleAttributeName,
        NotificationFonts.subjectItalics,   NSFontAttributeName
    )
    
    public static let blockRegular      = NSDictionary(objectsAndKeys:
        blockParagraphStyle,                NSParagraphStyleAttributeName,
        NotificationFonts.blockRegular,     NSFontAttributeName,
        NotificationColors.blockText,       NSForegroundColorAttributeName
    )
    
    public static let blockBold         = NSDictionary(objectsAndKeys:
        blockParagraphStyle,                NSParagraphStyleAttributeName,
        NotificationFonts.blockBold,        NSFontAttributeName,
        NotificationColors.blockText,       NSForegroundColorAttributeName
    )
    
    public static let blockItalics      = NSDictionary(objectsAndKeys:
        blockParagraphStyle,                NSParagraphStyleAttributeName,
        NotificationFonts.blockItalics,     NSFontAttributeName,
        NotificationColors.blockText,       NSForegroundColorAttributeName
    )
    
    public static let quotedItalics     = NSDictionary(objectsAndKeys:
        blockParagraphStyle,                NSParagraphStyleAttributeName,
        NotificationFonts.blockItalics,     NSFontAttributeName,
        NotificationColors.quotedText,      NSForegroundColorAttributeName
    )
}
