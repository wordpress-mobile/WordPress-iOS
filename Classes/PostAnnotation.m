//
//  PostAnnotation.m
//  WordPress
//
//  Created by Christopher Boyd on 3/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PostAnnotation.h"

@implementation PostAnnotation
@synthesize title, coordinate;

-(id)init {
	self = [super init];
    if (self != nil)
    {
		// etc
    }
    return self;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D) c{
	coordinate = c;
	return self;
}

-(void)dealloc {
	[title release];
	[super dealloc];
}

@end
