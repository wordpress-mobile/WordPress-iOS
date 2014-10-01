import Foundation


extension WPStyleGuide
{
    public struct Reply
    {
        // Styles used by ReplyTextView
        //
        public static let buttonFont       = WPFontManager.openSansBoldFontOfSize(13)
        public static let textFont         = WPFontManager.openSansRegularFontOfSize(14)

        public static let enabledColor     = WPStyleGuide.newKidOnTheBlockBlue()
        public static let disabledColor    = UIColor(red: 0xA1/255.0, green: 0xB9/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
        public static let placeholderColor = UIColor(red: 0xA3/255.0, green: 0xB9/255.0, blue: 0xCA/255.0, alpha: 0xFF/255.0)
        public static let textColor        = WPStyleGuide.littleEddieGrey()
        public static let separatorColor   = placeholderColor
        public static let backgroundColor  = UIColor(red: 0xF1/255.0, green:0xF6/255.0, blue:0xF9/255.0, alpha:0xFF/255.0)
    }
}
