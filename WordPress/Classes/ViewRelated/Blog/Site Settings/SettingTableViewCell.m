#import "SettingTableViewCell.h"
#import "WordPress-Swift.h"

NSString * const SettingsTableViewCellReuseIdentifier = @"org.wordpress.SettingTableViewCell";

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
        self.detailTextLabel.textColor = [UIColor murielTextSubtle];
        [self setEditable:editable];
    }
    return self;
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    if (editable) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
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
