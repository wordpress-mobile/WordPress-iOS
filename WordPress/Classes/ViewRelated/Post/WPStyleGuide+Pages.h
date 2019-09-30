#import <Foundation/Foundation.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WPButtonForNavigationBar.h"


NS_ASSUME_NONNULL_BEGIN

@interface WPStyleGuide (Pages)

#pragma mark - Pages

+ (void)applyRestorePageLabelStyle:(UILabel *)label;

+ (void)applyRestorePageButtonStyle:(UIButton *)button;

#pragma mark - Reader Posts

+ (void)applyRestoreSavedPostLabelStyle:(UILabel *)label;

+ (void)applyRestoreSavedPostTitleLabelStyle:(UILabel *)label;

+ (void)applyRestoreSavedPostButtonStyle:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
