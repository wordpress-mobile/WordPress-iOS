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
    [self setupModalButtonsIfNeeded];
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
    
    if (self.onValueChanged && ![self.textField.text isEqualToString:self.text] && self.textPassesValidation) {
        self.onValueChanged(self.textField.text);
    }
}


#pragma mark - Helpers

- (void)setupModalButtonsIfNeeded
{
    // Proceed only if this is the only VC in the current navigationController
    if (self.isBeingPresented == true || self.isModal == false) {
        return;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelButtonWasPressed:)];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneButtonWasPressed:)];
}

- (IBAction)cancelButtonWasPressed:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)doneButtonWasPressed:(id)sender
{
    if (self.textPassesValidation == false) {
        [self displayValidationAlert];
    } else if (self.isRootInNavigation && self.isModal) {
        [self dismissViewControllerAnimated:true completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - Validation

- (void)displayValidationAlert
{
    NSString *title = NSLocalizedString(@"Invalid Email", @"Invalid Email");
    NSString *message = NSLocalizedString(@"Please, enter a valid email", @"Text displayed whenever an invalid email is entered.");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addDefaultActionWithTitle:NSLocalizedString(@"Accept", @"Accept") handler:nil];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)textPassesValidation
{
    return (self.isEmail == false || (self.isEmail && self.textField.text.isValidEmail));
}


#pragma mark - Properties

- (BOOL)isPassword
{
    return self.textField.secureTextEntry;
}

- (void)setIsPassword:(BOOL)isPassword
{
    self.textField.secureTextEntry = isPassword;
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
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textField.delegate = self;
    
    [_textFieldCell.contentView addSubview:self.textField];
    
    return _textFieldCell;
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
    if (indexPath.section == 0 && indexPath.row == 0) {
        return self.textFieldCell;
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return self.hintView;
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSRange newLineRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];    
    if (newLineRange.location != NSNotFound) {
        [self.navigationController popViewControllerAnimated:YES];
    }

    if ([string isEqualToString:@"\n"]) {
        [self doneButtonWasPressed:self];
    }
    
    return YES;
}

@end
