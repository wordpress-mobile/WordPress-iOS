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

+ (NSDictionary *)largePostTitleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 35;
    paragraphStyle.maximumLineHeight = 35;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self largePostTitleFont]};
}

+ (UIFont *)postTitleFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

+ (NSDictionary *)postTitleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 20;
    paragraphStyle.maximumLineHeight = 20;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self postTitleFont]};
}

+ (UIFont *)subtitleFont
{
    return [UIFont fontWithName:@"OpenSans" size:12.0];
}

+ (NSDictionary *)subtitleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 14;
    paragraphStyle.maximumLineHeight = 14;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self subtitleFont]};
}

+ (UIFont *)subtitleFontItalic
{
    return [UIFont fontWithName:@"OpenSans-Italic" size:12.0];
}

+ (NSDictionary *)subtitleItalicAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 14;
    paragraphStyle.maximumLineHeight = 14;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self subtitleFontItalic]};
}

+ (UIFont *)labelFont
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:10.0];
}

+ (NSDictionary *)labelAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 12;
    paragraphStyle.maximumLineHeight = 12;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self labelFont]};
}

+ (UIFont *)regularTextFont
{
    return [UIFont fontWithName:@"OpenSans" size:16.0];
}

+ (NSDictionary *)regularTextAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 24;
    paragraphStyle.maximumLineHeight = 24;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self regularTextFont]};
}

+ (UIFont *)tableviewTextFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

+ (UIFont *)tableviewSubtitleFont
{
    return [UIFont fontWithName:@"OpenSans" size:12.0];
}

+ (UIFont *)tableviewSectionHeaderFont
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:12.0];
}

#pragma mark - Colors

+ (UIColor *)baseLighterBlue
{
    return [UIColor colorWithRed:30/255.0f green:140/255.0f blue:190/255.0f alpha:1.0f];
}

+ (UIColor *)baseDarkerBlue
{
    return [UIColor colorWithRed:0/255.0f green:116/255.0f blue:162/255.0f alpha:1.0f];
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
    return  [UIColor colorWithRed:102/255.0f green:102/255.0f blue:102/255.0f alpha:1.0f];
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

+ (UIColor *)darkAsNightGrey
{
	return [UIColor colorWithRed:16/255.0f green:16/255.0f blue:16/255.0f alpha:1.0f];
}

+ (UIColor *)tableViewActionColor
{
    return [WPStyleGuide baseLighterBlue];
}

+ (UIBarButtonItemStyle)barButtonStyleForDone
{
    if (IS_IOS7)
        return UIBarButtonItemStylePlain;
    else
        return UIBarButtonItemStyleDone;
}

+ (UIBarButtonItemStyle)barButtonStyleForBordered
{
    if (IS_IOS7)
        return UIBarButtonItemStylePlain;
    else
        return UIBarButtonItemStyleBordered;
}

+ (void)setLeftBarButtonItemWithCorrectSpacing:(UIBarButtonItem *)barButtonItem forNavigationItem:(UINavigationItem *)navigationItem
{
    navigationItem.leftBarButtonItems = @[[self spacerForNavigationBarButtonItems], barButtonItem];
}

+ (void)setRightBarButtonItemWithCorrectSpacing:(UIBarButtonItem *)barButtonItem forNavigationItem:(UINavigationItem *)navigationItem
{
    navigationItem.rightBarButtonItems = @[[self spacerForNavigationBarButtonItems], barButtonItem];
}

+ (UIBarButtonItem *)spacerForNavigationBarButtonItems
{
    UIBarButtonItem *spacerButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerButton.width = -16.0;
    return spacerButton;
}

+ (void)configureTableViewCell:(UITableViewCell *)cell
{
    cell.textLabel.font = [WPStyleGuide tableviewTextFont];
    cell.detailTextLabel.font = [WPStyleGuide tableviewSubtitleFont];
    cell.textLabel.textColor = [WPStyleGuide whisperGrey];
    cell.detailTextLabel.textColor = [WPStyleGuide whisperGrey];
}


@end
