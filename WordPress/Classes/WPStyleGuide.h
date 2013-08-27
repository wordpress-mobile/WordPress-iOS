//
//  WPStyleGuide.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPStyleGuide : NSObject

// Fonts
+ (UIFont *)largePostTitleFont;
+ (NSDictionary *)largePostTitleAttributes;
+ (UIFont *)postTitleFont;
+ (NSDictionary *)postTitleAttributes;
+ (UIFont *)subtitleFont;
+ (NSDictionary *)subtitleAttributes;
+ (UIFont *)subtitleFontItalic;
+ (NSDictionary *)subtitleItalicAttributes;
+ (UIFont *)labelFont;
+ (NSDictionary *)labelAttributes;
+ (UIFont *)regularTextFont;
+ (NSDictionary *)regularTextAttributes;

// Colors
+ (UIColor *)baseLightBlue;
+ (UIColor *)baseDarkBlue;
+ (UIColor *)lightBlue;
+ (UIColor *)newKidOnTheBlockBlue;
+ (UIColor *)midnightBlue;
+ (UIColor *)jazzyOrange;
+ (UIColor *)fireOrange;
+ (UIColor *)bigEddieGrey;
+ (UIColor *)littleEddieGrey;
+ (UIColor *)whisperGrey;
+ (UIColor *)allTAllShadeGrey;
+ (UIColor *)readGrey;
+ (UIColor *)itsEverywhereGrey;

@end
