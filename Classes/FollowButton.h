//
//  FollowButton.h
//  WordPress
//
//  Created by Beau Collins on 12/5/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FollowButtonState){
    FollowButtonStateNotFollowing,
    FollowButtonStateFollowing
};

@interface FollowButton : UIButton

@property FollowButtonState followState;

@end
