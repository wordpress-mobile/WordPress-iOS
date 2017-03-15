#import "SettingsMultiTextViewController.h"
#import "WPStyleGuide.h"
#import "WPTableViewCell.h"

static CGVector const SettingsTextPadding = {11.0f, 3.0f};
static CGFloat const SettingsMinHeight = 41.0f;

@interface SettingsMultiTextViewController() <UITextViewDelegate>

@property (nonatomic, strong) UITableViewCell *textViewCell;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation SettingsMultiTextViewController

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
    [self.textView becomeFirstResponder];
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.allowsSelection = NO;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self adjustCellSize];
    });
}

- (UITableViewCell *)textViewCell
{
    if (_textViewCell) {
        return _textViewCell;
    }
    _textViewCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    _textViewCell.selectionStyle = UITableViewCellSelectionStyleNone;

    UITextView *textView = [[UITextView alloc] init];
    textView.text = self.text;
    textView.returnKeyType = UIReturnKeyDefault;
    textView.keyboardType = UIKeyboardTypeDefault;
    textView.secureTextEntry = self.isPassword;
    textView.font = [WPStyleGuide tableviewTextFont];
    textView.textColor = [WPStyleGuide darkGrey];
    textView.delegate = self;
    textView.scrollEnabled = NO;

    UIEdgeInsets textInset = textView.textContainerInset;
    textInset.left = 0.0;
    textInset.right = 0.0;
    textView.textContainerInset = textInset;
    textView.textContainer.lineFragmentPadding = 0.0;

    [_textViewCell.contentView addSubview:textView];
    textView.translatesAutoresizingMaskIntoConstraints = NO;

    UILayoutGuide *readableGuide = _textViewCell.contentView.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                              [textView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                              [textView.topAnchor constraintEqualToAnchor:_textViewCell.contentView.topAnchor],
                                              [textView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                              [textView.bottomAnchor constraintEqualToAnchor:_textViewCell.contentView.bottomAnchor],
                                              ]];
    self.textView = textView;

    return _textViewCell;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.onValueChanged) {
        self.onValueChanged(self.textView.text);
    }
    [super viewWillDisappear:animated];
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
        return self.textViewCell;
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

- (void)textViewDidChange:(UITextView *)textView
{
    [self adjustCellSize];
}

- (void)adjustCellSize
{
    CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, CGFLOAT_MAX)];
    CGFloat height = size.height;

    if (fabs(self.tableView.rowHeight - height) > (self.textView.font.lineHeight * 0.5f))
    {
        [self.tableView beginUpdates];
        self.tableView.rowHeight = MAX(height, SettingsMinHeight) + SettingsTextPadding.dy;
        [self.tableView endUpdates];
    }
}

@end
