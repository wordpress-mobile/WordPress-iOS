#import "MenusSelectionView.h"
#import "WPStyleGuide.h"

@interface WPIconDrawView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIColor *drawColor;

@end

@implementation WPIconDrawView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGRect imageRect = CGRectZero;
    UIColor *drawColor = self.drawColor;
    UIImage *image = self.image;
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        
        CGContextSetFillColorWithColor(context, [drawColor CGColor]);
        
        imageRect.size.width = rect.size.width;
        imageRect.size.height = ((image.size.height * imageRect.size.width) / image.size.width);
        if(imageRect.size.height != rect.size.height) {
            imageRect.origin.y = -((rect.size.height / 2) - (imageRect.size.height / 2));
        }
        
        imageRect = CGRectIntegral(imageRect);
        
        CGContextTranslateCTM(context, 0, imageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGContextClipToMask(context, imageRect, [image CGImage]);
        CGContextFillRect(context, imageRect);
        
        CGContextRestoreGState(context);
    }
}

@end

@interface MenusSelectionView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) WPIconDrawView *iconView;
@property (nonatomic, strong) WPIconDrawView *accessoryView;

@end

@implementation MenusSelectionView

- (void)updateWithAvailableLocations:(NSUInteger)numLocationsAvailable selectedLocationName:(NSString *)name
{
    NSString *localizedFormat = nil;
    
    if(numLocationsAvailable > 1) {
        localizedFormat = NSLocalizedString(@"%i menu areas in this theme", @"The number of menu areas available in the theme");
    }else {
        localizedFormat = NSLocalizedString(@"%i menu area in this theme", @"One menu area available in the theme");
    }
    
    [self setTitleText:name subTitleText:[NSString stringWithFormat:localizedFormat, numLocationsAvailable]];
    
    self.iconView.image = [UIImage imageNamed:@"icon-menus-locations"];
    [self.iconView setNeedsDisplay];
}

- (void)updateWithAvailableMenus:(NSUInteger)numMenusAvailable selectedLocationName:(NSString *)name
{
    NSString *localizedFormat = nil;
    
    if(numMenusAvailable > 1) {
        localizedFormat = NSLocalizedString(@"%i menus available", @"The number of menus on the site and area.");
    }else {
        localizedFormat = NSLocalizedString(@"%i menu available", @"One menu is available in the site and area");
    }
    
    [self setTitleText:name subTitleText:[NSString stringWithFormat:localizedFormat, numMenusAvailable]];
    
    self.iconView.image = [UIImage imageNamed:@"icon-menus-menus"];
    [self.iconView setNeedsDisplay];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    {
        WPIconDrawView *iconView = [[WPIconDrawView alloc] init];
        iconView.backgroundColor = [UIColor clearColor];
        iconView.image = [UIImage imageNamed:@"icon-menus-menus"];
        iconView.drawColor = [WPStyleGuide darkBlue];
        
        [iconView.widthAnchor constraintEqualToConstant:30].active = YES;
        [iconView.heightAnchor constraintEqualToConstant:30].active = YES;

        [self.stackView addArrangedSubview:iconView];
        self.iconView = iconView;
    }
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.numberOfLines = 0;
        self.textLabel = label;

        [self setTitleText:@"Main Menu" subTitleText:@"2 menu areas available in this theme"];
        [self.stackView addArrangedSubview:label];
        
        [[label heightAnchor] constraintEqualToAnchor:self.stackView.heightAnchor].active = YES;
    }
    {
        WPIconDrawView *accessoryView = [[WPIconDrawView alloc] init];
        accessoryView.backgroundColor = [UIColor clearColor];
        accessoryView.image = [UIImage imageNamed:@"icon-menus-expand"];
        accessoryView.drawColor = [WPStyleGuide mediumBlue];
        
        [accessoryView.widthAnchor constraintEqualToConstant:15].active = YES;
        [accessoryView.heightAnchor constraintEqualToConstant:15].active = YES;
        
        [self.stackView addArrangedSubview:accessoryView];
        self.accessoryView = accessoryView;
    }
}

- (void)setTitleText:(NSString *)title subTitleText:(NSString *)subtitle
{
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    {
        NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide subtitleFont], NSForegroundColorAttributeName: [WPStyleGuide grey]};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:subtitle attributes:attributes];
        [mutableAttributedString appendAttributedString:attributedString];
    }
    [mutableAttributedString.mutableString appendString:@"\n"];
    {
        NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide regularTextFontSemiBold], NSForegroundColorAttributeName: [WPStyleGuide darkGrey]};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:title attributes:attributes];
        [mutableAttributedString appendAttributedString:attributedString];
    }
    
    self.textLabel.attributedText = mutableAttributedString;
}

@end
