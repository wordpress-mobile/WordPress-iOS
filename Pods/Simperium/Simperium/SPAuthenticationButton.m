//
//  SPAutehnticationButton.m
//  Simperium
//
//  Created by Tom Witkin on 8/4/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationButton.h"
#import "SPAuthenticationConfiguration.h"
#import <QuartzCore/QuartzCore.h>



static NSString* const SPAuthenticationHighlightedKey = @"highlighted";


@implementation SPAuthenticationButton
@synthesize backgroundHighlightColor;

- (void)dealloc {
	[self removeObserver:self forKeyPath:SPAuthenticationHighlightedKey];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserver:self
               forKeyPath:SPAuthenticationHighlightedKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
        
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        _detailTitleLabel = [[UILabel alloc] init];
        _detailTitleLabel.backgroundColor = [UIColor clearColor];
        _detailTitleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_detailTitleLabel];
        
        errorView = [[UIView alloc] initWithFrame:self.bounds];
        errorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        errorView.backgroundColor = [UIColor colorWithRed:222.0 / 255.0
                                                    green:33.0 / 255.0
                                                     blue:49.0 / 255.0
                                                    alpha:1.0];
        [self addSubview:errorView];
        
        CGRect errorLabelFrame = self.bounds;
        errorLabelFrame.origin.x += 10.0;
        errorLabelFrame.size.width -= 2 * 10.0;
        
        errorLabel = [[UILabel alloc] initWithFrame:errorLabelFrame];
        errorLabel.backgroundColor = [UIColor clearColor];
        errorLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        errorLabel.numberOfLines = 0;
        errorLabel.textAlignment = NSTextAlignmentCenter;
        errorLabel.textColor = [UIColor whiteColor];
        errorLabel.font = [UIFont fontWithName:[SPAuthenticationConfiguration sharedInstance].mediumFontName size:12.0];
        [errorView addSubview:errorLabel];
        
        errorView.alpha = 0.0;
    }
    
    return self;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    // layout title labels
    CGFloat titleLabelHeight = self.titleLabel.font.lineHeight;
    CGFloat detailTitleLabelHeight = self.detailTitleLabel.text.length > 0 ? self.detailTitleLabel.font.lineHeight : 0;
    CGFloat height = self.bounds.size.height;
    CGFloat padding = 10.0;
    
    self.detailTitleLabel.frame = CGRectMake(padding,
                                             (height - (titleLabelHeight + detailTitleLabelHeight)) / 2.0,
                                             self.bounds.size.width - 2 * padding,
                                             detailTitleLabelHeight);
    
    self.titleLabel.frame = CGRectMake(padding,
                                       detailTitleLabelHeight + self.detailTitleLabel.frame.origin.y,
                                       self.bounds.size.width - 2 * padding,
                                       titleLabelHeight);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    for (UIView *view in self.subviews) {
        if (view.class == [UIImageView class])
            [(UIImageView *)view setHighlighted:self.highlighted];
        
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    self.layer.backgroundColor = self.highlighted ? backgroundHighlightColor.CGColor : backgroundColor.CGColor;
}

- (void)setBackgroundColor:(UIColor *)bgcolor {
    backgroundColor = bgcolor;
}

- (void)setBackgroundHighlightColor:(UIColor *)bgHighlightColor {
    backgroundHighlightColor = bgHighlightColor;
}

- (void)showErrorMessage:(NSString *)errorMessage {
    [self bringSubviewToFront:errorView];

    errorLabel.text = errorMessage.uppercaseString;
    [UIView animateWithDuration:0.05
                     animations:^{
                         errorView.alpha = 1.0;
                     }];
    clearErrorTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                       target:self
                                                     selector:@selector(clearErrorMessage)
                                                     userInfo:nil
                                                      repeats:NO];
}

- (void)clearErrorMessage {
    errorView.alpha = 0.0;
}

@end
