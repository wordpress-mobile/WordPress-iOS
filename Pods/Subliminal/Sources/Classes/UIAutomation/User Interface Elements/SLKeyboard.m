//
//  SLKeyboard.m
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SLKeyboard.h"
#import "SLUIAElement+Subclassing.h"

@implementation SLKeyboard

+ (SLKeyboard *)keyboard {
    return [[self alloc] initWithUIARepresentation:@"UIATarget.localTarget().frontMostApp().keyboard()"];
}

- (void)typeString:(NSString *)string {
    /*
     The following bugs prevent `UIAKeyboard.typeString` from working correctly:
     
        *   in versions of iOS prior to 6.0, the function throws an exception
            when asked to type strings longer than one character
        *   on iOS 7, certain characters are mistyped--incorrectly capitalized, skipped entirely,
            or reported as not tappable

     We work around these by sending a separate `typeString` message
     for each character of the string to be typed.
     */
    NSString *escapedString = [string slStringByEscapingForJavaScriptLiteral];
    if ((kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1) &&
        (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)) {
        [self waitUntilTappable:YES
                thenSendMessage:@"typeString('%@')", escapedString];
    } else {
        NSString *quotedString = [NSString stringWithFormat:@"'%@'", escapedString];
        [self waitUntilTappable:YES thenPerformActionWithUIARepresentation:^(NSString *UIARepresentation) {
            // execute the typeString loop entirely within JavaScript, for improved performance
            [[SLTerminal sharedTerminal] evalFunctionWithName:@"SLKeyboardTypeString"
                                                       params:@[ @"keyboard", @"string" ]
                                                         body:@"for (var i = 0; i < string.length; i++) {\
                                                                    keyboard.typeString(string[i]);\
                                                                }"
                                                     withArgs:@[ UIARepresentation, quotedString ]];
        } timeout:[[self class] defaultTimeout]];
    }
}

- (void)typeString:(NSString *)string withSetValueFallbackUsingElement:(SLUIAElement *)element {
    @try {
        [self typeString:string];
    } @catch (id exception) {
        [[SLLogger sharedLogger] logWarning:[NSString stringWithFormat:@"-[SLKeyboard typeString:] will fall back on UIAElement.setValue due to an exception in UIAKeyboard.typeString: %@", exception]];
        [element waitUntilTappable:YES thenSendMessage:@"setValue('%@')", [string slStringByEscapingForJavaScriptLiteral]];
    }
}

- (void)hide
{
    [[SLKeyboardKey elementWithAccessibilityLabel:(@"Hide keyboard")] tap];
}

@end


@implementation SLKeyboardKey {
    NSString *_keyLabel;
}

+ (instancetype)elementWithAccessibilityLabel:(NSString *)label
{
    return [[self alloc] initWithAccessibilityLabel:label];
}

- (instancetype)initWithAccessibilityLabel:(NSString *)label {
    NSParameterAssert([label length]);
    
    NSString *UIARepresentation = [NSString stringWithFormat:@"UIATarget.localTarget().frontMostApp().keyboard().elements()['%@']", label];
    self = [super initWithUIARepresentation:UIARepresentation];
    if (self) {
        _keyLabel = [label copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ label:\"%@\">", NSStringFromClass([self class]), _keyLabel];
}

@end
