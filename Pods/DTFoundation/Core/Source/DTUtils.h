//
//  DTUtils.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 7/18/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

/**
 Various CoreGraphics-related utility functions
 */

CGSize sizeThatFitsKeepingAspectRatio(CGSize originalSize, CGSize sizeToFit);

CGSize sizeThatFillsKeepingAspectRatio(CGSize originalSize, CGSize sizeToFit);

/**
 Replacement for buggy CGSizeMakeWithDictionaryRepresentation
 @param dict The dictionary containing an encoded `CGSize`
 @param size The `CGSize` to decode from the dictionary
 @see http://www.cocoanetics.com/2012/09/radar-cgrectmakewithdictionaryrepresentation/
 */
BOOL DTCGSizeMakeWithDictionaryRepresentation(NSDictionary *dict, CGSize *size);

/**
 Replacement for buggy CGSizeCreateDictionaryRepresentation
 @param size The `CGSize` to encode in the returned dictionary
 @see http://www.cocoanetics.com/2012/09/radar-cgrectmakewithdictionaryrepresentation/
 */
NSDictionary *DTCGSizeCreateDictionaryRepresentation(CGSize size);

/**
 Replacement for buggy CGRectMakeWithDictionaryRepresentation
 @param dict The dictionary containing an encoded `CGRect`
 @param rect The `CGRect` to decode from the dictionary
 @see http://www.cocoanetics.com/2012/09/radar-cgrectmakewithdictionaryrepresentation/
 */
BOOL DTCGRectMakeWithDictionaryRepresentation(NSDictionary *dict, CGRect *rect);

/**
 Replacement for buggy CGRectCreateDictionaryRepresentation
 @param rect The `CGRect` to encode in the returned dictionary
 @see http://www.cocoanetics.com/2012/09/radar-cgrectmakewithdictionaryrepresentation/
 */
NSDictionary *DTCGRectCreateDictionaryRepresentation(CGRect rect);

/**
 Convenience method to find the center of a CGRect. Uses CGRectGetMidX and CGRectGetMidY.
 @returns The point which is the center of rect.
 */
CGPoint CGRectCenter(CGRect rect);



