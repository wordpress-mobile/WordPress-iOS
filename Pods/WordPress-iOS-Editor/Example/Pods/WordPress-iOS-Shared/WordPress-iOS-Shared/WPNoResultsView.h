#import <UIKit/UIKit.h>

@class WPNoResultsView;
@protocol WPNoResultsViewDelegate <NSObject>

@optional
- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView;
@end

@interface WPNoResultsView : UIView

@property (nonatomic, strong) NSString                      *titleText;
@property (nonatomic, strong) NSString                      *messageText;
@property (nonatomic, strong) NSString                      *buttonTitle;
@property (nonatomic, strong) UIView                        *accessoryView;
@property (nonatomic,   weak) id<WPNoResultsViewDelegate>   delegate;

+ (instancetype)noResultsViewWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView buttonTitle:(NSString *)buttonTitle;

- (void)showInView:(UIView *)view;
- (void)centerInSuperview;

@end
