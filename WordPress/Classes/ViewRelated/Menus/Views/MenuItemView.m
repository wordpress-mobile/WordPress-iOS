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

- (id)init
{
    self = [super init];
    if(self) {
        
        self.iconType = MenuItemsActionableIconDefault;
        
        {
            UIButton *button = [self newButtonIconViewWithType:MenuItemsActionableIconEdit];
            [self.stackView addArrangedSubview:button];
            self.editButton = button;
        }
        {
            UIButton *button = [self newButtonIconViewWithType:MenuItemsActionableIconAdd];
            [self.stackView addArrangedSubview:button];
            self.addButton = button;
        }
        {
            MenusActionButton *button = [[MenusActionButton alloc] init];
            button.backgroundDrawColor = [UIColor whiteColor];
            [button setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];
            [button setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
            [button.widthAnchor constraintLessThanOrEqualToConstant:63].active = YES;
            [button.heightAnchor constraintEqualToConstant:36].active = YES;
            button.hidden = YES;
            
            [self.stackView addArrangedSubview:button];
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

- (UIColor *)highlightedColor
{
    return [UIColor colorWithWhite:0.985 alpha:1.0];
}

@end
