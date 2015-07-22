#import "SettingsTextViewController.h"
#import "WPTextFieldTableViewCell.h"
#import "WPStyleGuide.h"

static NSString * const SiteTitleTextCell = @"SiteTitleTextCell";

@interface SettingsTextViewController()

@property (nonatomic, strong) WPTextFieldTableViewCell *textFieldCell;
@property (nonatomic, strong) NSString *hint;

@end

@implementation SettingsTextViewController

- (instancetype)initWithText:(NSString *)text placeholder:(NSString *)placeholder hint:(NSString *)hint isPassword:(BOOL)isPassword
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _textFieldCell = [[WPTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SiteTitleTextCell];
        _textFieldCell.textField.clearButtonMode = UITextFieldViewModeAlways;
        _textFieldCell.minimumLabelWidth = 0.0f;
        [WPStyleGuide configureTableViewTextCell:_textFieldCell];
        _textFieldCell.textField.text = text;
        _textFieldCell.textField.placeholder = placeholder;
        _textFieldCell.textField.returnKeyType = UIReturnKeyDone;
        _textFieldCell.textField.keyboardType = UIKeyboardTypeASCIICapable;
        [_textFieldCell.textField becomeFirstResponder];
        _textFieldCell.shouldDismissOnReturn = YES;
        _textFieldCell.textField.secureTextEntry = YES;
        _hint = hint;
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self initWithText:@"" placeholder:@"" hint:@"" isPassword:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.onValueChanged) {
        self.onValueChanged(self.textFieldCell.textField.text);
    }
    [super viewDidDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        return self.textFieldCell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"";
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.hint;
    }
    return @"";
}

@end
