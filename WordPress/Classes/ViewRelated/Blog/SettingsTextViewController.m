#import "SettingsTextViewController.h"
#import "WPTextFieldTableViewCell.h"
#import "WPStyleGuide.h"

static CGFloat const HorizontalMargin = 15.0f;
static CGFloat const VerticalMargin = 10.0f;

@interface SettingsTextViewController()

@property (nonatomic, strong) WPTableViewCell *textFieldCell;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIView *hintView;
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

- (UIView *)hintView
{
    if (_hintView) {
        return _hintView;
    }
    CGFloat horizontalMargin = HorizontalMargin;
    CGFloat verticalMargin = VerticalMargin;
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = _hint;
    hintLabel.font = [WPStyleGuide subtitleFont];
    hintLabel.textColor = [WPStyleGuide greyDarken20];
    hintLabel.numberOfLines = 0;
    CGSize size = [hintLabel sizeThatFits:CGSizeMake(self.view.frame.size.width -( 2 * horizontalMargin), CGFLOAT_MAX)];
    if (IS_IPAD && self.tableView.frame.size.width > WPTableViewFixedWidth) {
        horizontalMargin += (self.tableView.frame.size.width - WPTableViewFixedWidth)/2;
    }

    hintLabel.frame = CGRectIntegral(CGRectMake(horizontalMargin, verticalMargin, size.width, size.height));
    _hintView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, hintLabel.frame.size.height+(2*verticalMargin))];
    [_hintView addSubview:hintLabel];
    return _hintView;
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.onValueChanged) {
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return self.hintView;
}

@end
