//
//  ResourcesTableViewSection.m
//  WordPress
//
//  Created by Josh Bassett on 29/07/09.
//

#import "ResourcesTableViewSection.h"

@implementation ResourcesTableViewSection

@synthesize numberOfRows, title, resources;

- (id)init {
    if (self = [super init]) {
        title = [NSString string];
        resources = [[NSMutableArray alloc] init];
    }

    return self;
}

- (id)initWithTitle:(NSString *)aTitle {
    if (self = [self init]) {
        title = [aTitle retain];
    }
    
    return self;
}

- (void)dealloc {
    [title release];
    [resources release];
    [super dealloc];
}

@end
