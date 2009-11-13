//
//  CommentViewController.m
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import "CommentViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"

#define COMMENT_BODY_TOP        100
#define COMMENT_BODY_MAX_HEIGHT 4000
#define COMMENT_BODY_PADDING 20

#define kCustomButtonHeight     30.0

@interface CommentViewController (Private)

- (void)resizeCommentBodyLabel;
- (BOOL)isConnectedToHost;
- (void)moderateCommentWithSelector:(SEL)selector;
- (void)deleteThisComment;
- (void)approveThisComment;
- (void)markThisCommentAsSpam;
- (void)unapproveThisComment;

@end

@implementation CommentViewController

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [commentDetails release];
    [segmentedControl release];
    [segmentBarItem release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    segmentedControl = [[UISegmentedControl alloc] initWithItems:
                        [NSArray arrayWithObjects:
                         [UIImage imageNamed:@"up.png"],
                         [UIImage imageNamed:@"down.png"],
                         nil]];
    
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    
    segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    self.navigationItem.rightBarButtonItem = segmentBarItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self performSelector:@selector(reachabilityChanged)];
    [super viewWillAppear:animated];
}

- (void)reachabilityChanged {
    connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
    UIColor *textColor = connectionStatus == YES ? [UIColor blackColor] : [UIColor grayColor];

    commentAuthorLabel.textColor = textColor;
    commentPostTitleLabel.textColor = textColor;
    commentDateLabel.textColor = textColor;
    commentBodyLabel.textColor = textColor;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self resizeCommentBodyLabel];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//
//    if ([delegate isAlertRunning] == YES) {
//        return NO;
//    } else {
//        return YES;
//    }
	return NO;
}

#pragma mark -
#pragma mark Action Methods

- (void)segmentAction:(id)sender {
    if (currentIndex > -1) {
        if ([sender selectedSegmentIndex] == 0 && currentIndex > 0) {
            [self showComment:commentDetails atIndex:currentIndex - 1];
        } else if ([sender selectedSegmentIndex] == 1 && currentIndex < [commentDetails count] - 1) {
            [self showComment:commentDetails atIndex:currentIndex + 1];
        }
    }
}

- (void)deleteComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(deleteThisComment) withObject:nil];
}

- (void)approveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(approveThisComment) withObject:nil];
}

- (void)unApproveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(unapproveThisComment) withObject:nil];
}

- (void)spamComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(markThisCommentAsSpam) withObject:nil];
}

- (BOOL)isConnectedToHost {
    if (![[Reachability sharedReachability] remoteHostStatus] != NotReachable) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
                                            message:@"Operation is not supported now."
                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectionFailAlert show];
        [connectionFailAlert release];
        return NO;
    }

    return YES;
}

- (void)moderateCommentWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self isConnectedToHost]) {
        BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];

        NSArray *selectedComment = [NSArray arrayWithObjects:[commentDetails objectAtIndex:currentIndex], nil];

        [sharedDataManager performSelector:selector withObject:selectedComment withObject:[sharedDataManager currentBlog]];

        [sharedDataManager loadCommentTitlesForCurrentBlog];
        [self.navigationController popViewControllerAnimated:YES];
    }

    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
}

- (void)deleteThisComment {
    [self moderateCommentWithSelector:@selector(deleteComment:forBlog:)];
}

- (void)approveThisComment {
    [self moderateCommentWithSelector:@selector(approveComment:forBlog:)];
}

- (void)markThisCommentAsSpam {
    [self moderateCommentWithSelector:@selector(spamComment:forBlog:)];
}

- (void)unapproveThisComment {
    [self moderateCommentWithSelector:@selector(unApproveComment:forBlog:)];
}

- (void)resizeCommentBodyLabel {
    CGSize size = [commentBodyLabel.text sizeWithFont:commentBodyLabel.font
                    constrainedToSize:CGSizeMake(self.view.frame.size.width - COMMENT_BODY_PADDING, COMMENT_BODY_MAX_HEIGHT)
                        lineBreakMode:commentBodyLabel.lineBreakMode];
    scrollView.contentSize = CGSizeMake(size.width, COMMENT_BODY_TOP + size.height);
    commentBodyLabel.frame = CGRectMake(commentBodyLabel.frame.origin.x, COMMENT_BODY_TOP, size.width, size.height);
}

#pragma mark -
#pragma mark Public Methods

- (void)showComment:(NSArray *)comments atIndex:(int)index {
    currentIndex = index;
	commentDetails = [comments mutableCopy];
    NSDictionary *comment = [commentDetails objectAtIndex:currentIndex];
    
    static NSDateFormatter *dateFormatter = nil;
    int count = [commentDetails count];

    NSString *author = [[comment valueForKey:@"author"] trim];
    NSString *postTitle = [[comment valueForKey:@"post_title"] trim];
    NSString *commentBody = [[comment valueForKey:@"content"] trim];
    NSDate *createdAt = [comment valueForKey:@"date_created_gmt"];
    NSString *commentStatus = [comment valueForKey:@"status"];
    NSString *authorEmail = [comment valueForKey:@"author_email"];
    NSString *authorUrl = [comment valueForKey:@"author_url"];

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
    
	gravatarImageView.email = authorEmail;
	commentAuthorEmailLabel.text = authorEmail;
    commentAuthorLabel.text = author;
    commentAuthorUrlLabel.text = authorUrl;
    commentPostTitleLabel.text = [@"on " stringByAppendingString:postTitle];
    commentDateLabel.text = [@"" stringByAppendingString:[dateFormatter stringFromDate:createdAt]];
    commentBodyLabel.text = commentBody;
    
    [self resizeCommentBodyLabel];

    self.navigationItem.title = [NSString stringWithFormat:@"%d of %d", currentIndex + 1, count];

    if ([commentStatus isEqualToString:@"hold"]) {
        [approveAndUnapproveButtonBar setHidden:NO];
        [deleteButtonBar setHidden:YES];
    } else {
        [approveAndUnapproveButtonBar setHidden:YES];
        [deleteButtonBar setHidden:NO];
    }

    [approveButton setEnabled:NO];
    [unapproveButton setEnabled:NO];
    [spamButton1 setEnabled:YES];
    [spamButton2 setEnabled:YES];

    if ([commentStatus isEqualToString:@"hold"]) {
        [approveButton setEnabled:YES];
    } else if ([commentStatus isEqualToString:@"approve"]) {
        [unapproveButton setEnabled:YES];
    } else if ([commentStatus isEqualToString:@"spam"]) {
        [spamButton1 setEnabled:NO];
        [spamButton2 setEnabled:NO];
    }

    [segmentedControl setEnabled:TRUE forSegmentAtIndex:0];
    [segmentedControl setEnabled:TRUE forSegmentAtIndex:1];

    if (currentIndex == 0) {
        [segmentedControl setEnabled:FALSE forSegmentAtIndex:0];
    } else if (currentIndex == [commentDetails count] - 1) {
        [segmentedControl setEnabled:FALSE forSegmentAtIndex:1];
    }

}

@end
