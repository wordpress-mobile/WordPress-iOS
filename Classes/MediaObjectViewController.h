//
//  MediaObjectViewController.h
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//  Code is poetry.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "WordPressAppDelegate.h"
#import "Media.h"

@interface MediaObjectViewController : UIViewController <UIActionSheetDelegate, UIScrollViewDelegate> {
	WordPressAppDelegate *appDelegate;
	Media *media;
	MPMoviePlayerController *videoPlayer;
	UIImageView *imageView;
	UIBarButtonItem *deleteButton;
    UIBarButtonItem *insertButton;
	UIBarButtonItem *cancelButton; 
	UIScrollView *scrollView;
	BOOL isDeleting, isInserting;
	UIToolbar *toolbar;
    UIActionSheet *currentActionSheet;
}

@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (nonatomic, retain) Media *media;
@property (nonatomic, retain) IBOutlet MPMoviePlayerController *videoPlayer;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *insertButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton; 
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar; 
@property (nonatomic, assign) BOOL isDeleting, isInserting;
@property (nonatomic, retain) UIActionSheet *currentActionSheet;

- (IBAction)deleteObject:(id)sender;
- (IBAction)insertObject:(id)sender;
- (IBAction)cancelSelection:(id)sender;

@end
