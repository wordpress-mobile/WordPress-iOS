//
//  NSDocument+DTFoundation.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/1/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSDocument+DTFoundation.h"

@implementation NSDocument (DTFoundation)

- (NSWindowController *)mainDocumentWindowController
{
	if (![self.windowControllers count])
	{
		return nil;
	}
	
	// TODO: what if there are more than one window for a document?
	return [self.windowControllers objectAtIndex:0];
}

@end
