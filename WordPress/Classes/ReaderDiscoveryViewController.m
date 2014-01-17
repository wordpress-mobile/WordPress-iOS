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

@interface ReaderDiscoveryViewController ()

@property (nonatomic, strong) ReaderAttributionView *attributionView;

@end

@implementation ReaderDiscoveryViewController

- (BOOL)canShowRecommendedBlogs {
    return NO;
}

- (Class)cellClass {
    return [ReaderDiscoveryTableViewCell class];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return RPVAuthorViewHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.attributionView) {
        return self.attributionView;
    }
    
    self.attributionView = [[ReaderAttributionView alloc] initWithFrame:CGRectZero];
    [self.attributionView setAuthorDisplayName:self.post.authorDisplayName authorLink:self.post.authorURL];
    self.attributionView.followButton.hidden = ![self.post isFollowable];
    
    [self.attributionView.followButton addTarget:self action:@selector(followAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return self.attributionView;
}

- (void)followAction:(id)sender {
    UIButton *followButton = self.attributionView.followButton;
    ReaderPost *post = self.post;
    if (![post isFollowable])
        return;
    
    followButton.selected = ![post.isFollowing boolValue]; // Set it optimistically
	[post toggleFollowingWithSuccess:^{
	} failure:^(NSError *error) {
		DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
		[followButton setSelected:[post.isFollowing boolValue]];
	}];
}

@end
