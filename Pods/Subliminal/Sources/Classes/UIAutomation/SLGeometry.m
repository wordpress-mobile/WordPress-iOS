//
//  SLGeometry.m
//  Subliminal
//
//  Created by Maximilian Tagher on 7/2/13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import "SLGeometry.h"
#import "SLTerminal+ConvenienceFunctions.h"


NSString *SLUIARectFromCGRect(CGRect rect)
{
    NSCParameterAssert(!CGRectIsNull(rect));
    return [NSString stringWithFormat:@"{origin:{x:%f,y:%f}, size:{width:%f, height:%f}}",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height];
}

// `UIARect` is some string which evaluates to a `Rect`
CGRect SLCGRectFromUIARect(NSString *UIARect) {
    NSString *CGRectString = [[SLTerminal sharedTerminal] evalFunctionWithName:@"SLCGRectStringFromJSRect"
                                                                        params:@[ @"rect" ]
                                                                          body:@"if (!rect) return '';\
                                                                                 else return '{{' + rect.origin.x + ',' + rect.origin.y + '},\
                                                                                 {' + rect.size.width + ',' + rect.size.height + '}}';"
                                                                      withArgs:@[ UIARect ]];
    return ([CGRectString length] ? CGRectFromString(CGRectString) : CGRectNull);
}
