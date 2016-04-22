#import "MenuItemSourceCell.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"
#import "Menu+ViewDesign.h"

#pragma mark - MenuItemSourceRadioButton

@interface MenuItemSourceRadioButton : UIView

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

#pragma mark - MenuItemSourceOptionBadgeLabel

@interface MenuItemSourceOptionBadgeLabel : UILabel

@end

#pragma mark - MenuItemSourceOptionView

static CGFloat const MenuItemSourceCellHierarchyIdentationWidth = 17.0;

@interface MenuItemSourceCell ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) MenuItemSourceOptionBadgeLabel *badgeLabel;
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
            
            UIStackView *stackView = [[UIStackView alloc] init];
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            stackView.distribution = UIStackViewDistributionFill;
            stackView.alignment = UIStackViewAlignmentLeading;
            stackView.axis = UILayoutConstraintAxisHorizontal;
            
            UIEdgeInsets margins = UIEdgeInsetsZero;
            margins.top = 10.0;
            margins.left = MenusDesignDefaultContentSpacing;
            margins.right = MenusDesignDefaultContentSpacing;
            margins.bottom = 10.0;
            
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
            label.font = [WPStyleGuide tableviewTextFont];
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateSeparatorInsets];
}

- (void)setSourceSelected:(BOOL)sourceSelected
{
    if (_sourceSelected != sourceSelected) {
        _sourceSelected = sourceSelected;
        self.accessoryType = sourceSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
        self.leadingLayoutConstraintForContentViewIndentation.constant = sourceHierarchyIndentation * MenuItemSourceCellHierarchyIdentationWidth;
        [self updateSeparatorInsets];
    }
}

- (void)updateSeparatorInsets
{
    CGFloat left = self.sourceHierarchyIndentation * MenuItemSourceCellHierarchyIdentationWidth;
    left += self.stackView.layoutMargins.left;
    self.separatorInset = UIEdgeInsetsMake(0, left, 0, 0);
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