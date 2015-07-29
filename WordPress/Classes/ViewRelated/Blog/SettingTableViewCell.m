#import "SettingTableViewCell.h"

@implementation SettingTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithLabel:@"" editable:YES reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithLabel:(NSString *)label editable:(BOOL)editable reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.text = label;
        [WPStyleGuide configureTableViewCell:self];
        self.detailTextLabel.textColor = [WPStyleGuide grey];
        if (editable) {
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            self.selectionStyle = UITableViewCellSelectionStyleDefault;
        } else {
            self.accessoryType = UITableViewCellAccessoryNone;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    return self;
}

- (void)setTextValue:(NSString *)value
{
    self.detailTextLabel.text = value;
}

- (NSString *)textValue
{
    return self.detailTextLabel.text;
}

@end
