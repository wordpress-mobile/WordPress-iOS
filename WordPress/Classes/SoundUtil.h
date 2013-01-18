//
//  SoundUtil.h
//  WordPress
//
//  Created by Eric J on 10/25/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoundUtil : NSObject
+ (SoundUtil *)sharedInstance;
+ (void)playPullSound;
+ (void)playRollupSound;
+ (void)playSwipeSound;
+ (void)playDiscardSound;
+ (void)playNotificationSound;

@end
