//
//  RevisionSelectorViewController.m
//  WordPress
//
//  Created by Maxime Biais on 10/07/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "RevisionSelectorViewController.h"
#import "AbstractPost.h"
#import "RevisionView.h"

#define LEFT_MARGIN_PERCENTAGE 0.02

@interface RevisionSelectorViewController ()

@end

@implementation RevisionSelectorViewController
@synthesize revisions, conflictMode, scrollingLocked, scrollView, pageControl, originalPost;
@synthesize revisionDate, revisionAuthor, postContent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)showConflictAlert {
    UIAlertView *conflictAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Conflict Detected", @"")
                                                            message:NSLocalizedString(@"Conflict Detected", @"")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label (shown in popups).")
                                                  otherButtonTitles:nil];
    [conflictAlert show];
}

- (CGRect)calculateRevisionViewRectForIndex:(int) index {
    CGRect frame;
    CGSize parentFrameSize = self.scrollView.frame.size;
    float leftMargin = parentFrameSize.width * LEFT_MARGIN_PERCENTAGE / 2;
    frame.origin.x = self.scrollView.frame.size.width * index + leftMargin;
    frame.origin.y = 0;
    frame.size = CGSizeMake(parentFrameSize.width * (1 - LEFT_MARGIN_PERCENTAGE), parentFrameSize.height);
    return frame;
}

- (void)loadRevisionViewWithIndex:(int) index {
    RevisionView *subview;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"RevisionView" owner:self options:nil];
    for (id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:[RevisionView class]]) {
            subview = (RevisionView *) currentObject;
            break;
        }
    }
    [subview initStyle];
    AbstractPost *aPost = [self.revisions objectAtIndex:index];
    if (conflictMode && index == 1) {
        revisionDate.text = NSLocalizedString(@"Local Revision",
                                              @"Local revision label when a conflict is detected.");
        revisionAuthor.text = @"";
    } else {
        if (aPost.date_modified_gmt) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            NSDate *localModifiedDate = [DateUtils GMTDateTolocalDate:aPost.date_modified_gmt];
            revisionDate.text = [dateFormatter stringFromDate:localModifiedDate];
        }
        if (aPost.author) {
            revisionAuthor.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"by", "by [author]"),
                                   aPost.author];
        }
    }
    postContent.text = [NSString stringWithFormat:@"Title: %@\n%@", aPost.postTitle, aPost.content];
    [self.scrollView addSubview:subview];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (int i = 0; i < self.scrollView.subviews.count; i++) {
        UIView *subview = [self.scrollView.subviews objectAtIndex:i];
        [subview setFrame:[self calculateRevisionViewRectForIndex:i]];
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * revisions.count,
                                             self.scrollView.frame.size.height);
    [self.view layoutSubviews];
}

- (void)useSelectedRevision:(id)sender {
    AbstractPost *selectedRevision = [self.revisions objectAtIndex:self.pageControl.currentPage];
    NSString *postTitle = selectedRevision.postTitle;
    if (selectedRevision != originalPost) {
        [originalPost cloneFrom:selectedRevision];
    }
    [originalPost uploadWithSuccess:^{
        WPFLog(@"post uploaded: %@", postTitle);
    } failure:^(NSError *error) {
        WPFLog(@"post failed: %@", [error localizedDescription]);
    }];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (conflictMode) {
        [self showConflictAlert];
    }
    
    // Set up navigation items
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_bg"]];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancel:)];

    self.navigationItem.leftBarButtonItem = cancelButton;
    UIBarButtonItem *useButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Use", @"The Use button on navigation bar in the RevisionSelector view")
                                                                     style:UIBarButtonItemStyleDone target:self
                                                                    action:@selector(useSelectedRevision:)];
    self.navigationItem.rightBarButtonItem = useButton;
    self.navigationItem.title = NSLocalizedString(@"Revisions",
                                                  @"Title on navigation bar in the RevisionSelector view");

    // Instantiate and update revision subviews
    for (int i = 0; i < self.revisions.count; i++) {
        [self loadRevisionViewWithIndex:i];
    }
    
    // Update scrollView and pageControl
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * revisions.count,
                                             self.scrollView.frame.size.height);
    self.pageControl.numberOfPages = revisions.count;

    // Move to last page / revision
    self.pageControl.currentPage = revisions.count - 1;
    [self forcePage:revisions.count - 1 animated:NO];
}

- (void)viewDidUnload {
    scrollView = nil;
    pageControl = nil;
    revisions = nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration {
    self.scrollingLocked = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
    [self scrollToCurrentPage];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * revisions.count,
                                             self.scrollView.frame.size.height);
    for (int i = 0; i < self.scrollView.subviews.count; i++) {
        UIView *subview = [self.scrollView.subviews objectAtIndex:i];
        [subview setFrame:[self calculateRevisionViewRectForIndex:i]];
    }
    [UIView commitAnimations];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * revisions.count,
                                             self.scrollView.frame.size.height);
    self.scrollingLocked = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender {
    if (self.scrollingLocked) {
        return ;
    }
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

- (void)forcePage:(int)page animated:(BOOL)animated {
    self.pageControl.currentPage = page;
    CGRect frame;
    frame.origin.x = self.scrollView.frame.size.width * page;
    frame.origin.y = 0;
    frame.size = self.scrollView.frame.size;
    [self.scrollView scrollRectToVisible:frame animated:animated];
}

- (IBAction)scrollToCurrentPage {
    [self forcePage:self.pageControl.currentPage animated:YES];
}

@end
