//
//  ReaderDiscoveryViewController.m
//  WordPress
//
//  Created by Eric Johnson on 1/15/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "ReaderDiscoveryViewController.h"
#import "WPTableViewControllerSubclass.h"
#import "WPContentViewSubclass.h"
#import "ReaderAttributionView.h"
#import "ReaderDiscoveryTableViewCell.h"
#import "UIImageView+AFNetworkingExtra.h"

@interface ReaderDiscoveryViewController ()

@property (nonatomic, strong) ReaderAttributionView *attributionView;

@end

@implementation ReaderDiscoveryViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = NSLocalizedString(@"You Might Like", @"");
    
    [self refreshTableHeaderView];
}

- (BOOL)canShowRecommendedBlogs {
    return NO;
}

- (Class)cellClass {
    return [ReaderDiscoveryTableViewCell class];
}

- (void)refreshTableHeaderView {
    if (!self.attributionView) {
        self.attributionView = [[ReaderAttributionView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, RPVAuthorViewHeight + RPVAuthorPadding)];
        [self.attributionView setAuthorDisplayName:self.recommendedBlog.title authorLink:self.recommendedBlog.domain];
        [self.attributionView.avatarImageView setImageWithURL:[NSURL URLWithString:self.recommendedBlog.imagePath] placeholderImage:[UIImage imageNamed:@"wpcom_blavatar"]];
        [self.attributionView.followButton addTarget:self action:@selector(followAction:) forControlEvents:UIControlEventTouchUpInside];
        self.attributionView.followButton.hidden = NO;
    }
    
    self.tableView.tableHeaderView = self.attributionView;
}

- (void)followAction:(id)sender {
    // TODO: Handle follow taps
//    UIButton *followButton = self.attributionView.followButton;
//    ReaderPost *post = self.post;
//    if (![post isFollowable])
//        return;
//    
//    followButton.selected = ![post.isFollowing boolValue]; // Set it optimistically
//	[post toggleFollowingWithSuccess:^{
//	} failure:^(NSError *error) {
//		DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
//		[followButton setSelected:[post.isFollowing boolValue]];
//	}];
}

- (void)trackSyncEvent {
    // noop
}

- (NSString *)endpoint {
    return [NSString stringWithFormat:@"sites/%d/posts/", self.recommendedBlog.siteID];
}

@end
