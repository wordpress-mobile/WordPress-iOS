//
//  SLKeyboard.h
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

#import "SLStaticElement.h"
#import "SLButton.h"

/**
 The `SLKeyboard` protocol declares a standard way to interact with your application's
 input views, such as the standard keyboard (the `SLKeyboard` class) as well as
 (in iOS 7 and above) custom input views subclassing
 `[UIInputView](https://developer.apple.com/library/iOS/documentation/UIKit/Reference/UIInputView_class/Reference/Reference.html)`.
 
 Conforming classes must override `+keyboard`, to vend instances,
 and `-typeString:`, to enter strings via instances' associated custom `UIInputView`s.
 */

@protocol SLKeyboard <NSObject>

/**
 Returns an element representing an instance of this input view.
 
 @return An element representing an instance of this input view.
 */
+ (instancetype)keyboard;

/**
 Taps the keys of the specified input view as required
 to generate the specified string.
 
 @param string The string to be typed using the input view.

 @exception NSGenericException This method should throw an exception of some type 
 if _string_ contains any characters that cannot be typed using this input view.
 If this method might throw an exception, the conforming class should also 
 implement `-typeString:withSetValueFallbackUsingElement:`.
 */
- (void)typeString:(NSString *)string;

@optional

/**
 Tap the keyboard's "Hide Keyboard" button to hide the keyboard without 
 executing any done/submit actions.
 */
- (void)hide;

/**
 Uses `-typeString:` to tap the keys of the input string on the
 receiver; if that method throws an exception, this method will then
 send the `setValue` JavaScript message to the input element as a fallback.
 
 Implementing this method allows `SLTextField`, `SLTextView`, and related classes
 to work around an input view's lack of support for certain characters.

 @param string The string to be typed on the keyboard or set as the value for
 element.
 @param element The user interface element on which the `setValue` JavaScript
 method will be called if the internal call to `-typeString:`
 throws an exception.
 */
- (void)typeString:(NSString *)string withSetValueFallbackUsingElement:(SLUIAElement *)element;

@end


/**
 `SLKeyboard` allows you to test whether your application's standard keyboard
 is visible, and type strings.

 To tap individual keys on the keyboard, use `SLKeyboardKey`.
 */
@interface SLKeyboard : SLStaticElement <SLKeyboard>

/**
 Returns an element representing the application's keyboard.

 @return An element representing the application's keyboard.
 */
+ (instancetype)keyboard;

/**
 Taps the keys of the specified keyboard as required
 to generate the specified string.

 This string may contain characters that do not appear on the keyboard
 in the keyboard's current state--the keyboard will change keyplanes
 as necessary to make the corresponding keys visible.

 @bug This method throws an exception if string contains any characters
 that can be accessed only through a tap-hold gesture, for example
 “smart-quotes.”  Note that `SLTextField`, `SLTextView`, and related classes
 work around this bug internally when their text contents are set with
 `-setText:`.

 @param string The string to be typed on the keyboard.
 */
- (void)typeString:(NSString *)string;

@end


/**
 Instances of `SLKeyboardKey` refer to individual keys on the application's keyboard.
 */
@interface SLKeyboardKey : SLStaticElement

/**
 Creates and returns an element which represents the keyboard key with the specified label.
 
 This is the designated initializer for a keyboard key.

 @param label The key's accessibility label.
 @return A newly created element representing the keyboard key with the specified label.
 */
+ (instancetype)elementWithAccessibilityLabel:(NSString *)label;

@end
