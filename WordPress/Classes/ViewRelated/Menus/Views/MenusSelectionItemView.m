#import "MenusSelectionItemView.h"
#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"

@implementation MenusSelectionViewItem

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.name = menu.name;
    item.details = menu.details;
    return item;
}

+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.name = location.details;
    item.details = location.name;
    return item;
}

@end

@interface MenusSelectionItemView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation MenusSelectionItemView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = [UIColor clearColor];
    label.font = [[WPStyleGuide regularTextFont] fontWithSize:14];
    label.textColor = [WPStyleGuide darkGrey];
    [self addSubview:label];
    self.label = label;
    
    UIEdgeInsets insets = MenusDesignDefaultInsets();
    insets.left = MenusDesignDefaultContentSpacing;
    insets.right = MenusDesignDefaultContentSpacing;
    
    [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:insets.left].active = YES;
    [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:insets.right].active = YES;
    [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:0].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0].active = YES;
}

- (void)setItem:(MenusSelectionViewItem *)item
{
    if(_item != item) {
        _item = item;
        self.label.text = item.name;
    }
}

- (void)setDrawsDesignStrokeBottom:(BOOL)drawsDesignStrokeBottom
{
    if(_drawsDesignStrokeBottom != drawsDesignStrokeBottom) {
        _drawsDesignStrokeBottom = drawsDesignStrokeBottom;
        [self setNeedsDisplay];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    if(self.drawsDesignStrokeBottom) {
        CGContextSetLineWidth(context, 1.0);
        CGContextMoveToPoint(context, MenusDesignDefaultContentSpacing, rect.size.height - 1.0);
        CGContextAddLineToPoint(context, rect.size.width - MenusDesignDefaultContentSpacing, rect.size.height - 1.0);
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
        CGContextStrokePath(context);
    }
}

@end
