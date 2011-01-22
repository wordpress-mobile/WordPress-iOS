//
//  PostViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 12/30/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "PostViewController.h"


@implementation PostViewController
@synthesize categoriesTextField, statusTextField, titleTextField, tagsTextField;
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
    titleTextField.text = self.apost.postTitle;
    if (self.post) {
        tagsTextField.text = self.post.tags;
        categoriesTextField.text = [self.post categoriesText];
    }
    statusTextField.text = self.apost.statusTitle;
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
    EditPostViewController *postViewController;
    
    AbstractPost *postRevision = [self.apost createRevision];
    postViewController = [[EditPostViewController alloc] initWithPost:postRevision];
    postViewController.hasChanges = NO;
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

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self showModalEditor];
    return NO;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self showModalEditor];
    return NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.apost = nil;
    self.contentView = nil;
    self.categoriesTextField = nil;
    self.statusTextField = nil;
    self.titleTextField = nil;
    self.tagsTextField = nil;

    [super dealloc];
}

@end
