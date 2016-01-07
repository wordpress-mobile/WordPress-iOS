#import "MenuItemTypeSelectionView.h"
#import "MenuItemTypeView.h"

@interface MenuItemTypeSelectionView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) NSMutableArray *typeViews;

@end

@implementation MenuItemTypeSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.typeViews = [NSMutableArray arrayWithCapacity:5];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentMode = UIViewContentModeRedraw;

    {
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollView.backgroundColor = [UIColor clearColor];
        scrollView.clipsToBounds = NO;
        [self addSubview:scrollView];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                  [scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                  [scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                  [scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                  ]];
        self.scrollView = scrollView;
    }
    {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.alignment = UIStackViewAlignmentTop;
        stackView.distribution = UIStackViewDistributionFillProportionally;
        stackView.axis = UILayoutConstraintAxisVertical;
        [self.scrollView addSubview:stackView];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
                                                  [stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
                                                  [stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
                                                  [stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor]
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

- (MenuItemTypeView *)addTypeView:(MenuItemType)itemType {
    
    MenuItemTypeView *typeView = [[MenuItemTypeView alloc] init];
    typeView.itemType = itemType;
    [self.stackView addArrangedSubview:typeView];
    
    [typeView.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
    
    [self.typeViews addObject:typeView];
    return typeView;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    CGContextMoveToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

@end
