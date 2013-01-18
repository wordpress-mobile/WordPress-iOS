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
// Creates an empty local post associated with blog
+ (Page *)newDraftForBlog:(Blog *)blog;
+ (Page *)findWithBlog:(Blog *)blog andPostID:(NSNumber *)postID;
// Takes the NSDictionary from a XMLRPC call and creates or updates a post
+ (Page *)createOrReplaceFromDictionary:(NSDictionary *)postInfo forBlog:(Blog *)blog;

@end
