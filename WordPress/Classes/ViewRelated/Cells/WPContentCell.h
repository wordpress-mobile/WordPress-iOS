#import <UIKit/UIKit.h>

#import "WPTableViewCell.h"
#import "WPContentViewProvider.h"

@interface WPContentCell : WPTableViewCell

@property (nonatomic, strong) id<WPContentViewProvider> contentProvider;

+ (CGFloat)rowHeightForContentProvider:(id<WPContentViewProvider>)contentProvider andWidth:(CGFloat)width;
+ (BOOL)shortDateString;
+ (BOOL)showGravatarImage;
+ (BOOL)supportsUnreadStatus;
+ (UIFont *)statusFont;
+ (NSDictionary *)statusAttributes;
+ (NSString *)statusTextForContentProvider:(id<WPContentViewProvider>)contentProvider;
+ (UIColor *)statusColorForContentProvider:(id<WPContentViewProvider>)contentProvider;
+ (UIFont *)titleFont;
+ (NSDictionary *)titleAttributes;
+ (NSDictionary *)titleAttributesBold;
+ (NSAttributedString *)titleAttributedTextForContentProvider:(id<WPContentViewProvider>)contentProvider;
+ (UIFont *)dateFont;
+ (NSDictionary *)dateAttributes;
+ (NSString *)dateTextForContentProvider:(id<WPContentViewProvider>)contentProvider;


@end
