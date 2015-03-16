#import "WPStyleGuide+Posts.h"
#import <WordPress-iOS-Shared/WPFontManager.h>


@implementation WPStyleGuide (Posts)

#pragma mark - View Styles

+ (void)applyPostCardStyle:(UITableViewCell *)cell
{
    cell.backgroundColor = [self greyLighten30];
    cell.contentView.backgroundColor = [self greyLighten30];
}

+ (void)applyPostAuthorSiteStyle:(UILabel *)label
{
    label.font = [WPFontManager openSansRegularFontOfSize:14.0];
    label.textColor = [self grey];
}

+ (void)applyPostAuthorNameStyle:(UILabel *)label
{
    label.font = [WPFontManager openSansRegularFontOfSize:12.0];
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
    label.font = [WPFontManager openSansRegularFontOfSize:12.0];
    label.textColor = [self grey];
}

+ (void)applyPostStatusStyle:(UILabel *)label
{
    label.font = [WPFontManager openSansRegularFontOfSize:12.0];
    label.textColor = [self grey];
}

+ (void)applyPostMetaButtonStyle:(UIButton *)button
{
    [button setTitleColor:[self grey] forState:UIControlStateNormal];
    [button setTitleColor:[self jazzyOrange] forState:UIControlStateSelected];
    [button.titleLabel setFont:[WPFontManager openSansRegularFontOfSize:12.0]];
}


#pragma mark - Attributed String Attributes

+ (NSDictionary *)postCardAuthorSiteAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 20;
    paragraphStyle.maximumLineHeight = 20;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:14.0]};
}

+ (NSDictionary *)postCardAuthorNameAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = 18;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:12.0]};
}

+ (NSDictionary *)postCardTitleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 28;
    paragraphStyle.maximumLineHeight = 28;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:20.0]};
}

+ (NSDictionary *)postCardSnippetAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 20;
    paragraphStyle.maximumLineHeight = 20;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:14.0]};
}

+ (NSDictionary *)postCardDateAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = 18;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:12.0]};
}

+ (NSDictionary *)postCardStatusAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = 18;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPFontManager openSansRegularFontOfSize:12.0]};
}

@end
