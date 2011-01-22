//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"
#import "PageViewController.h"

#define TAG_OFFSET 1010

@implementation PagesViewController

- (void)syncPosts {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;
    // TODO: handle errors
    [self.blog syncPagesWithError:&error];
    [self performSelectorOnMainThread:@selector(refreshPostList) withObject:nil waitUntilDone:NO];
    [pool release];
}

- (void)showSelectedPost {
    Page *page = nil;
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSIndexPath *indexPath = self.selectedIndexPath;

    @try {
        page = [self.resultsController objectAtIndexPath:indexPath];
        WPLog(@"Selected page at indexPath: (%i,%i)", indexPath.section, indexPath.row);
    }
    @catch (NSException *e) {
        NSLog(@"Can't select page at indexPath (%i,%i)", indexPath.section, indexPath.row);
        NSLog(@"sections: %@", self.resultsController.sections);
        NSLog(@"results: %@", self.resultsController.fetchedObjects);
        page = nil;
    }
    self.postReaderViewController = [[PageViewController alloc] initWithPost:page];
    [delegate showContentDetailViewController:self.postReaderViewController];    
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Page";
}

@end
