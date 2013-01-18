//
//  Page.h
//  WordPress
//
//  Created by Jorge Bernal on 12/20/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractPost.h"

@interface Page : AbstractPost {

}
@property (nonatomic, strong) NSNumber * parentID;

#pragma mark Class Methods
/**
 Creates an empty local page associated with blog
 */
+ (Page *)newDraftForBlog:(Blog *)blog;

/**
 Retrieves the page with the specified `pageID` for a given blog

 @returns the specified page. Returns nil if there is no page with that id on the blog
 */
+ (Page *)findWithBlog:(Blog *)blog andPageID:(NSNumber *)pageID;

/**
 Retrieves the page with the specified `pageID` for a given blog. If the specified page doesn't exist, a new empty one is created

 @returns the specified page.
 */
+ (Page *)findOrCreateWithBlog:(Blog *)blog andPageID:(NSNumber *)pageID;

/**
 Updates the page properties with the results of a XML-RPC call

 @param pageInfo a dictionary with values returned from wp.getPages
 */
- (void)updateFromDictionary:(NSDictionary *)pageInfo;

@end
