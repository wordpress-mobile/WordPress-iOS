#import "SettingsTextViewController.h"
#import "WPTextFieldTableViewCell.h"
#import "WPStyleGuide.h"

static NSString * const SiteTitleTextCell = @"SiteTitleTextCell";

@interface SettingsTextViewController()

@property (nonatomic, strong) WPTextFieldTableViewCell *textFieldCell;
@property (nonatomic, strong) NSString *hint;
@property (nonatomic, assign) BOOL isPassword;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) NSString *text;

@end

@implementation SettingsTextViewController

- (instancetype)initWithText:(NSString *)text placeholder:(NSString *)placeholder hint:(NSString *)hint isPassword:(BOOL)isPassword
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _text = text;
        _placeholder = placeholder;
        _hint = hint;
        _isPassword = isPassword;
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self initWithText:@"" placeholder:@"" hint:@"" isPassword:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.textFieldCell.textField becomeFirstResponder];
    [super viewDidAppear:animated];
}

- (WPTextFieldTableViewCell *)textFieldCell
{
    if (_textFieldCell) {
        return _textFieldCell;
    }
    _textFieldCell = [[WPTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SiteTitleTextCell];
    _textFieldCell.textField.clearButtonMode = UITextFieldViewModeAlways;
    _textFieldCell.minimumLabelWidth = 0.0f;
    [WPStyleGuide configureTableViewTextCell:_textFieldCell];
    _textFieldCell.textField.text = self.text;
    _textFieldCell.textField.placeholder = self.placeholder;
    _textFieldCell.textField.returnKeyType = UIReturnKeyDone;
    _textFieldCell.textField.keyboardType = UIKeyboardTypeDefault;
    _textFieldCell.shouldDismissOnReturn = YES;
    _textFieldCell.textField.secureTextEntry = self.isPassword;
    
    return _textFieldCell;
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.hint;
    }
    return @"";
}

@end
