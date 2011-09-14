//
//  TapDetectingWindow.m
//  WordPress
//
//  Created by Danilo Ercoli on 13/09/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "TapDetectingWebView.h"

@implementation TapDetectingWebView

@synthesize controllerThatObserves;

- (void)forwardTap:(id)touch {
    [controllerThatObserves userDidTapWebView:touch];
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches) {

        NSLog(@"UIEventTypeTouches");

        NSSet *touches = [event allTouches];
        
        UITouch *touch = touches.anyObject;
        CGPoint tapPoint = [touch locationInView:self];
        NSLog(@"TapPoint = %f, %f", tapPoint.x, tapPoint.y);
        NSArray *pointArray = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%f", tapPoint.x],
                               [NSString stringWithFormat:@"%f", tapPoint.y], nil];
        
       
       [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forwardTap:) object:pointArray]; 
       [self performSelector:@selector(forwardTap:) withObject:pointArray afterDelay:0.5];
    }
    return [super hitTest:point withEvent:event];
}
@end