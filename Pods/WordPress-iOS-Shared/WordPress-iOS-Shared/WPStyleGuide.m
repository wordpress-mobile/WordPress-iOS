#import "WPStyleGuide.h"
#import "UITableViewTextFieldCell.h"
#import "UIColor+Helpers.h"
#import <DTCoreText/DTCoreText.h>
#import "WPFontManager.h"

@implementation WPStyleGuide

#pragma mark - Fonts
+ (UIFont *)largePostTitleFont
{
    return [WPFontManager openSansLightFontOfSize:32.0];
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
    return [WPFontManager openSansRegularFontOfSize:16.0];
}

+ (UIFont *)postTitleFontBold
{
    return [WPFontManager openSansBoldFontOfSize:16.0];
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
    return [WPFontManager openSansRegularFontOfSize:12.0];
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
    return [WPFontManager openSansItalicFontOfSize:12.0];
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
    return [WPFontManager openSansBoldFontOfSize:12.0];
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
    return [WPFontManager openSansBoldFontOfSize:10.0];
}

+ (UIFont *)labelFontNormal
{
    return [WPFontManager openSansRegularFontOfSize:10.0];
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
    return [WPFontManager openSansRegularFontOfSize:16.0];
}

+ (UIFont *)regularTextFontBold
{
    return [WPFontManager openSansBoldFontOfSize:16.0];
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
    return [WPFontManager openSansRegularFontOfSize:18.0];
}

+ (UIFont *)tableviewSubtitleFont
{
    return [WPFontManager openSansLightFontOfSize:18.0];
}

+ (UIFont *)tableviewSectionHeaderFont
{
    return [WPFontManager openSansBoldFontOfSize:12.0];
}

+ (NSDictionary *)defaultDTCoreTextOptions
{
    NSString *defaultStyles = @"blockquote {background-color: #EEEEEE; width: 100%; display: block; padding: 8px 5px 10px 0;}";
    DTCSSStylesheet *cssStylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:defaultStyles];
    return @{
             DTDefaultFontFamily:@"Open Sans",
             DTDefaultLineHeightMultiplier:(IS_IPAD ? @1.6 : @1.4),
             DTDefaultFontSize:(IS_IPAD ? @18 : @16),
             DTDefaultTextColor:[WPStyleGuide littleEddieGrey],
             DTDefaultLinkColor:[WPStyleGuide baseLighterBlue],
             DTDefaultLinkHighlightColor:[WPStyleGuide midnightBlue],
             DTDefaultLinkDecoration:@NO,
             DTDefaultStyleSheet:cssStylesheet
             };
}

#pragma mark - Colors

+ (UIColor *)wordPressBlue
{
    return [UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f];
}

+ (UIColor *)baseLighterBlue
{
    return [UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f];
}

+ (UIColor *)baseDarkerBlue
{
    return [UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f];
}

+ (UIColor *)lightBlue
{
	return [UIColor colorWithRed:120/255.0f green:220/255.0f blue:250/255.0f alpha:1.0f];
}

+ (UIColor *)newKidOnTheBlockBlue
{
	return [UIColor colorWithRed:0/255.0f green:170/255.0f blue:220/255.0f alpha:1.0f];
}

+ (UIColor *)midnightBlue
{
	return [UIColor colorWithRed:0/255.0f green:80/255.0f blue:130/255.0f alpha:1.0f];
}

+ (UIColor *)jazzyOrange
{
	return [UIColor colorWithRed:240/255.0f green:130/255.0f blue:30/255.0f alpha:1.0f];
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
	return [UIColor colorWithRed:50/255.0f green:65/255.0f blue:85/255.0f alpha:1.0f];
}

+ (UIColor *)whisperGrey
{
    return  [UIColor colorWithRed:82/255.0f green:122/255.0f blue:148/255.0f alpha:1.0f];
}

+ (UIColor *)allTAllShadeGrey
{
	return  [UIColor colorWithRed:144/255.0f green:174/255.0f blue:194/255.0f alpha:1.0f];
}

+ (UIColor *)readGrey
{
	return [UIColor colorWithRed:210/255.0f green:222/255.0f blue:230/255.0f alpha:1.0f];
}

+ (UIColor *)itsEverywhereGrey
{
	return [UIColor colorWithRed:232/255.0f green:240/255.0f blue:247/255.0f alpha:1.0f];
}

+ (UIColor *)darkAsNightGrey
{
	return [UIColor colorWithRed:0/255.0f green:80/255.0f blue:130/255.0f alpha:1.0f];
}

+ (UIColor *)textFieldPlaceholderGrey
{
    return [UIColor colorWithRed:144.0f/255.0f green:174.0f/255.0f blue:194.0f/255.0f alpha:1.0f];
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

+ (UIColor *)statsLighterBlue {
    return [UIColor colorWithRed:144.0f/255.0f green:174.0f/255.0f blue:194.0f/255.0f alpha:1.0f];
}

+ (UIColor *)statsDarkerBlue {
    return [UIColor colorWithRed:50.0f/255.0f green:65.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
}

+ (UIColor *)keyboardColor {
    // Pre iOS 7.1 uses a the lighter keyboard background.
    // There doesn't seem to be a good way to get the keyboard background color
    // programatically so we'll rely on checking the OS version.
    // Approach based on http://stackoverflow.com/a/5337804
    NSString *versionStr = [[UIDevice currentDevice] systemVersion];
    BOOL hasLighterKeyboard = [versionStr compare:@"7.1" options:NSNumericSearch] == NSOrderedAscending;
    
    if (hasLighterKeyboard) {
        if (IS_IPAD) {
            return [UIColor colorWithRed:207.0f/255.0f green:210.0f/255.0f blue:213.0f/255.0f alpha:1.0];
        } else {
            return [UIColor colorWithRed:220.0f/255.0f green:223.0f/255.0f blue:226.0f/255.0f alpha:1.0];
        }
    }
    
    if (IS_IPAD) {
        return [UIColor colorWithRed:217.0f/255.0f green:220.0f/255.0f blue:223.0f/255.0f alpha:1.0];
    } else {
        return [UIColor colorWithRed:204.0f/255.0f green:208.0f/255.0f blue:214.0f/255.0f alpha:1.0];
    }
}

+ (UIColor *)notificationsLightGrey
{
	return [UIColor colorWithRed:244/255.0f green:248/255.0f blue:250/255.0f alpha:1.0f];
}

+ (UIColor *)notificationsDarkGrey
{
	return [UIColor colorWithRed:210/255.0f green:222/255.0f blue:230/255.0f alpha:1.0f];
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

+ (void)configureTableViewSmallSubtitleCell:(UITableViewCell *)cell
{
    [self configureTableViewCell:cell];
    cell.detailTextLabel.font = [self subtitleFont];
}

+ (void)configureColorsForView:(UIView *)view andTableView:(UITableView *)tableView
{
    tableView.backgroundView = nil;
    view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    tableView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    tableView.separatorColor = [WPStyleGuide readGrey];
}

+ (void)configureColorsForView:(UIView *)view collectionView:(UICollectionView *)collectionView
{
    collectionView.backgroundView = nil;
    collectionView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
}

+ (void)configureFollowButton:(UIButton *)followButton {
    followButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    followButton.backgroundColor = [UIColor clearColor];
    followButton.titleLabel.font = [WPStyleGuide subtitleFont];
    NSString *followString = NSLocalizedString(@"Follow", @"Prompt to follow a blog.");
    NSString *followedString = NSLocalizedString(@"Following", @"User is following the blog.");
    [followButton setTitle:followString forState:UIControlStateNormal];
    [followButton setTitle:followedString forState:UIControlStateSelected];
    [followButton setImage:[UIImage imageNamed:@"reader-postaction-follow"] forState:UIControlStateNormal];
    [followButton setImage:[UIImage imageNamed:@"reader-postaction-following"] forState:UIControlStateSelected];
    [followButton setTitleColor:[UIColor colorWithHexString:@"90aec2"] forState:UIControlStateNormal];
}

@end
