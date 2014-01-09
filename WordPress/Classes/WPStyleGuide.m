//
//  WPStyleGuide.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPStyleGuide.h"
#import "UITableViewTextFieldCell.h"
#import <DTCoreText/DTCoreText.h>

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
    return [UIFont fontWithName:@"OpenSans" size:16.0];
}

+ (UIFont *)postTitleFontBold
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:16.0];
}

+ (NSDictionary *)postTitleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 19;
    paragraphStyle.maximumLineHeight = 19;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self postTitleFont]};
}

+ (NSDictionary *)postTitleAttributesBold {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 19;
    paragraphStyle.maximumLineHeight = 19;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self postTitleFontBold]};
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

+ (UIFont *)subtitleFontBold
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:12.0];
}

+ (NSDictionary *)subtitleAttributesBold
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 14;
    paragraphStyle.maximumLineHeight = 14;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self subtitleFontBold]};
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

+ (UIFont *)regularTextFontBold
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:16.0];    
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
    return [UIFont fontWithName:@"OpenSans-Light" size:18.0];
}

+ (UIFont *)tableviewSectionHeaderFont
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:12.0];
}

+ (NSDictionary *)defaultDTCoreTextOptions
{
    return @{
             DTDefaultFontFamily:@"Open Sans",
             DTDefaultLineHeightMultiplier:(IS_IPAD ? @1.6 : @1.4),
             DTDefaultFontSize:(IS_IPAD ? @18 : @16),
             DTDefaultTextColor:[WPStyleGuide littleEddieGrey],
             DTDefaultLinkColor:[WPStyleGuide baseLighterBlue],
             DTDefaultLinkHighlightColor:[WPStyleGuide midnightBlue],
             DTDefaultLinkDecoration:@NO
             };
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

+ (UIColor *)textFieldPlaceholderGrey
{
    return [UIColor colorWithRed:184.0f/255.0f green:184.0f/255.0f blue:184.0f/255.0f alpha:1.0f];
}

+ (UIColor *)validationErrorRed
{
    return [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0];
}

+ (UIColor *)tableViewActionColor
{
    return [WPStyleGuide baseLighterBlue];
}

+ (UIColor *)buttonActionColor
{
    return [WPStyleGuide baseLighterBlue];
}

+ (UIColor *)keyboardColor {
    if (IS_IPAD) {
        return [UIColor colorWithRed:207.0f/255.0f green:210.0f/255.0f blue:213.0f/255.0f alpha:1.0];
    } else {
        return [UIColor colorWithRed:220.0f/255.0f green:223.0f/255.0f blue:226.0f/255.0f alpha:1.0];
    }
}

+ (UIBarButtonItemStyle)barButtonStyleForDone
{
    return UIBarButtonItemStylePlain;
}

+ (UIBarButtonItemStyle)barButtonStyleForBordered
{
    return UIBarButtonItemStylePlain;
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

+ (void)configureTableViewActionCell:(UITableViewCell *)cell
{
    cell.textLabel.font = [self tableviewTextFont];
    cell.textLabel.textColor = [self tableViewActionColor];
}

+ (void)configureTableViewCell:(UITableViewCell *)cell
{
    cell.textLabel.font = [self tableviewTextFont];
    [cell.textLabel sizeToFit];

    cell.detailTextLabel.font = [self tableviewSubtitleFont];
    [cell.detailTextLabel sizeToFit];
    
    cell.textLabel.textColor = [self whisperGrey];
    cell.detailTextLabel.textColor = [self whisperGrey];
    if ([cell isKindOfClass:[UITableViewTextFieldCell class]]) {
        UITableViewTextFieldCell *tfcell = (UITableViewTextFieldCell *)cell;
        [tfcell.textField setTextColor:[self whisperGrey]];
    }
}

+ (void)configureTableViewTextCell:(UITableViewTextFieldCell *)cell
{
    [self configureTableViewCell:cell];
    cell.textField.font = [self tableviewSubtitleFont];
    
    if (cell.textField.enabled) {
        cell.textField.textColor = [self darkAsNightGrey];
        cell.textField.textAlignment = NSTextAlignmentLeft;
    } else {
        cell.textField.textColor = [self textFieldPlaceholderGrey];
        cell.textField.textAlignment = NSTextAlignmentRight;
    }
}

+ (void)configureColorsForView:(UIView *)view andTableView:(UITableView *)tableView
{
    tableView.backgroundView = nil;
    view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    tableView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    tableView.separatorColor = [WPStyleGuide readGrey];
}

@end
