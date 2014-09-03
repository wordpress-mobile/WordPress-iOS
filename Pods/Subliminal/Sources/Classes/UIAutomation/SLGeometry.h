//
//  SLGeometry.h
//  Subliminal
//
//  Created by Maximilian Tagher on 7/2/13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - CGRects

/**
 Converts a `CGRect` to a JavaScript `Rect` object, as described in
 http://developer.apple.com/library/ios/#documentation/ToolsLanguages/Reference/UIATargetClassReference/UIATargetClass/UIATargetClass.html
 
 @param rect A non-null `CGRect`.
 @return JavaScript which creates a `Rect` object.

 @exception NSInternalInconsistencyException if `rect` is `CGRectNull`.
 */
NSString *SLUIARectFromCGRect(CGRect rect);


/**
 Converts a string of JavaScript (that evaluates to a `Rect` object) to a `CGRect`.
 
 @param UIARect JavaScript which evaluates to a `Rect` object, e.g.
 `UIATarget.localTarget().frontMostApp().mainWindow().rect()`.
 @return A `CGRect`, or `CGRectNull` if the _UIARect_ was `nil`.
 */
CGRect SLCGRectFromUIARect(NSString *UIARect);
