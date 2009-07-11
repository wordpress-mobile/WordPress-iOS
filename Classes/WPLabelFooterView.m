//
//  WPLabelFooterView.m
//  WordPress
//
//  Created by JanakiRam on 02/02/09.
//

#import "WPLabelFooterView.h"

#define kLabelTextRedColor       0.2
#define kLabelTextGreenColor     0.25
#define kLabelTextBlueColor      0.35
#define kLabelTextFontSize       15.5
#define kLabelShadowOffSetWidth   0.3
#define kLabelShadowOffSetHeight  0.4

@implementation WPLabelFooterView

@synthesize label;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        UILabel *currentLabel = [[UILabel alloc] initWithFrame:frame];
        currentLabel.backgroundColor = [UIColor clearColor];
        currentLabel.font = [UIFont systemFontOfSize:kLabelTextFontSize];
        currentLabel.textColor = [[UIColor colorWithRed:kLabelTextRedColor green:kLabelTextGreenColor blue:kLabelTextBlueColor alpha:1.0] colorWithAlphaComponent:0.8];
        currentLabel.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        currentLabel.shadowOffset = CGSizeMake(kLabelShadowOffSetWidth, kLabelShadowOffSetHeight);
        [self addSubview:currentLabel];
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        currentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.label = currentLabel;
        [currentLabel release];
    }

    return self;
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)setText:(NSString *)labelText {
    self.label.text = labelText;
}

- (NSString *)text {
    return self.label.text;
}

- (void)setTextAlignment:(UITextAlignment)labelTextAlignment {
    self.label.textAlignment = labelTextAlignment;
}

- (UITextAlignment)textAlignment {
    return self.label.textAlignment;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    self.label.numberOfLines = numberOfLines;
}

- (NSInteger)numberOfLines {
    return self.label.numberOfLines;
}

- (void)dealloc {
    [label release];
    [super dealloc];
}

@end
