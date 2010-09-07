//
//  MediaObjectViewController.h
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MediaManager.h"
#import "Media.h"

@interface MediaObjectViewController : UIViewController <UIActionSheetDelegate> {
	Media *media;
	MediaManager *mediaManager;
	MPMoviePlayerController *videoPlayer;
	UIImageView *imageView;
	UIButton *deleteButton, *insertButton;
}

@property (nonatomic, retain) Media *media;
@property (nonatomic, retain) MediaManager *mediaManager;
@property (nonatomic, retain) IBOutlet MPMoviePlayerController *videoPlayer;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIButton *deleteButton, *insertButton;

- (IBAction)deleteObject:(id)sender;
- (IBAction)insertObject:(id)sender;

@end
