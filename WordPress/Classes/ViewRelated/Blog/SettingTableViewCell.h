#import "WPTableViewCell.h"

@interface SettingTableViewCell : WPTableViewCell

- (instancetype)initWithLabel:(NSString *)label editable:(BOOL)editable reuseIdentifier:(NSString *)reuseIdentifier  NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) NSString *textValue;

@end
