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
	WordPressAppDelegate *__weak appDelegate;
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

@property (nonatomic, weak) WordPressAppDelegate *appDelegate;
@property (nonatomic, strong) Media *media;
@property (nonatomic, strong) IBOutlet MPMoviePlayerController *videoPlayer;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *insertButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cancelButton; 
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar; 
@property (nonatomic, assign) BOOL isDeleting, isInserting;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;

- (IBAction)deleteObject:(id)sender;
- (IBAction)insertObject:(id)sender;
- (IBAction)cancelSelection:(id)sender;

@end
