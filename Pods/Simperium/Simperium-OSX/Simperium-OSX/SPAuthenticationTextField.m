//
//  SPAuthenticationTextField.m
//  Simplenote-OSX
//
//  Created by Michael Johnston on 7/24/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationTextField.h"
#import "SPAuthenticationConfiguration.h"

@interface SPAuthenticationTextField() {
    BOOL hasFocus;
}

@end

@implementation SPAuthenticationTextField

- (id)initWithFrame:(NSRect)frame secure:(BOOL)secure {
    self = [super initWithFrame:frame];
    if (self) {
        // Center the textField vertically
        int paddingX = 10;
        int fontSize = 20;
        CGFloat fieldHeight = [[SPAuthenticationConfiguration sharedInstance] regularFontHeightForSize:fontSize];
        CGFloat fieldY = (self.frame.size.height - fieldHeight) / 2;
        CGRect textFrame = NSMakeRect(paddingX, fieldY, frame.size.width-paddingX*2, fieldHeight);

        Class textFieldClass = secure ? [NSSecureTextField class] : [NSTextField class];
        _textField = [[textFieldClass alloc] initWithFrame:textFrame];
        NSFont *font = [NSFont fontWithName:[SPAuthenticationConfiguration sharedInstance].regularFontName size:fontSize];
        [_textField setFont:font];
        [_textField setTextColor:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
        [_textField setDrawsBackground:NO];
        [_textField setBezeled:NO];
        [_textField setBordered:NO];
        [_textField setFocusRingType:NSFocusRingTypeNone];
        [[_textField cell] setWraps:NO];
        [[_textField cell] setScrollable:YES];
        [self addSubview:_textField];
    }
    
    return self;
}

- (void)setStringValue:(NSString *)string {
    _textField.stringValue = string;
}

- (NSString *)stringValue {
    return _textField.stringValue;
}

- (void)setPlaceholderString:(NSString *)string {
    [[_textField cell] setPlaceholderString:string];
}

- (void)setDelegate:(id)delegate {
    _textField.delegate = delegate;
}

- (id)delegate {
    return _textField.delegate;
}

- (void)setEnabled:(BOOL)enabled {
    [_textField setEnabled:enabled];
    [_textField setEditable:enabled];
}

- (BOOL)hasFirstResponder {
	BOOL hasFirstResponder = NO;
	
	hasFirstResponder = ([[[_textField window] firstResponder] isKindOfClass:[NSTextView class]]
			   && [[_textField window] fieldEditor:NO forObject:nil]!=nil
			   && [_textField isEqualTo:(id)[(NSTextView *)[[_textField window] firstResponder]delegate]]);
	
	return hasFirstResponder;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *betterBounds = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:12.0 yRadius:12.0];
    [betterBounds addClip];
    
    
    if ([self hasFirstResponder]) {
        [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] setFill];
        [betterBounds fill];
        
        if (!hasFocus) {
            hasFocus = YES;
            [self setNeedsDisplay:YES];
        }
    } else {
        [[NSColor colorWithCalibratedWhite:250.f/255.f alpha:1.0] setFill];
        [betterBounds fill];

        
        [[NSColor colorWithCalibratedWhite:218.f/255.f alpha:1.0] setStroke];
        [betterBounds stroke];
        
        if (hasFocus) {
            hasFocus = NO;
            [self setNeedsDisplay:YES];
        }
    }
}

@end
