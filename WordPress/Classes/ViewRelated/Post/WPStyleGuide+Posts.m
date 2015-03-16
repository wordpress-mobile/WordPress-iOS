#import "WPStyleGuide+Posts.h"
#import <WordPress-iOS-Shared/WPFontManager.h>
#import "WordPress-Swift.h"

@implementation WPStyleGuide (Posts)

#pragma mark - View Styles

+ (void)applyPostCardStyle:(UITableViewCell *)cell
{
    cell.backgroundColor = [self greyLighten30];
    cell.contentView.backgroundColor = [self greyLighten30];
}

+ (void)applyPostAuthorSiteStyle:(UILabel *)label
{
    CGFloat fontSize = [UIDevice isPad] ? 16.0 : 14.0;
    label.font = [WPFontManager openSansRegularFontOfSize:fontSize];
    label.textColor = [self grey];
}

+ (void)applyPostAuthorNameStyle:(UILabel *)label
{
    CGFloat fontSize = [UIDevice isPad] ? 14.0 : 12.0;
    label.font = [WPFontManager openSansRegularFontOfSize:fontSize];
    label.textColor = [self greyDarken20];
}

+ (void)applyPostTitleStyle:(UILabel *)label
{
    label.textColor = [self darkGrey];
}

+ (void)applyPostSnippetStyle:(UILabel *)label
{
    label.textColor = [self darkGrey];
}

+ (void)applyPostDateStyle:(UILabel *)label
{
    CGFloat fontSize = [UIDevice isPad] ? 14.0 : 12.0;
    label.font = [WPFontManager openSansRegularFontOfSize:fontSize];
    label.textColor = [self grey];
}

+ (void)applyPostStatusStyle:(UILabel *)label
{
    CGFloat fontSize = [UIDevice isPad] ? 14.0 : 12.0;
    label.font = [WPFontManager openSansRegularFontOfSize:fontSize];
    label.textColor = [self grey];
}

+ (void)applyPostMetaButtonStyle:(UIButton *)button
{
    CGFloat fontSize = [UIDevice isPad] ? 14.0 : 12.0;
    [button setTitleColor:[self grey] forState:UIControlStateNormal];
    [button setTitleColor:[self jazzyOrange] forState:UIControlStateSelected];
    [button.titleLabel setFont:[WPFontManager openSansRegularFontOfSize:fontSize]];
}


#pragma mark - Attributed String Attributes

+ (NSDictionary *)postCardAuthorSiteAttributes
{
    CGFloat fontSize = 14.0;
    CGFloat lineHeight = 20.0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:fontSize]};
}

+ (NSDictionary *)postCardAuthorNameAttributes
{
    CGFloat fontSize = 12.0;
    CGFloat lineHeight = 18.0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:fontSize]};
}

+ (NSDictionary *)postCardTitleAttributes
{
    CGFloat fontSize = [UIDevice isPad] ? 24.0 : 20.0;
    CGFloat lineHeight = [UIDevice isPad] ? 32.0 : 28.0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:fontSize]};
}

+ (NSDictionary *)postCardSnippetAttributes
{
    CGFloat fontSize = [UIDevice isPad] ? 16.0 : 14.0;
    CGFloat lineHeight = [UIDevice isPad] ? 24.0 : 20.0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:fontSize]};
}

+ (NSDictionary *)postCardDateAttributes
{
    CGFloat fontSize = [UIDevice isPad] ? 14.0 : 12.0;
    CGFloat lineHeight = [UIDevice isPad] ? 21.0 : 18.0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:fontSize]};
}

+ (NSDictionary *)postCardStatusAttributes
{
    CGFloat fontSize = [UIDevice isPad] ? 14.0 : 12.0;
    CGFloat lineHeight = [UIDevice isPad] ? 21.0 : 18.0;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:fontSize]};
}

@end
