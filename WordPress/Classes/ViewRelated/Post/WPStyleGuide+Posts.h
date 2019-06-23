#import <Foundation/Foundation.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WPButtonForNavigationBar.h"


NS_ASSUME_NONNULL_BEGIN

@interface WPStyleGuide (Posts)

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
