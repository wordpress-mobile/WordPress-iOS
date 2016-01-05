#import "MenuItemTypeCell.h"
#import "MenusDesign.h"
#import "WPFontManager.h"

@interface MenuItemTypeCell ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation MenuItemTypeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        {
            UIImageView *iconView = [[UIImageView alloc] init];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.backgroundColor = [UIColor clearColor];
            iconView.tintColor = [WPStyleGuide mediumBlue];

            [self.contentView addSubview:iconView];
            
            NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:10.0];
            widthConstraint.priority = UILayoutPriorityDefaultHigh;
            widthConstraint.active = YES;
            
            NSLayoutConstraint *leadingConstraint = [iconView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:MenusDesignDefaultContentSpacing];
            leadingConstraint.priority = UILayoutPriorityDefaultHigh;
            leadingConstraint.active = YES;
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
                                                      [iconView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
                                                      ]];
            
            [iconView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            [iconView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            
            self.iconView = iconView;
            [self setTypeIconImageName:@"icon-menus-document"];
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.numberOfLines = 0;
            label.textColor = [WPStyleGuide greyDarken30];
            label.font = [WPFontManager openSansRegularFontOfSize:16.0];
            label.backgroundColor = [UIColor clearColor];
            
            [self.contentView addSubview:label];
            
            NSLayoutConstraint *leadingConstraint = [label.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:ceilf(MenusDesignDefaultContentSpacing / 2.0)];
            leadingConstraint.priority = UILayoutPriorityDefaultHigh;
            leadingConstraint.active = YES;
            
            [label.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
            
            NSLayoutConstraint *trailingConstraint = [label.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:MenusDesignDefaultContentSpacing];
            trailingConstraint.priority = MenusDesignDefaultContentSpacing;
            trailingConstraint.active = YES;
            
            self.label = label;
        }
    }
    
    return self;
}

- (void)setSelectionType:(MenuItemSelectionType *)selectionType
{
    if(_selectionType != selectionType) {
        _selectionType = selectionType;
        
        [self setTypeTitle:[selectionType title]];
        [self setTypeIconImageName:[selectionType iconImageName]];
    }
    
    if(selectionType.selected) {
        self.label.textColor = [WPStyleGuide mediumBlue];
    }else {
        self.label.textColor = [WPStyleGuide greyDarken30];;
    }
    
    [self setNeedsDisplay];
}

- (void)setTypeTitle:(NSString *)title
{
    self.label.text = title;
}

- (void)setTypeIconImageName:(NSString *)imageName
{
    self.iconView.hidden = NO;
    self.iconView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    
    if(self.selectionType.selected) {
        CGContextMoveToPoint(context, 0, rect.size.height);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    }else {
        CGContextMoveToPoint(context, rect.size.width , 0);
        CGContextAddLineToPoint(context, rect.size.width , rect.size.height);
    }
    
    CGContextStrokePath(context);
}

@end
