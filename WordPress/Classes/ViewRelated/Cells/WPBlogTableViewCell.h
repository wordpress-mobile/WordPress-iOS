#import <WordPressShared/WPTableViewCell.h>

@interface WPBlogTableViewCell : WPTableViewCell

@property (nonatomic, weak, nullable) UISwitch *visibilitySwitch;
@property (nonatomic, copy, nullable) void (^visibilitySwitchToggled)(WPBlogTableViewCell *cell);

@end
