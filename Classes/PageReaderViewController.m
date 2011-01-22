    //
//  PageReaderViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/17/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "PageReaderViewController.h"
#import "EditPageViewController.h"

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
    EditPageViewController *postViewController;
    
    AbstractPost *postRevision = [self.apost createRevision];
    postViewController = [[EditPageViewController alloc] initWithPost:postRevision];
    postViewController.hasChanges = NO;
    postViewController.editMode = kEditPost;
    [postViewController refreshUIForCurrentPost];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editorDismissed:) name:@"PostEditorDismissed" object:postViewController];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:postViewController];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.navigationBar.tintColor = [UIColor colorWithRed:31/256.0 green:126/256.0 blue:163/256.0 alpha:1.0];
    [self presentModalViewController:nav animated:YES];
    [nav release];
}
@end
