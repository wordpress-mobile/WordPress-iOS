//
//  SPAuthenticationTextField.h
//  Simplenote-OSX
//
//  Created by Michael Johnston on 7/24/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SPAuthenticationTextField : NSView

@property (assign) id delegate;
@property (strong) NSTextField *textField;

- (id)initWithFrame:(NSRect)frame secure:(BOOL)secure;
- (void)setPlaceholderString:(NSString *)string;
- (NSString *)stringValue;
- (void)setStringValue:(NSString *)string;
- (void)setEnabled:(BOOL)enabled;

@end
