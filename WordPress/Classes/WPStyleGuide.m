//
//  WPStyleGuide.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPStyleGuide.h"

@implementation WPStyleGuide

#pragma mark - Fonts
+ (UIFont *)largePostTitleFont
{
    return [UIFont fontWithName:@"OpenSans-Light" size:32.0];
}

+ (UIFont *)postTitleFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

+ (UIFont *)subtitleFont
{
    return [UIFont fontWithName:@"OpenSans" size:12.0];
}

+ (UIFont *)subtitleFontItalic
{
    return [UIFont fontWithName:@"OpenSans-Italic" size:12.0];
}

+ (UIFont *)labelFont
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:10.0];
}

+ (UIFont *)regularTextFont
{
    return [UIFont fontWithName:@"OpenSans" size:16.0];
}

#pragma mark - Colors

+ (UIColor *)baseLightBlue
{
    return [UIColor colorWithRed:30/255.0f green:140/255.0f blue:190/255.0f alpha:1.0];
}

+ (UIColor *)baseDarkBlue
{
    return [UIColor colorWithRed:0 green:116/255.0f blue:162/255.0f alpha:1.0f];
}

+ (UIColor *)lightBlue
{
	return [UIColor colorWithRed:120/255.0f green:200/255.0f blue:230/255.0f alpha:1.0f];
}

+ (UIColor *)newKidOnTheBlockBlue
{
	return [UIColor colorWithRed:46/255.0f green:162/255.0f blue:204/255.0f alpha:1.0f];
}

+ (UIColor *)midnightBlue
{
	return [UIColor colorWithRed:0/255.0f green:86/255.0f blue:132/255.0f alpha:1.0f];
}

+ (UIColor *)jazzyOrange
{
	return [UIColor colorWithRed:241/255.0f green:131/255.0f blue:30/255.0f alpha:1.0f];
}

+ (UIColor *)fireOrange
{
	return [UIColor colorWithRed:213/255.0f green:78/255.0f blue:33/255.0f alpha:1.0f];
}

+ (UIColor *)bigEddieGrey
{
	return [UIColor colorWithRed:34/255.0f green:34/255.0f blue:34/255.0f alpha:1.0f];
}

+ (UIColor *)littleEddieGrey
{
	return [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
}

+ (UIColor *)whisperGrey
{
	return [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
}

+ (UIColor *)allTAllShadeGrey
{
	return  [UIColor colorWithRed:153/255.0f green:153/255.0f blue:153/255.0f alpha:1.0f];
}

+ (UIColor *)readGrey
{
	return [UIColor colorWithRed:221/255.0f green:221/255.0f blue:221/255.0f alpha:1.0f];
}

+ (UIColor *)itsEverywhereGrey
{
	return [UIColor colorWithRed:238/255.0f green:238/255.0f blue:238/255.0f alpha:1.0f];
}

@end
