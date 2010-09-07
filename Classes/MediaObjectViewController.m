//
//  MediaObjectViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import "MediaObjectViewController.h"


@implementation MediaObjectViewController

@synthesize media, mediaManager, imageView, videoPlayer, deleteButton, insertButton;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if((media != nil) && ([media.mediaType isEqualToString:@"video"])) {
		videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:media.localURL]];
		[videoPlayer prepareToPlay];
		videoPlayer.view.frame = self.view.frame;
		[self.view addSubview:videoPlayer.view];
	}
	else if((media != nil) && ([media.mediaType isEqualToString:@"image"])) {
		imageView.image = [UIImage imageWithContentsOfFile:media.localURL];
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark -
#pragma mark Autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Custom methods

- (IBAction)deleteObject:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldDeleteMedia" object:media];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)insertObject:(id)sender {
	NSLog(@"inserting object into editor...");
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[insertButton release];
	[deleteButton release];
	[media release];
	[mediaManager release];
	[imageView release];
	[videoPlayer release];
    [super dealloc];
}


@end
