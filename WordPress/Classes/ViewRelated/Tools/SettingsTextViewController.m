#import "SettingsTextViewController.h"
#import <WordPressShared/WPTextFieldTableViewCell.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"



#pragma mark - Constants

static CGFloat const SettingsTextHorizontalMargin = 15.0f;

typedef NS_ENUM(NSInteger, SettingsTextSections) {
    SettingsTextSectionsTextfield = 0,
    SettingsTextSectionsAction,
    SettingsTextSectionsCount
};

#pragma mark - Private Properties

@interface SettingsTextViewController() <UITextFieldDelegate>
@property (nonatomic, strong) NoticeAnimator    *noticeAnimator;
@property (nonatomic, strong) WPTableViewCell   *textFieldCell;
@property (nonatomic, strong) WPTableViewCell   *actionCell;
@property (nonatomic, strong) UITextField       *textField;
@property (nonatomic, assign) BOOL              doneButtonEnabled;
@property (nonatomic, assign) BOOL              shouldNotifyValue;
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

        [self configureInstance];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureInstance];
    }

    return self;
}

- (void)configureInstance
{
    _autocorrectionType = UITextAutocorrectionTypeDefault;
    _shouldNotifyValue = YES;
    _validatesInput = YES;
}



#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.shouldNotifyValue = YES;

    [self startListeningTextfieldChanges];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupNoticeAnimatorIfNeeded];
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
    
    if (self.shouldNotifyValue) {
        [self notifyValueDidChangeIfNeeded];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.noticeAnimator layout];
}


#pragma mark - NavigationItem Buttons

- (void)cancel
{
    self.shouldNotifyValue = NO;
    [self dismissViewController];
}

- (void)confirm
{
    [self dismissViewController];
}

- (void)setupNoticeAnimatorIfNeeded
{
    if (self.notice == nil) {
        return;
    }
    
    self.noticeAnimator = [[NoticeAnimator alloc] initWithTarget:self.view];
    [self.noticeAnimator animateMessage:self.notice];
}


#pragma mark - Validation

- (void)startListeningTextfieldChanges
{
    // Hook up to Change Events
    [_textField addTarget:self action:@selector(validateTextInput:) forControlEvents:UIControlEventEditingChanged];
    
    // Fire initial status
    [self validateTextInput:_textField];
}

- (BOOL)textPassesValidation
{
    BOOL isEmail = (self.mode == SettingsTextModesEmail);
    return (self.validatesInput == false || isEmail == false || (isEmail && self.textField.text.isValidEmail));
}

- (void)validateTextInput:(id)sender
{
    self.doneButtonEnabled = [self textPassesValidation];
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
    _textFieldCell.selectionStyle = UITableViewCellSelectionStyleNone;
    [_textFieldCell.contentView addSubview:self.textField];

    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    UILayoutGuide *readableGuide = _textFieldCell.contentView.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                               [self.textField.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                               [self.textField.topAnchor constraintEqualToAnchor:_textFieldCell.contentView.topAnchor],
                                               [self.textField.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                               [self.textField.bottomAnchor constraintEqualToAnchor:_textFieldCell.contentView.bottomAnchor],
                                               ]];

    return _textFieldCell;
}

- (WPTableViewCell *)actionCell
{
    if (_actionCell) {
        return _actionCell;
    }
    _actionCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    _actionCell.frame = CGRectInset(_actionCell.bounds, SettingsTextHorizontalMargin, 0);
    _actionCell.textLabel.text = self.actionText;
    _actionCell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    [WPStyleGuide configureTableViewActionCell:_actionCell];
    
    return _actionCell;
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
    _textField.delegate = self;
    _textField.autocorrectionType = self.autocorrectionType;
    
    return _textField;
}


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _displaysActionButton ? SettingsTextSectionsCount : SettingsTextSectionsCount - 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SettingsTextSectionsTextfield) {
        return self.textFieldCell;
    }
    
    return self.actionCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section != SettingsTextSectionsTextfield) {
        return nil;
    }
    return self.hint;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectSelectedRowWithAnimation:YES];
    
    if (indexPath.section == SettingsTextSectionsAction && self.onActionPress != nil) {
        self.onActionPress();
        [self dismissViewController];
    }
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
    UITextAutocapitalizationType autocapitalizationType = UITextAutocapitalizationTypeSentences;

    if (newMode == SettingsTextModesLowerCaseText) {
        autocapitalizationType = UITextAutocapitalizationTypeNone;
    } else if (newMode == SettingsTextModesPassword) {
        requiresSecureTextEntry = YES;
    } else if (newMode == SettingsTextModesEmail) {
        keyboardType = UIKeyboardTypeEmailAddress;
        autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    
    self.textField.autocapitalizationType = autocapitalizationType;
    self.textField.keyboardType = keyboardType;
    self.textField.secureTextEntry = requiresSecureTextEntry;
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL isValid = self.textPassesValidation;
    if (isValid) {
        [self confirm];
    }
    
    return isValid;
}

@end
