//
//  MediaObjectViewController.h
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "WordPressAppDelegate.h"
#import "MediaManager.h"
#import "Media.h"

@interface MediaObjectViewController : UIViewController <UIActionSheetDelegate, UIScrollViewDelegate> {
	WordPressAppDelegate *appDelegate;
	Media *media;
	MediaManager *mediaManager;
	MPMoviePlayerController *videoPlayer;
	UIImageView *imageView;
	UIButton *deleteButton, *insertButton;
	UIScrollView *scrollView;
	BOOL isDeleting, isInserting;
}

@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (nonatomic, retain) Media *media;
@property (nonatomic, retain) MediaManager *mediaManager;
@property (nonatomic, retain) IBOutlet MPMoviePlayerController *videoPlayer;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIButton *deleteButton, *insertButton;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isDeleting, isInserting;

- (IBAction)deleteObject:(id)sender;
- (IBAction)insertObject:(id)sender;

@end
