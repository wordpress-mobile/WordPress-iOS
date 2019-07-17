#import "MenuItemLinkViewController.h"
#import "MenuItemCheckButtonView.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

static CGFloat const LinkTextBarHeight = 48.0;

@interface MenuItemLinkViewController () <MenuItemSourceTextBarDelegate>

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) MenuItemSourceTextBar *textBar;
@property (nonatomic, strong, readonly) MenuItemCheckButtonView *checkButtonView;

@end

@implementation MenuItemLinkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupLabel];
    [self setupTextBar];
    [self setupCheckButtonView];
}

- (void)setupLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = [NSLocalizedString(@"Link Address (URL)", @"Menus title label when editing a menu item as a link.") uppercaseString];
    label.textColor = [UIColor murielNeutral40];
    label.font = [WPFontManager systemSemiBoldFontOfSize:12.0];

    [self.stackView addArrangedSubview:label];
    _label = label;
}

- (void)setupTextBar
{
    MenuItemSourceTextBar *textBar = [[MenuItemSourceTextBar alloc] init];
    textBar.translatesAutoresizingMaskIntoConstraints = NO;
    textBar.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textBar.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textBar.textField.keyboardType = UIKeyboardTypeURL;
    textBar.delegate = self;
    [self.stackView addArrangedSubview:textBar];

    NSLayoutConstraint *heightConstraint = [textBar.heightAnchor constraintEqualToConstant:LinkTextBarHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;

    [textBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    _textBar = textBar;
}

- (void)setupCheckButtonView
{
    MenuItemCheckButtonView *checkButtonView = [[MenuItemCheckButtonView alloc] init];
    checkButtonView.label.text = NSLocalizedString(@"Open link in new window/tab", @"Menus label for checkbox when editig item as a link.");
    __weak __typeof__(self) weakSelf = self;
    checkButtonView.onChecked = ^() {
        [weakSelf updateItemLinkTargetOption];
    };
    [self.stackView addArrangedSubview:checkButtonView];

    NSLayoutConstraint *heightConstraint = [checkButtonView.heightAnchor constraintEqualToConstant:[checkButtonView preferredHeightForLayout]];
    heightConstraint.active = YES;

    _checkButtonView = checkButtonView;
}

- (NSString *)sourceItemType
{
    return MenuItemTypeCustom;
}

- (void)setItem:(MenuItem *)item
{
    [super setItem:item];

    self.textBar.textField.text = item.urlStr ?: @"";

    if ([self itemTypeMatchesSourceItemType]) {
        self.checkButtonView.checked = item.linkTarget && [item.linkTarget isEqualToString:MenuItemLinkTargetBlank];
    }
}

- (void)updateItemLinkTargetOption
{
    if (self.checkButtonView.checked) {
        self.item.linkTarget = MenuItemLinkTargetBlank;
    } else {
        self.item.linkTarget = nil;
    }
}

- (BOOL)isFirstResponder
{
    if ([self.textBar isFirstResponder]) {
        return [self.textBar isFirstResponder];
    }
    return [super isFirstResponder];
}

- (BOOL)resignFirstResponder
{
    if ([self.textBar isFirstResponder]) {
        return [self.textBar resignFirstResponder];
    }
    return [super resignFirstResponder];
}

#pragma mark - MenuItemSourceTextBarDelegate

- (void)sourceTextBar:(MenuItemSourceTextBar *)textBar didUpdateWithText:(NSString *)text
{
    if (![self itemTypeMatchesSourceItemType]) {
        [self setItemSourceWithContentID:nil name:[self sourceItemType]];
    }
    self.item.urlStr = text.length ? text : nil;
}

@end
