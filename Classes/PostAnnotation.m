//
//  PostAnnotation.m
//  WordPress
//
//  Created by Christopher Boyd on 3/8/10.
//  
//

#import "PostAnnotation.h"

@implementation PostAnnotation

-(id)initWithCoordinate:(CLLocationCoordinate2D) c{
    self = [super init];
    if (self != nil) {
        [self setCoordinate:c];
    }
	return self;
}

-(void)dealloc {
	[super dealloc];
}

@end
