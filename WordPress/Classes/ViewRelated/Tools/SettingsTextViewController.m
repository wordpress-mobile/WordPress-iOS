#import "SettingsTextViewController.h"
#import "WPTextFieldTableViewCell.h"
#import "WPStyleGuide.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "WordPress-Swift.h"



#pragma mark - Constants

static CGFloat const HorizontalMargin = 15.0f;


#pragma mark - Private Properties

@interface SettingsTextViewController() <UITextFieldDelegate>
@property (nonatomic, strong) WPTableViewCell   *textFieldCell;
@property (nonatomic, strong) UITextField       *textField;
@property (nonatomic, strong) UIView            *hintView;
@property (nonatomic, strong) NSString          *hint;
@property (nonatomic, strong) NSString          *placeholder;
@property (nonatomic, strong) NSString          *text;
@end


#pragma mark - SettingsTextViewController

@implementation SettingsTextViewController

- (void)dealloc
{
    _textField.delegate = nil;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self initWithText:@"" placeholder:@"" hint:@""];
}

- (instancetype)initWithText:(NSString *)text placeholder:(NSString *)placeholder hint:(NSString *)hint
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _text = text;
        _placeholder = placeholder;
        _hint = hint;
    }
    return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupNavigationButtonsIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    
    if (self.displaysNavigationButtons == NO) {
        [self notifyValueDidChangeIfNeeded];
    }
}


#pragma mark - NavigationItem Buttons

- (void)setupNavigationButtonsIfNeeded
{
    if (self.displaysNavigationButtons == NO) {
        return;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelButtonWasPressed:)];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneButtonWasPressed:)];
    
    [_textField addTarget:self action:@selector(validateTextInput:) forControlEvents:UIControlEventEditingChanged];
}

- (IBAction)cancelButtonWasPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)doneButtonWasPressed:(id)sender
{
    [self notifyValueDidChangeIfNeeded];
    [self dismissViewController];
}


#pragma mark - Validation

- (BOOL)textPassesValidation
{
    BOOL isEmail = (self.mode == SettingsTextModesEmail);
    return (isEmail == false || (isEmail && self.textField.text.isValidEmail));
}

- (void)validateTextInput:(id)sender
{
    self.navigationItem.rightBarButtonItem.enabled = [self textPassesValidation];
}


#pragma mark - Properties

- (void)setMode:(SettingsTextModes)mode
{
    _mode = mode;
    [self updateModeSettings:mode];
}

- (WPTableViewCell *)textFieldCell
{
    if (_textFieldCell) {
        return _textFieldCell;
    }
    _textFieldCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [_textFieldCell.contentView addSubview:self.textField];
    _textField.frame = CGRectInset(_textFieldCell.bounds, HorizontalMargin, 0);
    
    return _textFieldCell;
}

- (UITextField *)textField
{
    if (_textField) {
        return _textField;
    }
    
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    _textField.clearButtonMode = UITextFieldViewModeAlways;
    _textField.font = [WPStyleGuide tableviewTextFont];
    _textField.textColor = [WPStyleGuide darkGrey];
    _textField.text = self.text;
    _textField.placeholder = self.placeholder;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.keyboardType = UIKeyboardTypeDefault;
    _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textField.delegate = self;

    return _textField;
}

- (UIView *)hintView
{
    if (_hintView) {
        return _hintView;
    }
    
    WPTableViewSectionHeaderFooterView *footerView = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleFooter];
    [footerView setTitle:_hint];
    _hintView = footerView;
    return _hintView;
}


#pragma mark - UITableViewDelegate

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
    return self.textFieldCell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return self.hintView;
}


#pragma mark - Helpers

- (void)dismissViewController
{
    if (self.isModal) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)notifyValueDidChangeIfNeeded
{
    if (self.onValueChanged == nil || [self.textField.text isEqualToString:self.text]) {
        return;
    }
    
    self.onValueChanged(self.textField.text);
}


- (void)updateModeSettings:(SettingsTextModes)newMode
{
    BOOL requiresSecureTextEntry = NO;
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    
    if (newMode == SettingsTextModesPassword) {
        requiresSecureTextEntry = YES;
        keyboardType = UIKeyboardTypeEmailAddress;
    }
    
    self.textField.keyboardType = keyboardType;
    self.textField.secureTextEntry = requiresSecureTextEntry;
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL isValid = self.textPassesValidation;
    if (isValid) {
        [self doneButtonWasPressed:self];
    }
    
    return isValid;
}

@end
