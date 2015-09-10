#import "SwitchSettingTableViewCell.h"

@interface SwitchSettingTableViewCell()

@property (nonatomic, strong) UISwitch *switchComponent;

@end

@implementation SwitchSettingTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithLabel:@"" target:nil action:nil reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithLabel:(NSString *)label target:(id)target action:(SEL)action reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.text = label;
        [WPStyleGuide configureTableViewCell:self];
        _switchComponent = [[UISwitch alloc] init];
        if (target && action) {
            [_switchComponent addTarget:target action:action forControlEvents:UIControlEventValueChanged];
        }
        self.accessoryView = _switchComponent;
    }
    return self;
}

- (void)setSwitchValue:(BOOL)value
{
    _switchComponent.on = value;
}

- (BOOL)textValue
{
    return _switchComponent.on;
}

@end
