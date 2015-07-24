#import "WPTableViewCell.h"

@interface SettingTableViewCell : WPTableViewCell

- (instancetype)initWithLabel:(NSString *)label editable:(BOOL)editable reuseIdentifier:(NSString *)reuseIdentifier  NS_DESIGNATED_INITIALIZER;

- (void)setTextValue:(NSString *)value;

- (NSString *)textValue;

@end
