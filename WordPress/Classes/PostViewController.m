//
//  PostViewController.m
//  WordPress
//
//  Created by Eric Johnson on 2/25/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostViewController.h"
#import "AbstractPost.h"
#import "PostContentView.h"
#import "WPActivityDefaults.h"
#import "WPTableViewCell.h"
#import "EditPostViewController.h"
#import "PostPreviewViewController.h"
#import "WPImageSource.h"
#import "ContextManager.h"

CGFloat const WPPostDetailContentPadding = 44.0f;
NSString *const WPDetailPostRestorationKey = @"WPDetailPostRestorationKey";

@interface PostViewController ()<PostContentViewDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) AbstractPost *post;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentWrapperView;
@property (nonatomic, strong) PostContentView *postView;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSURL *featuredImageURL;
@end

@implementation PostViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    NSString *postID = [coder decodeObjectForKey:WPDetailPostRestorationKey];
    if (!postID) {
        return nil;
    }
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:postID]];
    if (!objectID) {
        return nil;
    }
    
    NSError *error = nil;
    AbstractPost *restoredPost = (AbstractPost *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredPost) {
        return nil;
    }
    
    return [[self alloc] initWithPost:restoredPost];
}

#pragma mark - Life Cycle Methods

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(AbstractPost *)post {
    self = [super init];
    if (self) {
        self.post = post;
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.post.postTitle;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentWrapperView];
    [self.contentWrapperView addSubview:self.postView];

    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
    editButton.accessibilityLabel = NSLocalizedString(@"Edit comment", @"Spoken accessibility label.");
    self.navigationItem.rightBarButtonItem = editButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postUpdated:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.post.managedObjectContext];
    [self configurePostView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateScrollHeight];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self.postView refreshMediaLayout]; // Resize media in the post detail to match the width of the new orientation.
    [self.postView setNeedsLayout];
    
    [self updateScrollHeight];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:[[self.post.objectID URIRepresentation] absoluteString] forKey:WPDetailPostRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

#pragma mark - Instance Methods

- (void)fetchFeaturedImage:(NSURL *)featuredImageURL {
    if ([featuredImageURL isEqual:self.featuredImageURL]) {
        return;
    }
    self.featuredImageURL = featuredImageURL;
    
    if (featuredImageURL) {
        [[WPImageSource sharedSource] downloadImageForURL:featuredImageURL withSuccess:^(UIImage *image) {
            [self.postView setFeaturedImage:image];
        } failure:^(NSError *error) {
            [self.postView setFeaturedImage:nil];
        }];
    } else {
        [self.postView setFeaturedImage:nil];
    }
}

- (PostContentView *)postView {
    if (!_postView) {
        CGFloat width = CGRectGetWidth(self.view.bounds);
        CGFloat x = 0.0f;
        UIViewAutoresizing mask = UIViewAutoresizingFlexibleWidth;
        if (IS_IPAD) {
            x = (width - WPTableViewFixedWidth) / 2.0f;
            width = WPTableViewFixedWidth;
            mask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        
        PostContentView *postView = [[PostContentView alloc] initWithFrame:CGRectMake(x, 0.0f, width, CGRectGetHeight(self.view.bounds)) showFullContent:YES];
        postView.autoresizingMask = mask;
        postView.delegate = self;
        self.postView = postView;
    }
    return _postView;
}

- (UIView *)contentWrapperView {
    // The content wrapper is a work around to let a user swipe on the margins to scroll,
    // and still let the postView calculate width based on its parent view.
    if (!_contentWrapperView) {
        CGFloat width = CGRectGetWidth(self.view.bounds);
        CGFloat x = 0.0f;
        UIViewAutoresizing mask = UIViewAutoresizingFlexibleWidth;
        if (IS_IPAD) {
            x = (width - WPTableViewFixedWidth) / 2.0f;
            width = WPTableViewFixedWidth;
            mask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        
        UIView *contentWrapperView = [[UIView alloc] initWithFrame:CGRectMake(x, 0.0, width, CGRectGetHeight(self.view.bounds))];
        contentWrapperView.autoresizingMask = mask;
        
        self.contentWrapperView = contentWrapperView;
    }
    
    return _contentWrapperView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIEdgeInsets contentInset = scrollView.contentInset;
        if (IS_IPAD) {
            contentInset.top = WPPostDetailContentPadding;
        }
        contentInset.bottom = WPPostDetailContentPadding;
        scrollView.contentInset = contentInset;
        self.scrollView = scrollView;
    }
    return _scrollView;
}

- (void)updateScrollHeight {
    CGRect frame = self.contentWrapperView.frame;
    frame.size.height = CGRectGetHeight(self.postView.frame);
    self.contentWrapperView.frame = frame;
    [self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.contentWrapperView.frame), CGRectGetHeight(self.contentWrapperView.frame))];
}

- (void)postUpdated:(NSNotification *)notification {
    [self configurePostView];
}

- (void)configurePostView {
    [self.postView configurePost:self.post withWidth:CGRectGetWidth(self.contentWrapperView.frame)];
    [self fetchFeaturedImage:[self.post featuredImageURLForDisplay]];
}

#pragma mark - Actions

- (void)editAction:(id)sender {
    EditPostViewController *editPostViewController = [[EditPostViewController alloc] initWithPost:self.post];
    editPostViewController.editorOpenedBy = StatsPropertyPostDetailEditorOpenedOpenedByPostsView;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];
    [self.view.window.rootViewController presentViewController:navController animated:YES completion:nil];
}


#pragma mark - PostContentView Delegate Methods

- (void)contentViewDidLoadAllMedia:(WPContentView *)contentView {
    [self.postView layoutIfNeeded];
    [self updateScrollHeight];
}

- (void)contentViewHeightDidChange:(WPContentView *)contentView {
    [self updateScrollHeight];
}

- (void)postView:(PostContentView *)postView didReceiveDeleteAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this post?", @"")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                               destructiveButtonTitle:NSLocalizedString(@"Delete", @"")
                                                    otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)postView:(PostContentView *)postView didReceivePreviewAction:(id)sender {
//    [WPMobileStats flagProperty:StatsPropertyPostDetailClickedPreview forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    PostPreviewViewController *vc = [[PostPreviewViewController alloc] initWithPost:self.post];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)postView:(PostContentView *)postView didReceiveShareAction:(id)sender {

    NSString *permaLink = self.post.permaLink;
    NSString *title = self.post.postTitle;
    
    NSMutableArray *activityItems = [NSMutableArray array];
    if (title) {
        [activityItems addObject:title];
    }
    [activityItems addObject:[NSURL URLWithString:permaLink]];
    
    NSArray *defaultActivities = [WPActivityDefaults defaultActivities];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:defaultActivities];
    if (title) {
        [activityViewController setValue:title forKey:@"subject"];
    }
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (!completed) {
            return;
        }
        [WPActivityDefaults trackActivityType:activityType withPrefix:@"PostDetail"];
    };
    
    if (IS_IPAD) {
        if (self.popover) {
            [self dismissPopover];
            return;
        }
        self.popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        self.popover.delegate = self;
        
        UIView *senderView = (UIView *)sender;
        CGRect frame = senderView.frame;
        frame = [self.scrollView convertRect:frame fromView:[senderView superview]];
        
        [self.popover presentPopoverFromRect:frame inView:self.scrollView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

#pragma mark - Popover Methods

- (void)dismissPopover {
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
}

#pragma mark - UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    [self.post deletePostWithSuccess:nil failure:^(NSError *error) {
        [WPError showXMLRPCErrorAlert:error];
    }];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
