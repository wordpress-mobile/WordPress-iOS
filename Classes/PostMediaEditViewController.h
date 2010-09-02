//
//  PostMediaEditViewController.h
//  WordPress
//
//  Created by Chris Boyd on 8/31/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "UIDevice-Hardware.h"
#import "UIImage+Resize.h"
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "MediaManager.h"
#import "WPMediaUploader.h"

@interface PostMediaEditViewController : UIViewController <UITableViewDelegate> {
	IBOutlet UITableView *table;
	
	MediaType mediaType;
	Media *media;
	UIImageView *imageView;
	MPMoviePlayerController *moviePlayer;
	NSArray *buttons;
}

@property (nonatomic, retain) IBOutlet UITableView *table;
@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, retain) Media *media;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) NSArray *buttons;

@end
