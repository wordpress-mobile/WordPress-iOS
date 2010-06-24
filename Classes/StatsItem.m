//
//  StatsItem.m
//  WordPress
//
//  Created by Chris Boyd on 6/18/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "StatsItem.h"

@implementation StatsItem
@synthesize views, title, url, description, note, date;

- (id)init {
    if (self = [super init]) {
		// Do custom init here.
    }
	
    return self;
}

- (void)dealloc {
	[date release];
	[note release];
	[description release];
	[url release];
	[title release];
    [super dealloc];
}

@end
