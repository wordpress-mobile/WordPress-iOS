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

float const LeftMarginPercentage = 0.02f;

@interface RevisionSelectorViewController ()
    @property (nonatomic) BOOL scrollingLocked;
    @property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
    @property (nonatomic, retain) IBOutlet UIPageControl *pageControl;

    // Subview references
    @property (nonatomic, strong) IBOutlet UILabel *revisionDate;
    @property (nonatomic, strong) IBOutlet UITextView *postContent;

    - (IBAction)scrollToCurrentPage;
@end

@implementation RevisionSelectorViewController

#pragma mark -
#pragma mark Lifecycle Methods

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (int i = 0; i < _scrollView.subviews.count; i++) {
        UIView *subview = [_scrollView.subviews objectAtIndex:i];
        [subview setFrame:[self calculateRevisionViewRectForIndex:i]];
    }
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _revisions.count,
                                         _scrollView.frame.size.height);
    [self.view layoutSubviews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_conflictMode) {
        [self showConflictAlert];
    }

    // Set up navigation items
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
    for (int i = 0; i < _revisions.count; i++) {
        [self loadRevisionViewWithIndex:i];
    }

    // Update scrollView and pageControl
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _revisions.count,
                                             _scrollView.frame.size.height);
    _pageControl.numberOfPages = _revisions.count;

    // Move to last page / revision
    _pageControl.currentPage = _revisions.count - 1;

    // If conflict mode enabled show the local revision
    if (_conflictMode) {
        [self forcePage:_revisions.count - 1 animated:NO];
    }
}

#pragma mark -
#pragma mark Instance Methods

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
    CGSize parentFrameSize = _scrollView.frame.size;
    float leftMargin = parentFrameSize.width * LeftMarginPercentage / 2;
    frame.origin.x = _scrollView.frame.size.width * index + leftMargin;
    frame.origin.y = 0;
    frame.size = CGSizeMake(parentFrameSize.width * (1 - LeftMarginPercentage), parentFrameSize.height);
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
    AbstractPost *aPost = [_revisions objectAtIndex:index];
    if (_conflictMode && index == 1) {
        _revisionDate.text = NSLocalizedString(@"Local Revision",
                                              @"Local revision label when a conflict is detected.");
    } else {
        if (aPost.date_modified_gmt) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            NSDate *localModifiedDate = [DateUtils GMTDateTolocalDate:aPost.date_modified_gmt];
            _revisionDate.text = [dateFormatter stringFromDate:localModifiedDate];
        }
    }
    _postContent.text = [NSString stringWithFormat:@"%@: %@\n%@",
                        NSLocalizedString(@"Title", "post or page title label"), aPost.postTitle, aPost.content];
    [_scrollView addSubview:subview];
}

#pragma mark -
#pragma mark Buttons Delegate

- (void)useSelectedRevision:(id)sender {
    AbstractPost *selectedRevision = [_revisions objectAtIndex:_pageControl.currentPage];
    NSString *postTitle = selectedRevision.postTitle;
    if (selectedRevision != _originalPost) {
        [_originalPost cloneFrom:selectedRevision];
    }
    [_originalPost uploadWithSuccess:^{
        WPFLog(@"post uploaded: %@", postTitle);
    } failure:^(NSError *error) {
        WPFLog(@"post failed: %@", [error localizedDescription]);
    }];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration {
    _scrollingLocked = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
    [self scrollToCurrentPage];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _revisions.count,
                                             _scrollView.frame.size.height);
    for (int i = 0; i < _scrollView.subviews.count; i++) {
        UIView *subview = [_scrollView.subviews objectAtIndex:i];
        [subview setFrame:[self calculateRevisionViewRectForIndex:i]];
    }
    [UIView commitAnimations];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _revisions.count,
                                         _scrollView.frame.size.height);
    _scrollingLocked = NO;
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender {
    if (_scrollingLocked) {
        return ;
    }
    CGFloat pageWidth = _scrollView.frame.size.width;
    int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageControl.currentPage = page;
}

#pragma mark -
#pragma mark Paging

- (void)forcePage:(int)page animated:(BOOL)animated {
    _pageControl.currentPage = page;
    CGRect frame;
    frame.origin.x = _scrollView.frame.size.width * page;
    frame.origin.y = 0;
    frame.size = _scrollView.frame.size;
    [_scrollView scrollRectToVisible:frame animated:animated];
}

- (IBAction)scrollToCurrentPage {
    [self forcePage:_pageControl.currentPage animated:YES];
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
