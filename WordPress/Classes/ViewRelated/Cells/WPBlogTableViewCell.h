#import <WordPressShared/WPTableViewCell.h>

NS_ASSUME_NONNULL_BEGIN;

@interface WPBlogTableViewCell : WPTableViewCell

@property (nonatomic, weak, nullable) UISwitch *visibilitySwitch;
@property (nonatomic, copy, nullable) void (^visibilitySwitchToggled)(WPBlogTableViewCell *cell);

+ (NSString *)reuseIdentifier;
+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END;
