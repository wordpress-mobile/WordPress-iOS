#import "SettingsTextViewController.h"
#import "WPTextFieldTableViewCell.h"
#import "WPStyleGuide.h"

static CGFloat const HorizontalMargin = 15.0f;

@interface SettingsTextViewController()

@property (nonatomic, strong) WPTableViewCell *textFieldCell;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSString *hint;
@property (nonatomic, assign) BOOL isPassword;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) NSString *text;

@end

@implementation SettingsTextViewController

- (instancetype)initWithText:(NSString *)text
                 placeholder:(NSString *)placeholder
                        hint:(NSString *)hint
                  isPassword:(BOOL)isPassword
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
    [self.textField becomeFirstResponder];
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (WPTableViewCell *)textFieldCell
{
    if (_textFieldCell) {
        return _textFieldCell;
    }
    _textFieldCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectInset(_textFieldCell.bounds, HorizontalMargin, 0)];
    self.textField.clearButtonMode = UITextFieldViewModeAlways;
    self.textField.font = [WPStyleGuide tableviewTextFont];
    self.textField.textColor = [WPStyleGuide darkGrey];
    self.textField.text = self.text;
    self.textField.placeholder = self.placeholder;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.keyboardType = UIKeyboardTypeDefault;
    self.textField.secureTextEntry = self.isPassword;
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [_textFieldCell.contentView addSubview:self.textField];
    
    return _textFieldCell;
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.onValueChanged && ![self.textField.text isEqualToString:self.text]) {
        self.onValueChanged(self.textField.text);
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
    return self.hint;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
}

@end
