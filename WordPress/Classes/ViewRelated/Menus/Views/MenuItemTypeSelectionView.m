#import "MenuItemTypeSelectionView.h"
#import "MenusDesign.h"
#import "MenuItemTypeView.h"

@interface MenuItemTypeSelectionView () <MenuItemTypeViewDelegate>

@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation MenuItemTypeSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        UIEdgeInsets margins = UIEdgeInsetsZero;
        margins.top = MenusDesignDefaultContentSpacing;
        margins.bottom = MenusDesignDefaultContentSpacing;
        stackView.layoutMargins = margins;
        stackView.layoutMarginsRelativeArrangement = YES;
        
        [self addSubview:stackView];
        [NSLayoutConstraint activateConstraints:@[
                                                  [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                  [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                  [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                  [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                  ]];
        self.stackView = stackView;
    }

    MenuItemTypeView *typeView = [self addTypeView:MenuItemTypePage];
    typeView.selected = YES;
    
    [self addTypeView:MenuItemTypeLink];
    [self addTypeView:MenuItemTypeCategory];
    [self addTypeView:MenuItemTypeTag];
    [self addTypeView:MenuItemTypePost];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    if(!hidden) {
        for(UIView *view in self.stackView.arrangedSubviews) {
            [view setNeedsDisplay];
        }
    }
}

- (MenuItemTypeView *)addTypeView:(MenuItemType)type
{
    MenuItemTypeView *typeView = [[MenuItemTypeView alloc] init];
    typeView.translatesAutoresizingMaskIntoConstraints = NO;
    typeView.itemType = type;
    typeView.delegate = self;
    [typeView setTypeTitle:[self titleForType:type]];
    
    [self.stackView addArrangedSubview:typeView];
    [typeView.heightAnchor constraintEqualToConstant:48.0].active = YES;
    
    return typeView;
}

- (NSString *)titleForType:(MenuItemType)type
{
    NSString *title = nil;
    switch (type) {
        case MenuItemTypePage:
            title = NSLocalizedString(@"Page", @"");
            break;
        case MenuItemTypeLink:
            title = NSLocalizedString(@"Link", @"");
            break;
        case MenuItemTypeCategory:
            title = NSLocalizedString(@"Category", @"");
            break;
        case MenuItemTypeTag:
            title = NSLocalizedString(@"Tag", @"");
            break;
        case MenuItemTypePost:
            title = NSLocalizedString(@"Post", @"");
            break;
        default:
            break;
    }
    
    return title;
}

#pragma mark - MenuItemTypeViewDelegate

- (void)itemTypeViewSelected:(MenuItemTypeView *)typeView
{
    [self.delegate typeSelectionView:self selectedType:typeView.itemType];
}

@end
