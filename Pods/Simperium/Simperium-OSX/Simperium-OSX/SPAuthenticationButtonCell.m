//
//  SPAuthenticationButtonCell.m
//  Simplenote-OSX
//
//  Created by Michael Johnston on 7/24/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationButtonCell.h"
#import "SPAuthenticationConfiguration.h"

@implementation SPAuthenticationButtonCell


- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSBezierPath *outerClip = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:12.f yRadius:12.f];
    [outerClip addClip];
    
    NSColor *buttonColor = [SPAuthenticationConfiguration sharedInstance].controlColor;
    if ([self isHighlighted]) {
        buttonColor = [buttonColor blendedColorWithFraction:0.1 ofColor:[NSColor blackColor]];
    }
    
    [buttonColor setFill];
    [outerClip fill];

    int fontSize = 20;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    [style setMaximumLineHeight:fontSize + 8];

    NSFont *font = [NSFont fontWithName:[SPAuthenticationConfiguration sharedInstance].regularFontName size:fontSize];
    NSDictionary *attributes = @{NSFontAttributeName : font,
                                 NSForegroundColorAttributeName : [NSColor whiteColor],
                                 NSParagraphStyleAttributeName: style};
    
    NSAttributedString *buttonTitle = [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
    
    // Vertically align the text (could be cached)
    CGFloat fieldHeight = [[SPAuthenticationConfiguration sharedInstance] regularFontHeightForSize:fontSize];
    CGFloat fieldY = (controlView.frame.size.height - fieldHeight) / 2;
    cellFrame.origin.y = fieldY;
    [buttonTitle drawInRect:cellFrame];
}

@end
