#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPBlogSelectorButtonStyle)
{
    WPBlogSelectorButtonTypeStacked = 0,
    WPBlogSelectorButtonTypeSingleLine
};

typedef NS_ENUM(NSUInteger, WPBlogSelectorButtonMode) {
    WPBlogSelectorButtonSingleSite,
    WPBlogSelectorButtonMultipleSite,
};

@interface WPBlogSelectorButton : UIButton

@property (nonatomic, assign) WPBlogSelectorButtonStyle buttonStyle;
@property (nonatomic, assign) WPBlogSelectorButtonMode buttonMode;

+ (id)buttonWithFrame:(CGRect)frame buttonStyle:(WPBlogSelectorButtonStyle)buttonStyle;

@end
