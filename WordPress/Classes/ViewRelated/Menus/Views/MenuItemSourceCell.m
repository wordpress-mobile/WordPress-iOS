#import "MenuItemSourceCell.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

#pragma mark - MenuItemSourceRadioButton

@interface MenuItemSourceRadioButton : UIView

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

#pragma mark - MenuItemSourceOptionBadgeLabel

@interface MenuItemSourceOptionBadgeLabel : UILabel

@end

#pragma mark - MenuItemSourceOptionView

static CGFloat const MenuItemSourceCellHierarchyIdentationLength = 17.0;

@interface MenuItemSourceCell ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) MenuItemSourceOptionBadgeLabel *badgeLabel;
@property (nonatomic, strong) MenuItemSourceRadioButton *radioButton;
@property (nonatomic, strong) NSLayoutConstraint *leadingLayoutConstraintForContentViewIndentation;
@property (nonatomic, strong) NSLayoutConstraint *topLayoutConstraintForContentViewIndentation;
@property (nonatomic, strong) NSLayoutConstraint *topLayoutDefaultConstraint;

@end

@implementation MenuItemSourceCell

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        {
            self.backgroundColor = [UIColor whiteColor];
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UIStackView *stackView = [[UIStackView alloc] init];
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            stackView.distribution = UIStackViewDistributionFill;
            stackView.alignment = UIStackViewAlignmentLeading;
            stackView.axis = UILayoutConstraintAxisHorizontal;
            
            UIEdgeInsets margins = UIEdgeInsetsZero;
            margins.top = MenusDesignDefaultContentSpacing / 2.0;
            margins.left = MenusDesignDefaultContentSpacing;
            margins.right = MenusDesignDefaultContentSpacing;
            margins.bottom = MenusDesignDefaultContentSpacing / 2.0;
            stackView.layoutMargins = margins;
            stackView.layoutMarginsRelativeArrangement = YES;
            stackView.spacing = MenusDesignDefaultContentSpacing / 2.0;
            [self.contentView addSubview:stackView];
            
            self.leadingLayoutConstraintForContentViewIndentation = [stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor];
            self.topLayoutDefaultConstraint = [stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor];
            self.topLayoutConstraintForContentViewIndentation = [stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:-(margins.top)];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      self.topLayoutDefaultConstraint,
                                                      self.leadingLayoutConstraintForContentViewIndentation,
                                                      [stackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor],
                                                      [stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
                                                      ]];
            
            self.stackView = stackView;
        }
        
        UIFont *labelFont = [WPFontManager systemRegularFontOfSize:16.0];
        const CGFloat labelFontLineHeight = ceilf(labelFont.ascender + fabs(labelFont.descender));
        {
            MenuItemSourceRadioButton *radioButton = [[MenuItemSourceRadioButton alloc] init];
            radioButton.translatesAutoresizingMaskIntoConstraints = NO;
            radioButton.selected = NO;
            
            [radioButton setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            [radioButton setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            
            [self.stackView addArrangedSubview:radioButton];
            const CGSize size = CGSizeMake(labelFontLineHeight, labelFontLineHeight);
            NSLayoutConstraint *heightConstraint = [radioButton.heightAnchor constraintEqualToConstant:size.height];
            heightConstraint.priority = 999;
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [radioButton.widthAnchor constraintEqualToConstant:size.width],
                                                      heightConstraint
                                                      ]];
            self.radioButton = radioButton;
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
    }
    
    return self;
}

- (void)setSourceSelected:(BOOL)sourceSelected
{
    if (_sourceSelected != sourceSelected) {
        _sourceSelected = sourceSelected;
        
        self.radioButton.selected = sourceSelected;
    }
}

- (void)setTitle:(NSString *)title
{
    if (_title != title) {
        _title = [title copy];
        self.label.text = title;
    }
}

- (void)setBadgeTitle:(NSString *)badgeTitle
{
    if (_badgeTitle != badgeTitle) {
        _badgeTitle = [badgeTitle copy];
        
        [self insertBadgeLabelIfNeeded];
        self.badgeLabel.text = [badgeTitle uppercaseString];
    }
    
    self.badgeLabel.hidden = _badgeTitle.length ? NO : YES;
}

- (void)setSourceHierarchyIndentation:(NSUInteger)sourceHierarchyIndentation
{
    if (_sourceHierarchyIndentation != sourceHierarchyIndentation) {
        _sourceHierarchyIndentation = sourceHierarchyIndentation;
        self.leadingLayoutConstraintForContentViewIndentation.constant = sourceHierarchyIndentation * MenuItemSourceCellHierarchyIdentationLength;
        
        if (sourceHierarchyIndentation) {
            
            if (self.topLayoutDefaultConstraint.active) {
                [NSLayoutConstraint deactivateConstraints:@[self.topLayoutDefaultConstraint]];
                [NSLayoutConstraint activateConstraints:@[self.topLayoutConstraintForContentViewIndentation]];
            }
            
        } else  {
            
            if (self.topLayoutConstraintForContentViewIndentation.active) {
                [NSLayoutConstraint deactivateConstraints:@[self.topLayoutConstraintForContentViewIndentation]];
                [NSLayoutConstraint activateConstraints:@[self.topLayoutDefaultConstraint]];
            }
        }
    }
}

- (CGRect)drawingRectForRadioButton
{
    return [self convertRect:self.radioButton.frame fromView:self.radioButton.superview];
}

- (CGRect)drawingRectForLabel
{
    CGRect rect = [self convertRect:self.label.frame fromView:self.label.superview];
    rect.size.width = self.contentView.frame.size.width - (self.stackView.layoutMargins.right);
    rect.size.width -= rect.origin.x;
    
    return rect;
}

- (void)insertBadgeLabelIfNeeded
{
    if (!self.badgeLabel) {
        
        MenuItemSourceOptionBadgeLabel *label = [[MenuItemSourceOptionBadgeLabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [WPFontManager systemLightFontOfSize:13.0];
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

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    self.radioButton.drawsHighlighted = YES;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    self.radioButton.drawsHighlighted = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    self.radioButton.drawsHighlighted = NO;
}

@end

#pragma mark - MenuItemSourceRadioButton

@implementation MenuItemSourceRadioButton

- (id)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [self setNeedsDisplay];
    }
}

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if (_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    if (self.drawsHighlighted) {
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide mediumBlue] CGColor]);
    } else  {
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten10] CGColor]);
    }
    const CGRect strokeRect = CGRectInset(rect, 1, 1);
    CGContextStrokeEllipseInRect(context, strokeRect);
    
    if (self.selected) {
        const CGRect fillRect = CGRectInset(strokeRect, 4.0, 4.0);
        CGContextSetFillColorWithColor(context, [[WPStyleGuide mediumBlue] CGColor]);
        CGContextFillEllipseInRect(context, fillRect);
    }
}

@end

#pragma mark - MenuItemSourceOptionBadgeLabel

@implementation MenuItemSourceOptionBadgeLabel

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    size.width += 8.0;
    size.height += 4.0;
    return size;
}

@end