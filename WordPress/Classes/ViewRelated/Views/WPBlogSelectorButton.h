#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPBlogSelectorButtonStyle)
{
    WPBlogSelectorButtonTypeStacked = 0,
    WPBlogSelectorButtonTypeSingleLine
};

@interface WPBlogSelectorButton : UIButton

@property (nonatomic, assign) WPBlogSelectorButtonStyle buttonStyle;
@property (nonatomic, assign) BOOL isReadOnly;

+ (id)buttonWithFrame:(CGRect)frame buttonStyle:(WPBlogSelectorButtonStyle)buttonStyle;

@end
