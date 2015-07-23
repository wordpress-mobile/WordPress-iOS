#import "SettingsTextViewController.h"
#import "WPTextFieldTableViewCell.h"
#import "WPStyleGuide.h"

static NSString * const SiteTitleTextCell = @"SiteTitleTextCell";

@interface SettingsTextViewController()

@property (nonatomic, strong) WPTextFieldTableViewCell *textFieldCell;
@property (nonatomic, strong) UIView *hintView;

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

- (UIView *)hintView
{
    if (_hintView) {
        return _hintView;
    }
    CGFloat horizontalMargin = 15.0f;
    CGFloat verticalMargin = 10.0f;
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = _hint;
    hintLabel.font = [WPStyleGuide subtitleFont];
    hintLabel.textColor = [WPStyleGuide greyDarken20];
    hintLabel.numberOfLines = 0;
    CGSize size = [hintLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-(2*horizontalMargin), CGFLOAT_MAX)];
    hintLabel.frame = CGRectMake(horizontalMargin, verticalMargin, size.width, size.height);

    _hintView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, hintLabel.frame.size.height+(2*verticalMargin))];
    [_hintView addSubview:hintLabel];
    return _hintView;
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return self.hintView;
}

@end
