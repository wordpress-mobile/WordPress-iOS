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
	
	[page updateFromDictionary:postInfo];
    return page;
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    if ([remoteStatus intValue] == AbstractPostRemoteStatusSync) {
		return NSLocalizedString(@"Pages", @"");
    } else {
		return [super titleForRemoteStatus:remoteStatus];
	}
}

- (void )updateFromDictionary:(NSDictionary *)postInfo {
	self.postTitle      = [postInfo objectForKey:@"title"];
    self.postID         = [[postInfo objectForKey:@"page_id"] numericValue];
    self.content        = [postInfo objectForKey:@"description"];
    self.date_created_gmt    = [postInfo objectForKey:@"date_created_gmt"];
    self.status         = [postInfo objectForKey:@"page_status"];
    self.password       = [postInfo objectForKey:@"wp_password"];
    self.remoteStatus   = AbstractPostRemoteStatusSync;
	self.permaLink      = [postInfo objectForKey:@"permaLink"];
	self.mt_excerpt		= [postInfo objectForKey:@"mt_excerpt"];
	self.mt_text_more	= [postInfo objectForKey:@"mt_text_more"];
	self.wp_slug		= [postInfo objectForKey:@"wp_slug"];
}

- (void)uploadInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self hasRemote]) {
        if ([[WPDataController sharedInstance] wpEditPage:self]) {
			[[WPDataController sharedInstance] updateSinglePage:self];
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
			[[WPDataController sharedInstance] updateSinglePage:self];
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

- (BOOL)removeWithError:(NSError **)error {
	BOOL res = NO;
	if ([self hasRemote]) {
		WPDataController *dc = [[WPDataController alloc] init];
		[dc  wpDeletePage:self];
		if(dc.error) {
			if (error != nil) 
				*error = dc.error;
			WPLog(@"Error while deleting page: %@", [dc.error localizedDescription]);
		}
		//even if there was an error on the XML-RPC call we should always delete post from coredata
		//and inform the user about that error.
		//Wheter the post is still on the server it will be downloaded again when list is refreshed. 
		//Otherwise if someone has deleted a post on the server, you can't get rid of it		
		//there are other approach to solve this internally in the app, but i think this is the easiest one.
		res = YES; //the page doesn't exist anymore on the server. we can return YES even if there are errors deleting it from db
		[super removeWithError:nil]; 
		
		[dc release];
	} else {
		//we should remove the post from the db even if it is a "LocalDraft"
		res = [super removeWithError:nil]; 
	}
	return res;
}

@end
