#import "MenuItemTypeView.h"
#import "MenusDesign.h"
#import "WPFontManager.h"

@interface MenuItemTypeView ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation MenuItemTypeView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        
        {
            UIImageView *iconView = [[UIImageView alloc] init];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.backgroundColor = [UIColor clearColor];
            iconView.tintColor = [WPStyleGuide mediumBlue];

            [self addSubview:iconView];
            
            const CGFloat iconSize = 14.0;
            NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:iconSize];
            widthConstraint.priority = UILayoutPriorityDefaultHigh;
            widthConstraint.active = YES;
            [iconView.heightAnchor constraintEqualToConstant:iconSize].active = YES;
            
            NSLayoutConstraint *leadingConstraint = [iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:MenusDesignDefaultContentSpacing];
            leadingConstraint.priority = UILayoutPriorityDefaultHigh;
            leadingConstraint.active = YES;
            
            [iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
            
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
            
            [self addSubview:label];
            
            NSLayoutConstraint *leadingConstraint = [label.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:ceilf(MenusDesignDefaultContentSpacing / 2.0)];
            leadingConstraint.priority = UILayoutPriorityDefaultHigh;
            leadingConstraint.active = YES;
            
            [label.heightAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
            [label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
            
            NSLayoutConstraint *trailingConstraint = [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:MenusDesignDefaultContentSpacing];
            trailingConstraint.priority = MenusDesignDefaultContentSpacing;
            trailingConstraint.active = YES;
            
            self.label = label;
        }
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if(_selected != selected) {
        _selected = selected;
        
        if(selected) {
            self.label.textColor = [WPStyleGuide mediumBlue];
        }else {
            self.label.textColor = [WPStyleGuide greyDarken30];;
        }
        
        [self setNeedsDisplay];
    }
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
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    
    if(self.selected) {
        CGContextMoveToPoint(context, 0, rect.size.height);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    }else {
        CGContextMoveToPoint(context, rect.size.width, 0);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    }
    
    CGContextStrokePath(context);
}

@end
