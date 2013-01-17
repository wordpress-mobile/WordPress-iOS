//
//  FollowButton.h
//  WordPress
//
//  Created by Beau Collins on 12/5/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressComApi.h"

typedef NS_ENUM(NSUInteger, FollowButtonState){
    FollowButtonStateNotFollowing,
    FollowButtonStateFollowing
};

@interface FollowButton : UIView

@property (nonatomic) FollowButtonState followState;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) WordPressComApi *user;
@property (nonatomic, strong) NSString *label;
@property (nonatomic) CGFloat maxButtonWidth;

+ (FollowButton *)buttonWithLabel:(NSString *)label andApi:(WordPressComApi *)user andSiteID:(NSNumber *)siteID andFollowing:(FollowButtonState)following;

+ (FollowButton *)buttonFromAction:(NSDictionary *)action withApi:(WordPressComApi *)user;

- initWithLabel:(NSString *)label andApi:(WordPressComApi *)user andSiteID:(NSNumber *)siteId andFollowing:(FollowButtonState)following;

@end
