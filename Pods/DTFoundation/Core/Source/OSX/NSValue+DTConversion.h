//
//  NSValue+DTConversion.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Category on NSValue providing some struct encoding that is missing on Mac, but exists on iOS.
 */

@interface NSValue (DTConversion)

/**-------------------------------------------------------------------------------------
 @name Creating an NSValue
 ---------------------------------------------------------------------------------------
 */

/**
 Creates and returns a value object that contains the specified affine transform data.
 @param transform The value for the new object.
 @returns A new value object that contains the affine transform data.
 @see CGAffineTransformValue
 */
+ (NSValue *)valueWithCGAffineTransform:(CGAffineTransform)transform;

/**
 Creates and returns a value object that contains the specified point structure.
 @param point The value for the new object.
 @returns A new value object that contains the point information.
 */
+ (NSValue *)valueWithCGPoint:(CGPoint)point;

/**-------------------------------------------------------------------------------------
 @name Accessing Data
 ---------------------------------------------------------------------------------------
 */

/**
 Returns an affine transform structure representing the data in the receiver.
 @returns An affine transform structure containing the receiver’s value.
 @see valueWithCGAffineTransform:
 */
- (CGAffineTransform)CGAffineTransformValue;

/**
 Returns a point structure representing the data in the receiver.
 @returns A point structure containing the receiver’s value.
 @see valueWithCGPoint:
 */
- (CGPoint)CGPointValue;

@end
