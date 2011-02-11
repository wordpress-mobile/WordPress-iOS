//
//  Page.m
//  WordPress
//
//  Created by Jorge Bernal on 12/20/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Page.h"
#import "WPDataController.h"

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
    page.date_created_gmt    = [postInfo objectForKey:@"date_created_gmt"];
    page.status         = [postInfo objectForKey:@"page_status"];
    page.password       = [postInfo objectForKey:@"wp_password"];
    page.remoteStatus   = AbstractPostRemoteStatusSync;
	page.permaLink      = [postInfo objectForKey:@"permaLink"];
    
    return page;
}

- (void)uploadInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self hasRemote]) {
        if ([[WPDataController sharedInstance] wpEditPage:self]) {
            self.remoteStatus = AbstractPostRemoteStatusSync;
            [self performSelectorOnMainThread:@selector(didUploadInBackground) withObject:nil waitUntilDone:NO];
        } else {
            NSLog(@"Page update failed");
            self.remoteStatus = AbstractPostRemoteStatusFailed;
            [self performSelectorOnMainThread:@selector(failedUploadInBackground) withObject:nil waitUntilDone:NO];
        }
    } else {
        int postID = [[WPDataController sharedInstance] wpNewPage:self];
        if (postID == -1) {
            NSLog(@"Page upload failed");
            self.remoteStatus = AbstractPostRemoteStatusFailed;
            [self performSelectorOnMainThread:@selector(failedUploadInBackground) withObject:nil waitUntilDone:NO];
        } else {
            self.postID = [NSNumber numberWithInt:postID];
            self.remoteStatus = AbstractPostRemoteStatusSync;
            [self performSelectorOnMainThread:@selector(didUploadInBackground) withObject:nil waitUntilDone:NO];
        }
    }
    [self save];

    [pool release];
}

- (void)didUploadInBackground {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploaded" object:self];
}

- (void)failedUploadInBackground {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
}

- (void)upload {
    [super upload];
    [self save];

    self.remoteStatus = AbstractPostRemoteStatusPushing;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelectorInBackground:@selector(uploadInBackground) withObject:nil];
}

- (void)remove {
    if ([self hasRemote] && [[WPDataController sharedInstance] wpDeletePage:self]) {

    }
	[super remove]; //we should remove the page from the db even if it is a "LocalDraft"
}

@end
