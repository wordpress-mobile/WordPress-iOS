#import <Foundation/Foundation.h>
#import <WordPressUIKit/WPStyleGuide.h>
#import "WPButtonForNavigationBar.h"


NS_ASSUME_NONNULL_BEGIN

@interface WPStyleGuide (Posts)

+ (UIColor *)postListSearchBarTextColor;

+ (UIColor *)postCardBorderColor;

+ (void)applyPostAuthorFilterStyle:(UISegmentedControl *)segmentControl;

+ (void)applyPostCardStyle:(UITableViewCell *)cell;

+ (void)applyPostAuthorSiteStyle:(UILabel *)label;

+ (void)applyPostAuthorNameStyle:(UILabel *)label;

+ (void)applyPostTitleStyle:(UILabel *)label;

+ (void)applyPostSnippetStyle:(UILabel *)label;

+ (void)applyPostDateStyle:(UILabel *)label;

+ (void)applyPostStatusStyle:(UILabel *)label;

+ (void)applyPostMetaButtonStyle:(UIButton *)button;

+ (void)applyRestorePostLabelStyle:(UILabel *)label;

+ (void)applyRestorePostButtonStyle:(UIButton *)button;


+ (NSDictionary *)postCardAuthorSiteAttributes;

+ (NSDictionary *)postCardAuthorNameAttributes;

+ (NSDictionary *)postCardTitleAttributes;

+ (NSDictionary *)postCardSnippetAttributes;

+ (NSDictionary *)postCardDateAttributes;

+ (NSDictionary *)postCardStatusAttributes;


+ (CGRect)navigationBarButtonRect;

+ (CGFloat)spacingBetweeenNavbarButtons;

+ (WPButtonForNavigationBar*)buttonForBarWithImage:(UIImage *)image
                                            target:(id)target
                                          selector:(SEL)selector;


#pragma mark - Pages

+ (void)applyPageTitleStyle:(UILabel *)label;

+ (NSDictionary *)pageCellTitleAttributes;

+ (void)applySectionHeaderTitleStyle:(UILabel *)label;

+ (void)applyRestorePageLabelStyle:(UILabel *)label;

+ (void)applyRestorePageButtonStyle:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
