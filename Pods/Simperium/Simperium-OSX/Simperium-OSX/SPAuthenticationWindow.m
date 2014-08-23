//
//  SPAuthenticationWindow.m
//  Simplenote-OSX
//
//  Created by Michael Johnston on 7/20/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationWindow.h"

@implementation SPAuthenticationWindow
@synthesize initialLocation;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
        [self setAlphaValue:1.0];
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setHasShadow:YES];
    }
    
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
    // Get the mouse location in window coordinates.
    self.initialLocation = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect windowFrame = [self frame];
    NSPoint newOrigin = windowFrame.origin;
    
    // Get the mouse location in window coordinates.
    NSPoint currentLocation = [theEvent locationInWindow];
    
    // Update the origin with the difference between the new mouse location and the old mouse location.
    newOrigin.x += (currentLocation.x - initialLocation.x);
    newOrigin.y += (currentLocation.y - initialLocation.y);
    
    // Don't let window get dragged up under the menu bar
    if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
        newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
    }
    
    // Move the window to the new location
    [self setFrameOrigin:newOrigin];
}

@end
