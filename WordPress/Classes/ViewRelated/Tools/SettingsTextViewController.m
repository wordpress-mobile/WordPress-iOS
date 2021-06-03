#import "SettingsTextViewController.h"
#import <WordPressShared/WPTextFieldTableViewCell.h>
#import <WordPressShared/WPStyleGuide.h>
#import <WordPressUI/WordPressUI.h>
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
@property (nonatomic, strong) MessageAnimator    *messageAnimator;
@property (nonatomic, strong) WPTableViewCell   *textFieldCell;
@property (nonatomic, strong) WPTableViewCell   *actionCell;
@property (nonatomic, strong) UITextField       *textField;
@property (nonatomic, assign) BOOL              doneButtonEnabled;
@property (nonatomic, assign) BOOL              shouldNotifyValue;
@property (nonatomic, strong) NSString          *originalString;
@property (nonatomic, strong) NSAttributedString *originalAttributedString;
@property (nonatomic, copy) NSDictionary<NSAttributedStringKey, id> *defaultAttributes;
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
        [self commonInitWithPlaceholder:placeholder hint:hint];

        _originalString = (text && !text.isEmpty) ? text : @"";
        _originalAttributedString = [[NSAttributedString alloc] initWithString:_originalString];
        _textField.text = text;
    }
    return self;
}

- (instancetype)initWithAttributedText:(NSAttributedString *)text defaultAttributes:(NSDictionary<NSAttributedStringKey, id> *)defaultAttributes placeholder:(NSString *)placeholder hint:(NSString *)hint
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self commonInitWithPlaceholder:placeholder hint:hint];
        
        _originalString = text.string;
        _originalAttributedString = text;
        _textField.attributedText = text;
        _textField.allowsEditingTextAttributes = true;
        _textField.defaultTextAttributes = defaultAttributes;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInitWithPlaceholder:nil hint:nil];
    }

    return self;
}

- (void)configureInstance
{
    _autocorrectionType = UITextAutocorrectionTypeDefault;
    _shouldNotifyValue = YES;
    _validatesInput = YES;
}

- (void)commonInitWithPlaceholder:(NSString *)placeholder hint:(NSString *)hint
{
    [self createTextField];
    
    _textField.placeholder = placeholder;
    _hint = hint;
    
    [self configureInstance];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Don't auto-size rows
    self.tableView.estimatedRowHeight = 0;

    [self startListeningTextfieldChanges];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupMessageAnimatorIfNeeded];
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
        [self notifyValueChangedIfNecessary];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.messageAnimator layout];
}


#pragma mark - NavigationItem Buttons

- (void)setDisplaysNavigationButtons:(BOOL)displaysNavigationButtons
{
    if (displaysNavigationButtons) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(confirm)];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)cancel
{
    self.shouldNotifyValue = NO;
    [self dismissViewController];
}

- (void)confirm
{
    [self dismissViewController];
}

- (void)setupMessageAnimatorIfNeeded
{
    if (self.notice == nil) {
        return;
    }
    
    self.messageAnimator = [[MessageAnimator alloc] initWithTarget:self.view];
    [self.messageAnimator animateMessage:self.notice];
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
    return ([self.textField hasText] && (self.validatesInput == false || isEmail == false || (isEmail && self.textField.text.isValidEmail)));
}

- (void)validateTextInput:(id)sender
{
    self.doneButtonEnabled = [self textPassesValidation];
    [self setEnabledStateForCell:_actionCell value:self.doneButtonEnabled];
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
    [self setEnabledStateForCell:_actionCell value:self.doneButtonEnabled];

    return _actionCell;
}

- (void)createTextField
{
    NSAssert(_textField == nil, @"The text field has already been created.");
    
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    _textField.clearButtonMode = UITextFieldViewModeAlways;
    _textField.font = [WPStyleGuide tableviewTextFont];
    _textField.textColor = [UIColor murielNeutral70];
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.keyboardType = UIKeyboardTypeDefault;
    _textField.delegate = self;
    _textField.autocorrectionType = self.autocorrectionType;
}

#pragma mark - Getters

- (NSAttributedString *)attributedText
{
    return self.textField.attributedText;
}

- (NSString *)placeholder
{
    return self.textField.placeholder;
}

- (NSString *)text
{
    return self.textField.text;
}

#pragma mark - Setters

- (void)setAttributedText:(NSAttributedString *)text
{
    self.textField.attributedText = text;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.textField.placeholder = placeholder;
}

- (void)setText:(NSString *)text
{
    self.textField.text = text;
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
        [self dismissViewControllerAnimated:YES completion:self.onDismiss];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)notifyValueChangedIfNecessary
{
    if (self.onValueChanged != nil && ![_originalString isEqual:self.textField.text]) {
        self.onValueChanged(self.textField.text);
    }
    
    if (self.onAttributedValueChanged != nil && ![_originalAttributedString isEqual:self.textField.attributedText]) {
        self.onAttributedValueChanged(self.textField.attributedText);
    }
}


- (void)updateModeSettings:(SettingsTextModes)newMode
{
    BOOL requiresSecureTextEntry = NO;
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    UITextAutocapitalizationType autocapitalizationType = UITextAutocapitalizationTypeSentences;
    UITextAutocorrectionType autocorrectionType = UITextAutocorrectionTypeDefault;

    if (newMode == SettingsTextModesLowerCaseText) {
        autocapitalizationType = UITextAutocapitalizationTypeNone;
    } else if (newMode == SettingsTextModesPassword) {
        requiresSecureTextEntry = YES;
    } else if (newMode == SettingsTextModesNewPassword) {
        requiresSecureTextEntry = YES;
        if (@available(iOS 12.0, *)) {
            NSString *passwordDescriptor = @"required: lower; required: upper; required: digit; required: [&)*]]; minlength: 6; maxlength: 24;";
            self.textField.passwordRules = [UITextInputPasswordRules passwordRulesWithDescriptor:passwordDescriptor];
            self.textField.textContentType = UITextContentTypeNewPassword;
        }
    } else if (newMode == SettingsTextModesEmail) {
        keyboardType = UIKeyboardTypeEmailAddress;
        autocapitalizationType = UITextAutocapitalizationTypeNone;
    } else if (newMode == SettingsTextModesURL) {
        keyboardType = UIKeyboardTypeURL;
        autocapitalizationType = UITextAutocapitalizationTypeNone;
        autocorrectionType = UITextAutocorrectionTypeNo;
    }
    
    self.textField.autocapitalizationType = autocapitalizationType;
    self.textField.keyboardType = keyboardType;
    self.textField.secureTextEntry = requiresSecureTextEntry;
    
    self.autocorrectionType = autocorrectionType;
    self.textField.autocorrectionType = autocorrectionType;
}

- (void)setEnabledStateForCell:(UITableViewCell *)ActionCell value:(BOOL)value
{
    if (value) {
        [_actionCell enable];
    } else {
        [_actionCell disable];
    }
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
