#import "MenuItemSourceResultView.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

NSString * const MenuItemSourceResultSelectionDidChangeNotification = @"MenuItemSourceResultSelectionDidChangeNotification";

#pragma mark - MenuItemSourceResult

@implementation MenuItemSourceResult

- (void)setSelected:(BOOL)selected
{
    if(_selected != selected) {
        _selected = selected;
        [[NSNotificationCenter defaultCenter] postNotificationName:MenuItemSourceResultSelectionDidChangeNotification object:self];
    }
}

@end

#pragma mark - MenuItemSourceResultCheckView

@interface MenuItemSourceResultCheckView : UIView

@property (nonatomic, assign) BOOL drawsChecked;
@property (nonatomic, assign) BOOL drawsSelected;

@end

#pragma mark - MenuItemSourceResultBadgeLabel

@interface MenuItemSourceResultBadgeLabel : UILabel

@end

#pragma mark - MenuItemSourceResultCell

@interface MenuItemSourceResultView ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, strong) MenuItemSourceResultBadgeLabel *badgeLabel;
@property (nonatomic, strong) MenuItemSourceResultCheckView *checkView;

@end

@implementation MenuItemSourceResultView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if(self) {
        {
            self.translatesAutoresizingMaskIntoConstraints = NO;
            
            UIStackView *stackView = [[UIStackView alloc] init];
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            stackView.distribution = UIStackViewDistributionFillProportionally;
            stackView.alignment = UIStackViewAlignmentCenter;
            stackView.axis = UILayoutConstraintAxisHorizontal;
            
            const CGFloat spacing = MenusDesignDefaultContentSpacing / 2.0;
            UIEdgeInsets margins = UIEdgeInsetsZero;
            margins.top = spacing;
            margins.left = MenusDesignDefaultContentSpacing;
            margins.right = MenusDesignDefaultContentSpacing;
            margins.bottom = spacing;
            stackView.layoutMargins = margins;
            stackView.layoutMarginsRelativeArrangement = YES;
            stackView.spacing = spacing;
            [self addSubview:stackView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                      [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                      [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            
            self.stackView = stackView;
        }
        {
            MenuItemSourceResultCheckView *checkView = [[MenuItemSourceResultCheckView alloc] init];
            checkView.translatesAutoresizingMaskIntoConstraints = NO;
            checkView.drawsChecked = NO;
            
            [checkView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            [checkView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            
            [self.stackView addArrangedSubview:checkView];
            const CGSize size = CGSizeMake(20.0, 20.0);
            [NSLayoutConstraint activateConstraints:@[
                                                      [checkView.widthAnchor constraintEqualToConstant:size.width],
                                                      [checkView.heightAnchor constraintEqualToConstant:size.height]
                                                      ]];
            self.checkView = checkView;
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.font = [WPFontManager openSansRegularFontOfSize:16.0];
            label.textColor = [WPStyleGuide greyDarken30];
            label.backgroundColor = [UIColor whiteColor];
            
            [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            [self.stackView addArrangedSubview:label];
            self.resultLabel = label;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resultSelectionUpdatedNotification:) name:MenuItemSourceResultSelectionDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)setResult:(MenuItemSourceResult *)result
{
    if(_result != result) {
        _result = result;
    }
    
    [self updateResultDrawing];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}

- (void)updateResultDrawing
{
    if(self.result.badgeTitle) {
        
        [self insertBadgeLabelIfNeeded];
        
        self.badgeLabel.text = [self.result.badgeTitle uppercaseString];
        self.badgeLabel.hidden = NO;
        
    }else {
        self.badgeLabel.hidden = YES;
    }
    
    self.resultLabel.text = self.result.title;
    self.checkView.drawsChecked = self.result.selected;
    [self setNeedsDisplay];
}

- (void)insertBadgeLabelIfNeeded
{
    if(!self.badgeLabel) {
        
        MenuItemSourceResultBadgeLabel *label = [[MenuItemSourceResultBadgeLabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [WPFontManager openSansLightFontOfSize:12.0];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [WPStyleGuide greyLighten10];
        label.layer.cornerRadius = 4.0;
        label.layer.masksToBounds = YES;
        label.textAlignment = NSTextAlignmentCenter;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        
        [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        
        [self.stackView addArrangedSubview:label];
        self.badgeLabel = label;
    }
}

- (void)resultSelectionUpdatedNotification:(NSNotification *)notification
{
    if(notification.object == self.result) {
        [self updateResultDrawing];
    }
}

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    self.checkView.drawsSelected = YES;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    self.checkView.drawsSelected = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    self.checkView.drawsSelected = NO;
}

@end

@implementation MenuItemSourceResultCheckView

- (id)init
{
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)setDrawsChecked:(BOOL)drawsChecked
{
    if(_drawsChecked != drawsChecked) {
        _drawsChecked = drawsChecked;
        [self setNeedsDisplay];
    }
}

- (void)setDrawsSelected:(BOOL)drawsSelected
{
    if(_drawsSelected != drawsSelected) {
        _drawsSelected = drawsSelected;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    if(self.drawsSelected) {
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide mediumBlue] CGColor]);
    }else {
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten10] CGColor]);
    }
    const CGRect strokeRect = CGRectInset(rect, 1, 1);
    CGContextStrokeEllipseInRect(context, strokeRect);
    
    if(self.drawsChecked) {
        const CGRect fillRect = CGRectInset(strokeRect, 4.0, 4.0);
        CGContextSetFillColorWithColor(context, [[WPStyleGuide mediumBlue] CGColor]);
        CGContextFillEllipseInRect(context, fillRect);
    }
}

@end

#pragma mark - MenuItemSourceResultBadgeLabel

@implementation MenuItemSourceResultBadgeLabel

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    size.width += 6.0;
    size.height += 2.0;
    return size;
}

@end