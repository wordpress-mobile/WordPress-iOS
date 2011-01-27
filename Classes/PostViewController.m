//
//  PostViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 12/30/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "PostViewController.h"


@implementation PostViewController
@synthesize titleLabel, tagsLabel, categoriesLabel;
@synthesize contentView;
@synthesize apost;

- (id)initWithPost:(AbstractPost *)aPost {
    if (self = [super initWithNibName:@"PostViewController-iPad" bundle:nil]) {
        self.apost = aPost;
    }
    
    return self;
}

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    } else {
        return nil;
    }
}

- (void)setPost:(Post *)aPost {
    self.apost = aPost;
}

- (void)refreshUI {
    titleLabel.text = self.apost.postTitle;
    if (self.post) {
        tagsLabel.text = self.post.tags;
        categoriesLabel.text = [self.post categoriesText];
    }
    contentView.text = self.apost.content;
}

- (void)viewDidLoad {
    [self refreshUI];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                target:self
                                                                                action:@selector(showModalEditor)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
}

// Subclassed in PageViewController
- (void)showModalEditor {
    if (self.modalViewController) {
        NSLog(@"Trying to show editor a second time: bad");
        return;
    }
    EditPostViewController *postViewController;
    
    AbstractPost *postRevision = [self.apost createRevision];
    postViewController = [[EditPostViewController alloc] initWithPost:postRevision];
    postViewController.editMode = kEditPost;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editorDismissed:) name:@"PostEditorDismissed" object:postViewController];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:postViewController];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.navigationBar.tintColor = [UIColor colorWithRed:31/256.0 green:126/256.0 blue:163/256.0 alpha:1.0];
    [self presentModalViewController:nav animated:YES];
    [postViewController release];
    [nav release];
}

- (void)editorDismissed:(NSNotification *)aNotification {
    [self refreshUI];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    // Did the touch ended inside?
    if (CGRectContainsPoint(self.view.frame, point)) {
        [self showModalEditor];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.apost = nil;
    self.contentView = nil;
    self.titleLabel = nil;
    self.tagsLabel = nil;
    self.categoriesLabel = nil;

    [super dealloc];
}

@end
