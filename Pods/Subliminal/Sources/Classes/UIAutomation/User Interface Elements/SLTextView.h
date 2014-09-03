//
//  SLTextView.h
//  Subliminal
//
//  Created by Jeffrey Wear on 7/29/13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import "SLElement.h"
#import "SLKeyboard.h"

/**
 `SLTextView` matches instances of `UITextView`.
 */
@interface SLTextView : SLElement

/**
 The text displayed by the text view.
 
 @exception SLUIAElementInvalidException Raised by both `-text` and `-setText:`
 if the element is not valid by the end of the [default timeout](+[SLUIAElement defaultTimeout]).

 @exception SLUIAElementNotTappableException Raised, only by `setText:`, if the
 element is not tappable when whatever amount of time remains of the default
 timeout after the element becomes valid elapses.
 */
@property (nonatomic, copy) NSString *text;

/**
 Type the text in the text view with a specific keyboard.
 
 @param text A string to type into the text view.
 
 @param keyboard An `SLElement` that implements the `SLKeyboard` protocol,
 to be used to type the given string.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+[SLUIAElement defaultTimeout]).
 
 @exception SLUIAElementNotTappableException Raised if the element is not
 tappable when whatever amount of time remains of the default timeout after
 the element becomes valid elapses.
 */
- (void)setText:(NSString *)text withKeyboard:(id<SLKeyboard>)keyboard;

/**
 The default keyboard to be used by `-setText:` and `-setText:withKeyboard:`.
 
 Defaults to `SLKeyboard`.
 */
@property (nonatomic) id<SLKeyboard> defaultKeyboard;

@end


/**
 SLWebTextView matches text views displayed in web views.

 Such as HTML `textarea` elements.

 #### Configuring web text views' accessibility information

 A web text view's `[-label](-[SLUIAElement label])` is the text of a `DOM`
 element specified by the "aria-labelled-by" attribute, if present.
 See `SLWebTextView.html` and the `SLWebTextView` test cases of `SLTextViewTest`.
 */
@interface SLWebTextView : SLElement

/**
 The text displayed by the text view.

 `-text` returns the web text view's value (i.e. the `value` of the text area).

 @exception SLUIAElementInvalidException Raised by both `-text` and `-setText:`
 if the element is not valid by the end of the [default timeout](+[SLUIAElement defaultTimeout]).

 @exception SLUIAElementNotTappableException Raised, only by `-setText:`, if the
 element is not tappable when whatever amount of time remains of the default
 timeout after the element becomes valid elapses.
 */
@property (nonatomic, copy) NSString *text;

@end
