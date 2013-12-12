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

@interface MediaObjectViewController : UIViewController <UIActionSheetDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) WordPressAppDelegate *appDelegate;
@property (nonatomic, strong) Media *media;
@property (nonatomic, weak) MPMoviePlayerController *videoPlayer;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *insertButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *leftSpacer;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *rightSpacer;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, assign) BOOL isDeleting, isInserting;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;

- (IBAction)deleteObject:(id)sender;
- (IBAction)insertObject:(id)sender;
- (IBAction)cancelSelection:(id)sender;

@end
