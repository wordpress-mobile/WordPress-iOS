#import "MenuItemsView.h"
#import "Menu.h"
#import "WPStyleGuide.h"
#import "MenuItemView.h"
#import "MenusDesign.h"

@interface MenuItemsView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) NSMutableArray *itemViews;

@end

@implementation MenuItemsView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.alignment = UIStackViewAlignmentTop;
    self.stackView.spacing = 0.0;
    
    [self setupStyling];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)setMenu:(Menu *)menu
{
    if(_menu != menu) {
        _menu = menu;
        [self reloadItemViews];
    }
}

- (void)reloadItemViews
{
    for(MenuItemView *itemView in self.itemViews) {
        [self.stackView removeArrangedSubview:itemView];
        [itemView removeFromSuperview];
    }
    
    self.itemViews = [NSMutableArray array];
    MenuItemView *lastItemView = nil;
    int i = 0;
    for(MenuItem *item in self.menu.items) {
                
        MenuItemView *itemView = [[MenuItemView alloc] init];
        // setup ordering to help with any drawing
        lastItemView.nextItemView = itemView;
        itemView.previousItemView = lastItemView;
        itemView.indentationLevel = 1;
        
        NSLayoutConstraint *heightConstraint = [itemView.heightAnchor constraintEqualToConstant:50];
        heightConstraint.active = YES;
        
        [self.itemViews addObject:itemView];
        [self.stackView addArrangedSubview:itemView];
        
        [itemView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
        lastItemView = itemView;
        i++;
    }
}

@end
