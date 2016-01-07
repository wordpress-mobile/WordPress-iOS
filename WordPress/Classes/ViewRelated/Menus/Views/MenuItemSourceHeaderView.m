#import "MenuItemSourceHeaderView.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

@interface MenuItemSourceHeaderView ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation MenuItemSourceHeaderView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        const CGFloat spacing = MenusDesignDefaultContentSpacing;
        
        {
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.image = [[UIImage imageNamed:@"icon-menus-arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            imageView.tintColor = [WPStyleGuide mediumBlue];
            imageView.backgroundColor = [UIColor whiteColor];
            [self addSubview:imageView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [imageView.widthAnchor constraintEqualToConstant:14.0],
                                                      [imageView.heightAnchor constraintEqualToConstant:14.0],
                                                      [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:spacing],
                                                      [imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
                                                      ]];
            
            self.iconView = imageView;
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.font = [WPFontManager openSansRegularFontOfSize:16.0];
            label.textColor = [WPStyleGuide greyDarken30];
            label.backgroundColor = [UIColor whiteColor];
            label.text = @"Page"; // sample
            [self addSubview:label];
            
            NSLayoutConstraint *heightConstraint = [label.heightAnchor constraintEqualToAnchor:self.heightAnchor constant:-2.0];
            heightConstraint.priority = UILayoutPriorityDefaultHigh;
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [label.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:ceilf(spacing * 0.75)],
                                                      [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                      heightConstraint,
                                                      [label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
                                                      ]];
            self.label = label;
        }
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)tapGesture:(UITapGestureRecognizer *)tapGesture
{
    [self.delegate sourceHeaderViewSelected:self];
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
}

@end
