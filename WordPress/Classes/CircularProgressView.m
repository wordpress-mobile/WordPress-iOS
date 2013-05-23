#import "CircularProgressView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CircularProgressView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setProgress:(float)progress {
    if (progress > 1.0) {
        progress = 1.0;
    }
    
    if (progress != _progress) {
        _progress = progress;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    if ([self color] == nil) {
        self.color = [UIColor whiteColor];
    }
    
    CGPoint center = CGPointMake(rect.size.width/2, rect.size.height/2);
    CGFloat radius = MIN(rect.size.width, rect.size.height)/2;
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.usesEvenOddFillRule = YES;
    [path moveToPoint:center];
    [path addArcWithCenter:center
                    radius:radius
                startAngle:0 - M_PI_2 
                  endAngle:2 * M_PI * [self progress] - M_PI_2
                 clockwise:YES];
    [path closePath];
    [[self color] setFill];
    [path fill];
}

@end
