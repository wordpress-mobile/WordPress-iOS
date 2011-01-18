    //
//  PageReaderViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/17/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "PageReaderViewController.h"
#import "PageViewController.h"

@implementation PageReaderViewController
- (id)initWithPost:(AbstractPost *)aPost {
    if (self = [super initWithNibName:@"PageReaderViewController-iPad" bundle:nil]) {
        self.apost = aPost;
    }
    
    return self;
}

- (void)showModalEditor {
    // In some cases, textViewShouldBeginEditing gets called twice
    // Don't try to show a second modal or it crashes
    if (self.modalViewController) {
        WPLog(@"showModalEditor: already has modal");
        return;
    }
    PageViewController *postViewController;
    
    AbstractPost *postRevision = [self.apost createRevision];
    postViewController = [[PageViewController alloc] initWithPost:postRevision];
    postViewController.hasChanges = NO;
    postViewController.editMode = kEditPost;
    [postViewController refreshUIForCurrentPost];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editorDismissed:) name:@"PostEditorDismissed" object:postViewController];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:postViewController];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:nav animated:YES];
    [nav release];
}
@end
