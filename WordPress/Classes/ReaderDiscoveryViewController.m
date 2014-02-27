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
    self.attributionView.followButton.selected = self.recommendedBlog.isFollowing;
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
    UIButton *followButton = self.attributionView.followButton;
    followButton.selected = !self.recommendedBlog.isFollowing;
    
    [self.recommendedBlog toggleFollowingWithSuccess:^{
        // noop
    } failure:^(NSError *error) {
        DDLogError(@"Error toggling follow of recommended blog: %@", error);
        followButton.selected = self.recommendedBlog.isFollowing;
    }];
}

- (void)trackSyncEvent {
    // noop
}

- (NSString *)endpoint {
    return [NSString stringWithFormat:@"sites/%d/posts/", self.recommendedBlog.siteID];
}

@end
