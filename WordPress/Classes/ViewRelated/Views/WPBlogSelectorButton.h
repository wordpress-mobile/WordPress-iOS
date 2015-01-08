#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPBlogSelectorButtonStyle)
{
    WPBlogSelectorButtonTypeStacked = 0,
    WPBlogSelectorButtonTypeSingleLine
};

@interface WPBlogSelectorButton : UIButton

@property (nonatomic, assign) WPBlogSelectorButtonStyle buttonStyle;

+ (id)buttonWithFrame:(CGRect)frame buttonStyle:(WPBlogSelectorButtonStyle)buttonStyle;

@end
