//
//  Page.m
//  WordPress
//
//  Created by Jorge Bernal on 12/20/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Page.h"


@implementation Page
@dynamic parentID;

+ (Page *)newPageForBlog:(Blog *)blog {
    Page *page = [[Page alloc] initWithEntity:[NSEntityDescription entityForName:@"Page"
                                                          inManagedObjectContext:[blog managedObjectContext]]
               insertIntoManagedObjectContext:[blog managedObjectContext]];
    
    page.blog = blog;
    
    return page;
}

+ (Page *)newDraftForBlog:(Blog *)blog {
    Page *page = [self newPageForBlog:blog];
    page.dateCreated = [NSDate date];
    page.remoteStatus = AbstractPostRemoteStatusLocal;
    page.status = @"publish";
    [page save];
    
    return page;
}

+ (Page *)findWithBlog:(Blog *)blog andPostID:(NSNumber *)postID {
    NSSet *results = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@",postID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;
}

+ (Page *)createOrReplaceFromDictionary:(NSDictionary *)postInfo forBlog:(Blog *)blog {
    Page *page = [self findWithBlog:blog andPostID:[postInfo objectForKey:@"page_id"]];
    
    if (page == nil) {
        page = [[Page newPageForBlog:blog] autorelease];
    }
    
    page.postTitle      = [postInfo objectForKey:@"title"];
    page.postID         = [postInfo objectForKey:@"page_id"];
    page.content        = [postInfo objectForKey:@"description"];
    page.dateCreated    = [postInfo objectForKey:@"dateCreated"];
    page.status         = [postInfo objectForKey:@"page_status"];
    page.password       = [postInfo objectForKey:@"wp_password"];
    page.remoteStatus   = AbstractPostRemoteStatusSync;
    
    return page;
}

@end
