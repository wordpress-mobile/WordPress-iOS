// For some reason, and only in some files, the modular import does not work.
// Just to be on the safe side, _all_ imports use the angle brackets style.
// We shall try to go back to the modular style on Keystone successfully builds for testing.
// @import WordPressData;
#import <WordPressData/WordPressData.h>
#import "Menu+ViewDesign.h"

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const MenusDesignItemIconSize;

/**
 * Design category for providing common values used for drawing, layout, and views involving a MenuItem object.
 */
@interface MenuItem (ViewDesign)

+ (UIImage *)iconImageForItemType:(NSString *)itemType;

@end

NS_ASSUME_NONNULL_END
