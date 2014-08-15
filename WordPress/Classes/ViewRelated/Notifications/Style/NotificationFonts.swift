import Foundation


public struct NotificationFonts
{
    public static let noticon           = UIFont(name: "Noticons", size: 16)
    public static let timestamp         = WPFontManager.openSansRegularFontOfSize(14)
    
    public static let subjectRegular    = WPFontManager.openSansRegularFontOfSize(14)
    public static let subjectBold       = WPFontManager.openSansBoldFontOfSize(14)
    public static let subjectItalics    = WPFontManager.openSansItalicFontOfSize(14)
    
    public static let blockFontSize     = CGFloat(UIDevice.isPad() ? 18 : 16)
    public static let blockRegular      = WPFontManager.openSansRegularFontOfSize(blockFontSize)
    public static let blockBold         = WPFontManager.openSansBoldFontOfSize(blockFontSize)
    public static let blockItalics      = WPFontManager.openSansItalicFontOfSize(blockFontSize)
}
