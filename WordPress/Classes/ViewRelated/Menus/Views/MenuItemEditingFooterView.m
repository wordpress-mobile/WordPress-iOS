#import "MenuItemEditingFooterView.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

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
    {
        UIButton *button = self.cancelButton;
        button.titleLabel.font = [WPFontManager systemRegularFontOfSize:18.0];
        [button setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];
        [button setTitleColor:[WPStyleGuide greyDarken20] forState:UIControlStateHighlighted];
        [button setTitle:NSLocalizedString(@"Cancel", @"Menus: Cancel button title for canceling an edited menu item.") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor clearColor];
    }
    {
        UIButton *button = self.trashButton;
        button.adjustsImageWhenHighlighted = YES;
        [button setTitle:nil forState:UIControlStateNormal];
        button.tintColor = [WPStyleGuide grey];
        [button setImage:[Gridicon iconOfType:GridiconTypeTrash] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(trashButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor clearColor];
    }
    {
        UIButton *button = self.saveButton;
        button.titleLabel.font = [WPFontManager systemSemiBoldFontOfSize:18.0];
        [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
        [button setTitleColor:[WPStyleGuide darkBlue] forState:UIControlStateHighlighted];
        [button setTitleColor:[WPStyleGuide greyLighten20] forState:UIControlStateDisabled];
        [button setTitle:NSLocalizedString(@"OK", @"Menus: button title for finishing editing of a menu item.") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor clearColor];
    }
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
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
