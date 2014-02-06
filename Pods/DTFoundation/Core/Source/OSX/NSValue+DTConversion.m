//
//  NSValue+DTConversion.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSValue+DTConversion.h"

@implementation NSValue (DTConversion)

+ (NSValue *)valueWithCGAffineTransform:(CGAffineTransform)transform
{
    return [NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)];
}

+ (NSValue *)valueWithCGPoint:(CGPoint)point
{
    return [NSValue valueWithBytes:&point objCType:@encode(CGPoint)];
}

- (CGAffineTransform)CGAffineTransformValue
{
    CGAffineTransform transform;
    
    [self getValue:&transform];
    
    return transform;
}

- (CGPoint)CGPointValue
{
    CGPoint point;
    
    [self getValue:&point];
    
    return point;
}

@end
