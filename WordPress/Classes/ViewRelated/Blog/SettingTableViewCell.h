#import <WordPressShared/WPTableViewCell.h>

@interface SettingTableViewCell : WPTableViewCell

- (instancetype)initWithLabel:(NSString *)label editable:(BOOL)editable reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, copy) NSString *textValue;

@end
