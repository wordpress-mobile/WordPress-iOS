#import "MenuItemEditingFooterView.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

@interface MenuItemEditingFooterView ()

@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *trashButton;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;

@end

@implementation MenuItemEditingFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.backgroundColor = [UIColor murielListForeground];

    [self setupCancelButton];
    [self setupTrashButton];
    [self setupSaveButton];
}

- (void)setupCancelButton
{
    UIButton *button = self.cancelButton;
    button.titleLabel.font = [WPFontManager systemRegularFontOfSize:18.0];
    [button setTitleColor:[UIColor murielNeutral70] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor murielNeutral] forState:UIControlStateHighlighted];
    [button setTitle:NSLocalizedString(@"Cancel", @"Menus: Cancel button title for canceling an edited menu item.") forState:UIControlStateNormal];
    [button addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupTrashButton
{
    UIButton *button = self.trashButton;
    button.adjustsImageWhenHighlighted = YES;
    [button setTitle:nil forState:UIControlStateNormal];
    button.tintColor = [UIColor murielNeutral30];
    [button setImage:[Gridicon iconOfType:GridiconTypeTrash] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(trashButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupSaveButton
{
    UIButton *button = self.saveButton;
    button.titleLabel.font = [WPFontManager systemSemiBoldFontOfSize:18.0];
    [button setTitleColor:[UIColor murielPrimary] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor murielPrimaryDark] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor murielNeutral10] forState:UIControlStateDisabled];
    [button setTitle:NSLocalizedString(@"OK", @"Menus: button title for finishing editing of a menu item.") forState:UIControlStateNormal];
    [button addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, [[UIColor murielNeutral5] CGColor]);
    CGContextSetLineWidth(context, 2.0);

    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, rect.size.width, 0);

    CGContextStrokePath(context);
}

#pragma mark - buttons

- (void)saveButtonPressed
{
    [self.delegate editingFooterViewDidSelectSave:self];
}

- (void)trashButtonPressed
{
    [self.delegate editingFooterViewDidSelectTrash:self];
}

- (void)cancelButtonPressed
{
    [self.delegate editingFooterViewDidSelectCancel:self];
}

@end
