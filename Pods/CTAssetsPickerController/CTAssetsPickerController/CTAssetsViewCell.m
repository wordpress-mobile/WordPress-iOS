/*
 CTAssetsViewCell.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "CTAssetsViewCell.h"
#import "NSDate+timeDescription.h"



@interface CTAssetsViewCell ()

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *videoImage;

@end





@implementation CTAssetsViewCell

static UIFont *titleFont;
static CGFloat titleHeight;
static UIImage *videoIcon;
static UIColor *titleColor;
static UIImage *checkedIcon;
static UIColor *selectedColor;
static UIColor *disabledColor;

+ (void)initialize
{
    titleFont       = [UIFont systemFontOfSize:12];
    titleHeight     = 20.0f;
    videoIcon       = [UIImage imageNamed:@"CTAssetsPickerVideo"];
    titleColor      = [UIColor whiteColor];
    checkedIcon     = [UIImage imageNamed:@"CTAssetsPickerChecked"];
    selectedColor   = [UIColor colorWithWhite:1 alpha:0.3];
    disabledColor   = [UIColor colorWithWhite:1 alpha:0.9];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque                 = YES;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits    = UIAccessibilityTraitImage;
        self.enabled                = YES;
    }
    
    return self;
}

- (void)bind:(ALAsset *)asset
{
    self.asset  = asset;
    self.type   = [asset valueForProperty:ALAssetPropertyType];
    self.image  = (asset.thumbnail == NULL) ? [UIImage imageNamed:@"CTAssetsPickerEmpty"] : [UIImage imageWithCGImage:asset.thumbnail];
    
    if ([self.type isEqual:ALAssetTypeVideo])
        self.title = [NSDate timeDescriptionOfTimeInterval:[[asset valueForProperty:ALAssetPropertyDuration] doubleValue]];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}


#pragma mark - Draw Rect

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    [self drawThumbnailInRect:rect];
    
    if ([self.type isEqual:ALAssetTypeVideo])
        [self drawVideoMetaInRect:rect];
    
    if (!self.isEnabled)
        [self drawDisabledViewInRect:rect];
    
    else if (self.selected)
        [self drawSelectedViewInRect:rect];
}

- (void)drawThumbnailInRect:(CGRect)rect
{
    [self.image drawInRect:rect];
}

- (void)drawVideoMetaInRect:(CGRect)rect
{
    // Create a gradient from transparent to black
    CGFloat colors [] = {
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.8,
        0.0, 0.0, 0.0, 1.0
    };
    
    CGFloat locations [] = {0.0, 0.75, 1.0};
    
    CGColorSpaceRef baseSpace   = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient      = CGGradientCreateWithColorComponents(baseSpace, colors, locations, 2);
    
    CGContextRef context    = UIGraphicsGetCurrentContext();
    
    CGFloat height          = rect.size.height;
    CGPoint startPoint      = CGPointMake(CGRectGetMidX(rect), height - titleHeight);
    CGPoint endPoint        = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
    
    CGColorSpaceRelease(baseSpace);
    CGGradientRelease(gradient);
    
    CGSize titleSize = [self.title sizeWithAttributes:@{NSFontAttributeName : titleFont}];
    CGRect titleRect = CGRectMake(rect.size.width - titleSize.width - 2, startPoint.y + (titleHeight - 12) / 2, titleSize.width, titleHeight);
    
    NSMutableParagraphStyle *titleStyle = [[NSMutableParagraphStyle alloc] init];
    titleStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    [self.title drawInRect:titleRect
            withAttributes:@{NSFontAttributeName : titleFont,
                             NSForegroundColorAttributeName : titleColor,
                             NSParagraphStyleAttributeName : titleStyle}];
    
    [videoIcon drawAtPoint:CGPointMake(2, startPoint.y + (titleHeight - videoIcon.size.height) / 2)];
}

- (void)drawDisabledViewInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, disabledColor.CGColor);
    CGContextFillRect(context, rect);
}

- (void)drawSelectedViewInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, selectedColor.CGColor);
    CGContextFillRect(context, rect);
    
    [checkedIcon drawAtPoint:CGPointMake(CGRectGetMaxX(rect) - checkedIcon.size.width, CGRectGetMinY(rect))];
}


#pragma mark - Accessibility Label

- (NSString *)accessibilityLabel
{
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    [labels addObject:[self typeLabel]];
    [labels addObject:[self orientationLabel]];
    [labels addObject:[self dateLabel]];
    
    return [labels componentsJoinedByString:@", "];
}

- (NSString *)typeLabel
{
    NSString *type = [self.asset valueForProperty:ALAssetPropertyType];
    NSString *key  = ([type isEqual:ALAssetTypeVideo]) ? @"Video" : @"Photo";
    return NSLocalizedString(key, nil);
}

- (NSString *)orientationLabel
{
    CGSize dimension = self.asset.defaultRepresentation.dimensions;
    NSString *key    = (dimension.height >= dimension.width) ? @"Portrait" : @"Landscape";
    return NSLocalizedString(key, nil);
}

- (NSString *)dateLabel
{
    NSDate *date = [self.asset valueForProperty:ALAssetPropertyDate];
    
    NSDateFormatter *df             = [[NSDateFormatter alloc] init];
    df.locale                       = [NSLocale currentLocale];
    df.dateStyle                    = NSDateFormatterMediumStyle;
    df.timeStyle                    = NSDateFormatterShortStyle;
    df.doesRelativeDateFormatting   = YES;
    
    return [df stringFromDate:date];
}


@end