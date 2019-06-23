#import <Foundation/Foundation.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WPButtonForNavigationBar.h"


NS_ASSUME_NONNULL_BEGIN

@interface WPStyleGuide (Posts)

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

#pragma mark - Reader Posts

+ (void)applyRestoreSavedPostLabelStyle:(UILabel *)label;

+ (void)applyRestoreSavedPostTitleLabelStyle:(UILabel *)label;

+ (void)applyRestoreSavedPostButtonStyle:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
