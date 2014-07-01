//
//  SPAuthenticationWindow.h
//  Simplenote-OSX
//
//  Created by Michael Johnston on 7/20/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SPAuthenticationWindow : NSWindow {
    NSPoint initialLocation;
}

@property (assign) NSPoint initialLocation;

@end
