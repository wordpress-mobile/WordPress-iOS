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

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UILabel *label;
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
            self.backgroundColor = [UIColor whiteColor];
            
            UIView *contentView = [[UIView alloc] init];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            contentView.backgroundColor = [UIColor whiteColor];
            
            [self addSubview:contentView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                      [contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                      [contentView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
                                                      [contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            
            self.contentView = contentView;
            
            UIStackView *stackView = [[UIStackView alloc] init];
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            stackView.distribution = UIStackViewDistributionFill;
            stackView.alignment = UIStackViewAlignmentLeading;
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
            [contentView addSubview:stackView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [stackView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
                                                      [stackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
                                                      [stackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
                                                      [stackView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor]
                                                      ]];
            
            self.stackView = stackView;
        }
        
        UIFont *labelFont = [WPFontManager openSansRegularFontOfSize:16.0];
        const CGFloat labelFontLineHeight = ceilf(labelFont.ascender + fabs(labelFont.descender));
        {
            MenuItemSourceResultCheckView *checkView = [[MenuItemSourceResultCheckView alloc] init];
            checkView.translatesAutoresizingMaskIntoConstraints = NO;
            checkView.drawsChecked = NO;
            
            [checkView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            [checkView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            
            [self.stackView addArrangedSubview:checkView];
            const CGSize size = CGSizeMake(labelFontLineHeight, labelFontLineHeight);
            [NSLayoutConstraint activateConstraints:@[
                                                      [checkView.widthAnchor constraintEqualToConstant:size.width],
                                                      [checkView.heightAnchor constraintEqualToConstant:size.height]
                                                      ]];
            self.checkView = checkView;
        }
        {
            UIStackView *labelsStackView = [[UIStackView alloc] init];
            labelsStackView.translatesAutoresizingMaskIntoConstraints = NO;
            labelsStackView.distribution = UIStackViewDistributionFill;
            labelsStackView.alignment = UIStackViewAlignmentTop;
            labelsStackView.axis = UILayoutConstraintAxisHorizontal;
            labelsStackView.spacing = self.stackView.spacing;
            
            [self.stackView addArrangedSubview:labelsStackView];
            self.labelsStackView = labelsStackView;
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.font = labelFont;
            label.textColor = [WPStyleGuide greyDarken30];
            label.backgroundColor = [UIColor whiteColor];
            label.numberOfLines = 0;
            label.lineBreakMode = NSLineBreakByTruncatingTail;
            
            [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            
            [self.labelsStackView addArrangedSubview:label];
            self.label = label;
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
    
    self.label.text = self.result.title;
    self.checkView.drawsChecked = self.result.selected;
    [self setNeedsDisplay];
}

- (void)insertBadgeLabelIfNeeded
{
    if(!self.badgeLabel) {
        
        MenuItemSourceResultBadgeLabel *label = [[MenuItemSourceResultBadgeLabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [WPFontManager openSansLightFontOfSize:13.0];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [WPStyleGuide greyLighten10];
        label.layer.cornerRadius = 3.0;
        label.layer.masksToBounds = YES;
        label.textAlignment = NSTextAlignmentCenter;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        
        [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        [self.labelsStackView addArrangedSubview:label];
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
    size.width += 8.0;
    size.height += 4.0;
    return size;
}

@end