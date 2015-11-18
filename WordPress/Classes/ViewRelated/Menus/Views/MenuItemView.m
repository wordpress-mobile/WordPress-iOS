#import "MenuItemView.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"
#import "MenusActionButton.h"

@interface MenuItemView ()

@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) MenusActionButton *cancelButton;

@end

@implementation MenuItemView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if(self) {
        
        self.iconType = MenuItemActionableIconDefault;
        self.reorderingEnabled = YES;
        
        {
            UIButton *button = [self addAccessoryButtonIconViewWithType:MenuItemActionableIconEdit];
            self.editButton = button;
        }
        {
            UIButton *button = [self addAccessoryButtonIconViewWithType:MenuItemActionableIconAdd];
            [button addTarget:self action:@selector(addButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            self.addButton = button;
        }
        {
            MenusActionButton *button = [[MenusActionButton alloc] init];
            button.backgroundDrawColor = [UIColor whiteColor];
            [button addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [button setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];
            [button setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
            [button.widthAnchor constraintLessThanOrEqualToConstant:63].active = YES;
            [button.heightAnchor constraintEqualToConstant:MenuItemActionableViewAccessoryButtonHeight].active = YES;
            button.hidden = YES;
            
            [self addAccessoryButton:button];
            self.cancelButton = button;
        }
    }
    
    return self;
}

- (void)setItem:(MenuItem *)item
{
    if(_item != item) {
        _item = item;
        self.textLabel.text = item.name;
    }
}

- (void)setShowsEditingButtonOptions:(BOOL)showsEditingButtonOptions
{
    if(_showsEditingButtonOptions != showsEditingButtonOptions) {
        _showsEditingButtonOptions = showsEditingButtonOptions;
    }
    
    self.editButton.hidden = !showsEditingButtonOptions;
    self.addButton.hidden = !showsEditingButtonOptions;
    self.reorderingEnabled = showsEditingButtonOptions;
}

- (void)setShowsCancelButtonOption:(BOOL)showsCancelButtonOption
{
    if(_showsCancelButtonOption != showsCancelButtonOption) {
        _showsCancelButtonOption = showsCancelButtonOption;
    }
    
    self.cancelButton.hidden = !showsCancelButtonOption;
}

- (UIColor *)contentViewBackgroundColor
{
    UIColor *color = nil;
    if(self.highlighted) {
        color = [UIColor colorWithWhite:0.99 alpha:1.0];;
    }else {
        color = [UIColor whiteColor];
    }
    
    return color;
}

- (UIColor *)textLabelColor
{
    UIColor *color = [WPStyleGuide darkGrey];
    return color;
}

- (UIColor *)iconTintColor
{
    UIColor *color = [WPStyleGuide mediumBlue];
    return color;
}

#pragma mark - buttons

- (void)addButtonPressed
{
    [self.delegate itemViewAddButtonPressed:self];
}

- (void)cancelButtonPressed
{
    [self.delegate itemViewCancelButtonPressed:self];
}

@end
