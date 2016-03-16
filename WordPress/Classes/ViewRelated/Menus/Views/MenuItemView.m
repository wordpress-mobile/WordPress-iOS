#import "MenuItemView.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"
#import "MenusActionButton.h"

@interface MenuItemView ()

@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) MenusActionButton *cancelButton;
@property (nonatomic, assign) CGPoint touchesBeganLocation;

@end

@implementation MenuItemView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if (self) {
        
        self.iconType = MenuIconTypeDefault;
        
        {
            UIButton *button = [self addAccessoryButtonIconViewWithType:MenuIconTypeEdit];
            [button addTarget:self action:@selector(editButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            self.editButton = button;
        }
        {
            UIButton *button = [self addAccessoryButtonIconViewWithType:MenuIconTypeAdd];
            [button addTarget:self action:@selector(addButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            self.addButton = button;
        }
        {
            MenusActionButton *button = [[MenusActionButton alloc] init];
            button.fillColor = [UIColor whiteColor];
            [button addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [button setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];
            [button setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
            [button.widthAnchor constraintLessThanOrEqualToConstant:63].active = YES;
            [button.heightAnchor constraintEqualToConstant:MenuItemsStackableViewAccessoryButtonHeight].active = YES;
            button.hidden = YES;
            
            [self addAccessoryButton:button];
            self.cancelButton = button;
        }
    }
    
    return self;
}

- (void)setItem:(MenuItem *)item
{
    if (_item != item) {
        _item = item;
        self.textLabel.text = item.name;
    }
}

- (void)setShowsEditingButtonOptions:(BOOL)showsEditingButtonOptions
{
    if (_showsEditingButtonOptions != showsEditingButtonOptions) {
        _showsEditingButtonOptions = showsEditingButtonOptions;
    }
    
    self.editButton.hidden = !showsEditingButtonOptions;
    self.addButton.hidden = !showsEditingButtonOptions;
}

- (void)setShowsCancelButtonOption:(BOOL)showsCancelButtonOption
{
    if (_showsCancelButtonOption != showsCancelButtonOption) {
        _showsCancelButtonOption = showsCancelButtonOption;
    }
    
    self.cancelButton.hidden = !showsCancelButtonOption;
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

- (void)editButtonPressed
{
    [self.delegate itemViewEditingButtonPressed:self];
}

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    self.touchesBeganLocation = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    self.touchesBeganLocation = CGPointZero;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if (CGPointEqualToPoint(self.touchesBeganLocation, CGPointZero)) {
        return;
    }
    
    CGPoint endedPoint = [touch locationInView:self];
    if (CGPointEqualToPoint(endedPoint, CGPointZero)) {
        return;
    }
    
    if (CGRectContainsPoint(self.bounds, self.touchesBeganLocation) && CGRectContainsPoint(self.bounds, endedPoint)) {
        [self.delegate itemViewSelected:self];
    }
    
    self.touchesBeganLocation = CGPointZero;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.touchesBeganLocation = CGPointZero;
}

@end
