//
//  SoundUtil.m
//  WordPress
//
//  Created by Eric J on 10/25/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "SoundUtil.h"
#import <AudioToolbox/AudioToolbox.h>
#import "Constants.h"

@interface SoundUtil ()

@property (nonatomic) BOOL isPlaying;

@end


@implementation SoundUtil

@synthesize isPlaying;

+ (SoundUtil *)sharedInstance {
    static SoundUtil *sharedInstance;
    
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [[SoundUtil alloc] init];
        }
        return sharedInstance;
    }
}


+ (void)playPullSound {
    [self.sharedInstance playCafNamed:@"snd_pull"];
}


+ (void)playRollupSound {
    [self.sharedInstance playCafNamed:@"snd_rollup"];
}


+ (void)playSwipeSound {
    [self.sharedInstance playCafNamed:@"snd_swipe"];
}


+ (void)playDiscardSound {
    [self.sharedInstance playCafNamed:@"snd_discard"];
}


+ (void)playNotificationSound {
    [self.sharedInstance playCafNamed:@"n"]; //"n" for "notification"
}


- (void)playCafNamed:(NSString *)sound {
    if(self.isPlaying) return;
    if(![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsMuteSoundsKey]) {

        self.isPlaying = YES;
        
        SystemSoundID sndId;
        NSURL *toneURLRef = [[NSBundle mainBundle] URLForResource:sound withExtension:@"caf"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) toneURLRef, &sndId);
        
        AudioServicesAddSystemSoundCompletion(sndId,NULL,NULL, systemSoundCompletionCallback, (__bridge void*) self);
        
        AudioServicesPlaySystemSound(sndId);

    }
}

static void systemSoundCompletionCallback(SystemSoundID  mySSID, void* myself) {
    SoundUtil.sharedInstance.isPlaying = NO;
    AudioServicesRemoveSystemSoundCompletion (mySSID);
}

@end
