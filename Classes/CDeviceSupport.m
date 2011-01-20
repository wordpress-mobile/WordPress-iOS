//
//  CDeviceSupport.m
//  WordPress
//
//  Created by Jonathan Wight on 03/29/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CDeviceSupport.h"

BOOL DeviceIsPad(void)
{

if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)])
	{
	return([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);	
	}

return(NO);
}

BOOL iOs4OrGreater(void) {
    static BOOL didCheckIfOnOS4 = NO;
    static BOOL runningOnOS4OrBetter = NO;
    
    if (!didCheckIfOnOS4) {
        NSString *systemVersion = [UIDevice currentDevice].systemVersion;
        NSInteger majorSystemVersion = 3;
        
        if (systemVersion != nil && [systemVersion length] > 0) { //Can't imagine it would be empty, but.
            NSString *firstCharacter = [systemVersion substringToIndex:1];
            majorSystemVersion = [firstCharacter integerValue];			
        }
        
        runningOnOS4OrBetter = (majorSystemVersion >= 4);
        didCheckIfOnOS4 = YES;
    }
    return runningOnOS4OrBetter;
}