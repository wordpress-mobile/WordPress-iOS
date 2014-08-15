//
//  WPStyleGuide+Notifications.swift
//  WordPress
//
//  Created by Jorge Leandro Perez on 8/14/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

import Foundation


extension WPStyleGuide
{
    public class Notifications
    {
        // MARK: Noticon Styles
        //
        public class func iconFont() -> UIFont {
            return UIFont(name: "Noticons", size: 16)
        }
        
        public class func iconReadColor() -> UIColor {
            return UIColor(red: 0xA4/255.0, green: 0xB9/255.0, blue: 0xC9/255.0, alpha: 0xFF/255.0)
        }
        
        public class func iconUnreadColor() -> UIColor {
            return UIColor(red: 0x25/255.0, green: 0x9C/255.0, blue: 0xCF/255.0, alpha: 0xFF/255.0)
        }
        
        
        // MARK: Notification Cell
        //
        public class func backgroundReadColor() -> UIColor {
            return UIColor.whiteColor()
        }
        
        class func backgroundUnreadColor() -> UIColor {
            return UIColor(red: 0xF1/255.0, green: 0xF6/255.0, blue: 0xF9/255.0, alpha: 0xFF/255.0)
        }

        
        // MARK: Notification Timestamp
        //
        public class func timestampFont() -> UIFont {
            return WPFontManager.openSansRegularFontOfSize(14)
        }
        
        public class func timestampTextColor() -> UIColor {
            return UIColor(red: 0xB7/255.0, green: 0xC9/255.0, blue: 0xD5/255.0, alpha: 0xFF/255.0)
        }
        
        
        // MARK: Notification Subject
        //
        private class func subjectFontRegular() -> UIFont {
            return WPFontManager.openSansRegularFontOfSize(14)
        }
        
        private class func subjectFontBold() -> UIFont {
            return WPFontManager.openSansBoldFontOfSize(14)
        }
        
        private class func subjectFontItalics() -> UIFont {
            return WPFontManager.openSansItalicFontOfSize(14)
        }
        
        private class func subjectParagraphStyle() -> NSParagraphStyle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = 18;
            paragraphStyle.maximumLineHeight = 18;
            return paragraphStyle
        }
        
        public class func subjectAttributesRegular() -> NSDictionary {
            return NSDictionary(objectsAndKeys:
                subjectParagraphStyle(),    NSParagraphStyleAttributeName,
                subjectFontRegular(),       NSFontAttributeName
            )
        }
        
        public class func subjectAttributesBold() -> NSDictionary {
            return NSDictionary(objectsAndKeys:
                subjectParagraphStyle(),    NSParagraphStyleAttributeName,
                subjectFontBold(),          NSFontAttributeName
            )
        }
        
        public class func subjectAttributesItalics() -> NSDictionary {
            return NSDictionary(objectsAndKeys:
                subjectParagraphStyle(),    NSParagraphStyleAttributeName,
                subjectFontItalics(),       NSFontAttributeName
            )
        }
        
        
        // MARK: Notification Header styles
        //
        public class func headerTextColor() -> UIColor {
            return iconReadColor()
        }
        
        public class func headerBackgroundColor() -> UIColor {
            return UIColor.whiteColor()
        }
        
        public class func headerIconFont() -> UIFont {
            return UIFont(name: "Noticons", size: 20)
        }
        
        
        // Notification Block: Regular
        //
        public class func blockBackgroundColor() -> UIColor {
            return UIColor.clearColor()
        }
        
        public class func blockFontRegular() -> UIFont {
            let size: CGFloat = UIDevice.isPad() ? 18 : 16
            return WPFontManager.openSansRegularFontOfSize(size)
        }
        
        public class func blockFontBold() -> UIFont {
            let size: CGFloat = UIDevice.isPad() ? 18 : 16
            return WPFontManager.openSansBoldFontOfSize(size)
        }
        
        public class func blockFontItalics() -> UIFont {
            let size: CGFloat = UIDevice.isPad() ? 18 : 16
            return WPFontManager.openSansItalicFontOfSize(size)
        }
        
        private class func blockParagraphStyle() -> NSParagraphStyle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = 24;
            paragraphStyle.maximumLineHeight = 24;
            return paragraphStyle;
        }
        
        public class func blockAttributesRegular() -> NSDictionary {
            return NSDictionary(objectsAndKeys:
                blockParagraphStyle(),              NSParagraphStyleAttributeName,
                blockFontRegular(),                 NSFontAttributeName,
                WPStyleGuide.littleEddieGrey(),     NSForegroundColorAttributeName
            )
        }
        
        public class func blockAttributesBold() -> NSDictionary {
            return NSDictionary(objectsAndKeys:
                blockParagraphStyle(),              NSParagraphStyleAttributeName,
                blockFontBold(),                    NSFontAttributeName,
                WPStyleGuide.littleEddieGrey(),     NSForegroundColorAttributeName
            )
        }
        
        public class func notificationBlockAttributesItalics() -> NSDictionary {
            return NSDictionary(objectsAndKeys:
                blockParagraphStyle(),              NSParagraphStyleAttributeName,
                blockFontItalics(),                 NSFontAttributeName,
                WPStyleGuide.littleEddieGrey(),     NSForegroundColorAttributeName
            )
        }
        
        
        // Notification Block: Quoted
        //
        public class func notificationQuotedAttributesItalics() -> NSDictionary {
            return NSDictionary(objectsAndKeys:
                blockParagraphStyle(),              NSParagraphStyleAttributeName,
                blockFontItalics(),                 NSFontAttributeName,
                WPStyleGuide.allTAllShadeGrey(),    NSForegroundColorAttributeName
            )
    }
    }
}
