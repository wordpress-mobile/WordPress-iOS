#import "MenuItemSourceLinkView.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"
#import "MenuItemCheckButtonView.h"

@interface MenuItemSourceLinkView () <MenuItemSourceTextBarDelegate>

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) MenuItemSourceTextBar *textBar;
@property (nonatomic, strong) MenuItemCheckButtonView *checkButtonView;

@end

@implementation MenuItemSourceLinkView

- (id)init
{
    self = [super init];
    if (self) {
        
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.text = [NSLocalizedString(@"Link Address (URL)", @"Menus title label when editing a menu item as a link.") uppercaseString];
            label.textColor = [WPStyleGuide greyDarken10];
            label.font = [WPFontManager systemSemiBoldFontOfSize:12.0];
            
            [self.stackView addArrangedSubview:label];
            self.label = label;
        }
        {
            MenuItemSourceTextBar *textBar = [[MenuItemSourceTextBar alloc] init];
            textBar.translatesAutoresizingMaskIntoConstraints = NO;
            textBar.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textBar.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textBar.textField.keyboardType = UIKeyboardTypeURL;
            textBar.delegate = self;
            [self.stackView addArrangedSubview:textBar];
            
            NSLayoutConstraint *heightConstraint = [textBar.heightAnchor constraintEqualToConstant:48.0];
            heightConstraint.priority = UILayoutPriorityDefaultHigh;
            heightConstraint.active = YES;
            
            [textBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
            self.textBar = textBar;
        }
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
            
            self.checkButtonView = checkButtonView;
        }
    }
    
    return self;
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