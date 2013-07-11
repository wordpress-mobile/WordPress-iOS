//
//  RevisionSelectorViewController.h
//  WordPress
//
//  Created by Maxime Biais on 10/07/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AbstractPost;

@interface RevisionSelectorViewController : UIViewController <UIScrollViewDelegate> {
    UIScrollView *scrollView;
    UIPageControl *pageControl;
    NSArray *revisions;
    AbstractPost *originalPost;
    // To avoid scrolling during rotation
    BOOL scrollingLocked;
    BOOL conflictMode;
}

@property (nonatomic, strong) NSArray *revisions;
@property (nonatomic, strong) AbstractPost *originalPost;
@property (nonatomic) BOOL conflictMode;
@property (nonatomic) BOOL scrollingLocked;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;

// Subview references
@property (nonatomic, strong) IBOutlet UILabel *revisionDate;
@property (nonatomic, strong) IBOutlet UILabel *revisionAuthor;
@property (nonatomic, strong) IBOutlet UITextView *postContent;

- (IBAction)scrollToCurrentPage;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender;
@end

