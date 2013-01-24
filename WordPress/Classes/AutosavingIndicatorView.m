//
//  AutosavingIndicatorView.m
//  WordPress
//
//  Created by Jorge Bernal on 1/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "AutosavingIndicatorView.h"

CGFloat const AutosavingIndicatiorViewDefaultInset = 4.f;
CGFloat const AutosavingIndicatiorViewFadeDuration = 0.3f;
CGFloat const AutosavingIndicatiorViewDelayAfterStopped = 1.f;
CGFloat const AutosavingIndicatiorViewFontSize = 11.f;
NSTimeInterval const AutosavingIndicatorViewDotsAnimationInterval = 0.2;

@implementation AutosavingIndicatorView {
    UILabel *_label;
    NSString *_text;
    NSTimer *_timer;
    NSUInteger _dots;
}

- (void)dealloc {
    [_timer invalidate];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.8f];
        self.layer.cornerRadius = 4.f;
        _text = NSLocalizedString(@"Autosaving", @"");
        _label = [[UILabel alloc] initWithFrame:CGRectInset(frame, AutosavingIndicatiorViewDefaultInset, AutosavingIndicatiorViewDefaultInset)];
        _label.text = _text;
        _label.textColor = [UIColor colorWithWhite:0.2f alpha:1.f];
        _label.backgroundColor = [UIColor clearColor];
        _label.font = [UIFont systemFontOfSize:AutosavingIndicatiorViewFontSize];
        [self addSubview:_label];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview && !self.hidden) {
        [self setupTimer];
    } else {
        [self disableTimer];
    }
}

- (void)layoutSubviews {
    _label.frame = CGRectInset(self.bounds, AutosavingIndicatiorViewDefaultInset, AutosavingIndicatiorViewDefaultInset);
}

- (void)updateText:(NSTimer *)timer {
    _dots +=1;
    if (_dots > 3)
        _dots = 0;
    _label.text = [_text stringByAppendingString:[@"..." substringWithRange:NSMakeRange(0, _dots)]];
}

- (void)setupTimer {
    if (_timer)
        return;
    _timer = [NSTimer scheduledTimerWithTimeInterval:AutosavingIndicatorViewDotsAnimationInterval target:self selector:@selector(updateText:) userInfo:nil repeats:YES];
}

- (void)disableTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void)startAnimating {
    [self setupTimer];
    self.alpha = 0.f;
    self.hidden = NO;
    [UIView animateWithDuration:AutosavingIndicatiorViewFadeDuration
                     animations:^{
                         self.alpha = 1.f;
                     }];
}

- (void)stopAnimatingWithSuccess:(BOOL)success {
    [self disableTimer];
    NSString *text;
    if (success) {
        text = NSLocalizedString(@"Autosaved ✓", @"");
    } else {
        text = NSLocalizedString(@"Failed", @"Autosave failed");
    }
    _label.text = text;
    [UIView animateWithDuration:AutosavingIndicatiorViewFadeDuration
                          delay:AutosavingIndicatiorViewDelayAfterStopped
                        options:0
                     animations:^{
                         self.alpha = 0.f;
                     } completion:^(BOOL finished) {
                         self.hidden = YES;
                         self.alpha = 1.f;
                         [self updateText:nil];
                     }];
}

@end
