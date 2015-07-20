import Foundation


extension WPStyleGuide
{
    public struct AlertView
    {
        public static let titleFont     = WPFontManager.openSansLightFontOfSize(16)
        public static let detailsFont   = WPFontManager.openSansRegularFontOfSize(14)
        public static let buttonFont    = WPFontManager.openSansRegularFontOfSize(16)
        
        public static let titleColor    = UIColor(red: 0x87/255.0, green: 0xA6/255.0, blue: 0xBC/255.0, alpha: 0xFF/255.0)
        public static let detailsColor  = WPStyleGuide.darkGrey()
    }
}
