#import <UIKit/UIKit.h>

@class WPNoResultsView;
@protocol WPNoResultsViewDelegate <NSObject>

@optional
- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView;
@end

@interface WPNoResultsView : UIView

@property (nonatomic, weak) id<WPNoResultsViewDelegate> delegate;

+ (WPNoResultsView *)noResultsViewWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView buttonTitle:(NSString *)buttonTitle;

- (void)setupWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView buttonTitle:(NSString *)buttonTitle;
- (void)showInView:(UIView *)view;
- (void)centerInSuperview;

- (void)setTitleText:(NSString *)title;
- (void)setMessageText:(NSString *)message;

@end
