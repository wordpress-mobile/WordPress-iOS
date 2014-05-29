#import <UIKit/UIKit.h>

@interface WPNUXUtility : NSObject

+ (UIFont *)textFieldFont;
+ (UIFont *)descriptionTextFont;
+ (UIFont *)titleFont;
+ (UIFont *)swipeToContinueFont;
+ (UIFont *)tosLabelFont;
+ (UIFont *)confirmationLabelFont;
+ (UIFont *)tosLabelSmallerFont;

+ (UIColor *)bottomPanelLineColor;
+ (UIColor *)descriptionTextColor;
+ (UIColor *)bottomPanelBackgroundColor;
+ (UIColor *)swipeToContinueTextColor;
+ (UIColor *)confirmationLabelColor;
+ (UIColor *)backgroundColor;
+ (UIColor *)tosLabelColor;

+ (void)centerViews:(NSArray *)controls withStartingView:(UIView *)startingView andEndingView:(UIView *)endingView forHeight:(CGFloat)viewHeight;
+ (void)configurePageControlTintColors:(UIPageControl *)pageControl;
+ (NSDictionary *)titleAttributesWithColor:(UIColor *)color;

@end
