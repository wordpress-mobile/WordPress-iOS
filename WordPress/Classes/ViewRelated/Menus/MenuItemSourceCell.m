#import "MenuItemSourceCell.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

#pragma mark - MenuItemSourceRadioButton

@interface MenuItemSourceRadioButton : UIView

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

#pragma mark - MenuItemSourceOptionView

static CGFloat const MenuItemSourceCellHierarchyIdentationWidth = 17.0;

@interface MenuItemSourceCell ()

@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) UIStackView *labelsStackView;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) NSLayoutConstraint *leadingLayoutConstraintForContentViewIndentation;
@property (nonatomic, strong, readonly) NSLayoutConstraint *topLayoutConstraintForContentViewIndentation;
@property (nonatomic, strong, readonly) NSLayoutConstraint *topLayoutDefaultConstraint;

@end

@implementation MenuItemSourceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        self.backgroundColor = [UIColor murielListForeground];

        [self setupStackView];
        [self setupLabel];
    }

    return self;
}

- (void)setupStackView
{
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

    _leadingLayoutConstraintForContentViewIndentation = [stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor];
    _topLayoutDefaultConstraint = [stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor];
    _topLayoutConstraintForContentViewIndentation = [stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:-(margins.top)];

    [NSLayoutConstraint activateConstraints:@[
                                              _topLayoutDefaultConstraint,
                                              _leadingLayoutConstraintForContentViewIndentation,
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
                                              ]];

    _stackView = stackView;
}

- (void)setupLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [WPStyleGuide tableviewTextFont];
    label.textColor = [UIColor murielNeutral60];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    _label = label;

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:label];
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
    rect.size.width = self.contentView.frame.size.width - self.stackView.layoutMargins.right;
    rect.size.width -= rect.origin.x;

    return rect;
}

@end
