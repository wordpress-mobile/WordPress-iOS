//
//  SPAuthenticationConfiguration.m
//  Simperium-OSX
//
//  Created by Michael Johnston on 7/29/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationConfiguration.h"

#define kFontTestString @"Testyj"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@implementation SPAuthenticationConfiguration

static SPAuthenticationConfiguration *gInstance = NULL;

+ (instancetype)sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
            gInstance = [[self alloc] init];
	});
    
    return(gInstance);
}

- (id)init {
    if ((self = [super init])) {
        _regularFontName = @"HelveticaNeue";
        _mediumFontName = @"HelveticaNeue-Medium";
        
#if TARGET_OS_IPHONE
#else
        self.controlColor = [NSColor colorWithCalibratedRed:65.f/255.f green:137.f/255.f blue:199.f/255.f alpha:1.0];
#endif
    }
    
    return self;
}

// Just quick and dirty fonts for now. Could be extended with colors.
// In an app this would likely be done in an external .plist file, but for a framework,
// keeping in code avoids having to include a resource.
#if TARGET_OS_IPHONE

- (float)regularFontHeightForSize:(float)size {
    // Not cached, but could be
    return [kFontTestString sizeWithFont:[UIFont fontWithName:self.regularFontName size:size]].height;
}

#else

- (NSFont *)regularFontWithSize:(CGFloat)size {
    return [NSFont fontWithName:_regularFontName size:size];
}

- (NSFont *)mediumFontWithSize:(CGFloat)size {
    return [NSFont fontWithName:_mediumFontName size:size];
}

- (float)regularFontHeightForSize:(float)size {
    // Not cached, but could be
    NSDictionary *attributes = @{NSFontAttributeName : [self regularFontWithSize:size],
                                 NSFontSizeAttribute : [NSString stringWithFormat:@"%f", size]};
    return [kFontTestString sizeWithAttributes:attributes].height;
}
#endif

@end
