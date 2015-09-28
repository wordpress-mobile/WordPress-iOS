#import "SettingsMultiTextViewController.h"
#import "WPStyleGuide.h"
#import "WPTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"

static CGFloat const HorizontalMargin = 10.0f;

@interface SettingsMultiTextViewController() <UITextViewDelegate>

@property (nonatomic, strong) UITableViewCell *textViewCell;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *hintView;
@property (nonatomic, strong) NSString *hint;
@property (nonatomic, assign) BOOL isPassword;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) NSString *text;

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
    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self adjustCellSize];
}

- (UITableViewCell *)textViewCell
{
    if (_textViewCell) {
        return _textViewCell;
    }
    _textViewCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    _textViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textView = [[UITextView alloc] initWithFrame:CGRectInset(self.textViewCell.bounds, HorizontalMargin, 0)];
    self.textView.text = self.text;
    self.textView.returnKeyType = UIReturnKeyDefault;
    self.textView.keyboardType = UIKeyboardTypeDefault;
    self.textView.secureTextEntry = self.isPassword;
    self.textView.font = [WPStyleGuide tableviewTextFont];
    self.textView.textColor = [WPStyleGuide darkGrey];
    self.textView.delegate = self;
    self.textView.scrollEnabled = NO;
    [_textViewCell.contentView addSubview:self.textView];
    
    return _textViewCell;
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

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.onValueChanged) {
        self.onValueChanged(self.textView.text);
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
        return self.textViewCell;
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return self.hintView;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self adjustCellSize];
}

- (void)adjustCellSize
{
    CGFloat widthAvailable = self.textViewCell.contentView.bounds.size.width - ( 2 * HorizontalMargin);
    CGSize size = [self.textView sizeThatFits:CGSizeMake(widthAvailable, CGFLOAT_MAX)];
    if (fabs(self.tableView.rowHeight - size.height) > (self.textView.font.lineHeight/2))
    {
        [self.tableView beginUpdates];
        self.textView.frame = CGRectMake(HorizontalMargin, 0, widthAvailable, size.height);
        self.tableView.rowHeight = size.height;
        [self.tableView endUpdates];
    }
}

@end
