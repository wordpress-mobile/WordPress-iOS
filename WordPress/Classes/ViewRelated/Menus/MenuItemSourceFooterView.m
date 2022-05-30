#import "MenuItemSourceFooterView.h"
#import "MenuItemSourceCell.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@interface MenuItemSourceFooterView ()

@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, assign) BOOL drawsLabelTextIfNeeded;
@property (nonatomic, strong) MenuItemSourceCell *sourceCell;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation MenuItemSourceFooterView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.backgroundColor = [UIColor murielBasicBackground];

        [self setupSourceCell];
    }

    return self;
}

- (void)setupSourceCell
{
    MenuItemSourceCell *cell = [[MenuItemSourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.frame = self.bounds;
    cell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cell.alpha = 0.0;
    [cell setTitle:@"Dummy Text For Sizing the Label"];
    [self addSubview:cell];
    self.sourceCell = cell;
    [self setupActivityIndicator];
}

- (void)setupActivityIndicator
{
    _activityIndicator = [[UIActivityIndicatorView alloc] init]; // defaults to Medium
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = false;

    [self addSubview: _activityIndicator];
    [self pinSubviewAtCenter: _activityIndicator];
}

- (void)toggleMessageWithText:(NSString *)text
{
    self.labelText = text;
    if (!self.activityIndicator.isAnimating) {
        self.drawsLabelTextIfNeeded = YES;
    }
}

- (void)startLoadingIndicatorAnimation
{
    if (self.isAnimating) {
        return;
    }

    self.drawsLabelTextIfNeeded = NO;

    [self.activityIndicator startAnimating];
    self.isAnimating = YES;
    self.sourceCell.hidden = NO;
}

- (void)stopLoadingIndicatorAnimation
{
    if (!self.isAnimating) {
        return;
    }

    [self.activityIndicator stopAnimating];
    self.isAnimating = NO;
}

- (void)setLabelText:(NSString *)labelText
{
    if (_labelText != labelText) {
        _labelText = labelText;
        [self setNeedsDisplay];
    }
}

- (void)setDrawsLabelTextIfNeeded:(BOOL)drawsLabelTextIfNeeded
{
    if (_drawsLabelTextIfNeeded != drawsLabelTextIfNeeded) {
        _drawsLabelTextIfNeeded = drawsLabelTextIfNeeded;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    if (self.labelText && self.drawsLabelTextIfNeeded) {
        const CGFloat textVerticalInsetPadding = 4.0;
        CGRect textRect = CGRectInset(rect, MenusDesignDefaultContentSpacing + textVerticalInsetPadding, 0);
        textRect.origin.y = MenusDesignDefaultContentSpacing / 2.0;;
        textRect.size.height -= textRect.origin.y;
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        NSDictionary *attributes = @{
                                     NSFontAttributeName: [WPStyleGuide regularTextFont],
                                     NSForegroundColorAttributeName: [UIColor murielNeutral40],
                                     NSParagraphStyleAttributeName: style
                                     };
        [self.labelText drawInRect:textRect withAttributes:attributes];
    }
}

@end
