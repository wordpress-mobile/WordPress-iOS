//
//  MediaObjectViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//  Code is poetry.
//

#import "MediaObjectViewController.h"


@implementation MediaObjectViewController

@synthesize media, imageView, videoPlayer, deleteButton, insertButton, cancelButton, isDeleting, isInserting, appDelegate, toolbar;
@synthesize scrollView;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSLog(@"media: %@", media);
	
	if((media != nil) && ([media.mediaType isEqualToString:@"video"])) {
		self.navigationItem.title = NSLocalizedString(@"Video", @"");
		videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:media.localURL]];
		[videoPlayer prepareToPlay];
		videoPlayer.view.frame = scrollView.frame;
		videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.view insertSubview:videoPlayer.view belowSubview:toolbar];
		[scrollView removeFromSuperview];
	}
	else if((media != nil) && ([media.mediaType isEqualToString:@"image"])) {
		self.navigationItem.title = NSLocalizedString(@"Image", @"");
		imageView.image = [UIImage imageWithContentsOfFile:media.localURL];
		if((imageView.image == nil) && (media.remoteURL != nil)) {
			imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:media.remoteURL]]];
		}
	}
	
	if (!DeviceIsPad()) { 
		NSMutableArray *items = [[toolbar.items mutableCopy] autorelease]; 
		[items removeObject: cancelButton]; 
		toolbar.items = items; 
	} 
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (videoPlayer) {
        [videoPlayer stop];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark UIScrollView delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)pScrollView {
	CGRect innerFrame = imageView.frame;
	CGRect scrollerBounds = pScrollView.bounds;
	
	if ((innerFrame.size.width < scrollerBounds.size.width) || (innerFrame.size.height < scrollerBounds.size.height))
	{
		CGFloat tempx = imageView.center.x - ( scrollerBounds.size.width / 2 );
		CGFloat tempy = imageView.center.y - ( scrollerBounds.size.height / 2 );
		CGPoint myScrollViewOffset = CGPointMake( tempx, tempy);
		
		pScrollView.contentOffset = myScrollViewOffset;
	}
	
	UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
	if(scrollerBounds.size.width > innerFrame.size.width)
	{
		anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
		anEdgeInset.right = -anEdgeInset.left;
	}
	if(scrollerBounds.size.height > innerFrame.size.height)
	{
		anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
		anEdgeInset.bottom = -anEdgeInset.top;
	}
	pScrollView.contentInset = anEdgeInset;
}

#pragma mark -
#pragma mark UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(isDeleting == YES) {
		switch (buttonIndex) {
			case 0:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:media];
                [media remove];
				if(DeviceIsPad() == YES)
					[self dismissModalViewControllerAnimated:YES];
				else
					[self.navigationController popViewControllerAnimated:YES];
				break;
			default:
				break;
		}
	}
	else if(isInserting == YES) {
		switch (buttonIndex) {
			case 0:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaAbove" object:media];
				if(DeviceIsPad() == YES)
					[self dismissModalViewControllerAnimated:YES];
				else
					[self.navigationController popViewControllerAnimated:YES];
				break;
			case 1:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
				if(DeviceIsPad() == YES)
					[self dismissModalViewControllerAnimated:YES];
				else
					[self.navigationController popViewControllerAnimated:YES];
				break;
			default:
				break;
		}
	}
}

#pragma mark -
#pragma mark Custom methods

- (IBAction)deleteObject:(id)sender {
	isDeleting = YES;
	isInserting = NO;
	
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"Delete %@?", @""), media.mediaTypeName];
	UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
													 destructiveButtonTitle:NSLocalizedString(@"Delete", @"") 
														  otherButtonTitles:nil];
	[deleteActionSheet showInView:self.view];
	[deleteActionSheet release];
}

- (IBAction)insertObject:(id)sender {
	isDeleting = NO;
	isInserting = YES;
	
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"Insert %@:", @""), media.mediaTypeName];
	UIActionSheet *insertActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
													 destructiveButtonTitle:nil
														  otherButtonTitles:NSLocalizedString(@"Above Content", @""), NSLocalizedString(@"Below Content", @""), nil];
	[insertActionSheet showInView:self.view];
	[insertActionSheet release];
}

- (IBAction)cancelSelection:(id)sender { 
 	if (DeviceIsPad()) 
		[self dismissModalViewControllerAnimated:YES]; 
 	} 

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[scrollView release], scrollView = nil;
	[insertButton release], insertButton = nil;
	[deleteButton release], deleteButton = nil;
	[media release], media = nil;
	[imageView release], imageView = nil;
	[videoPlayer release], videoPlayer = nil;
	[cancelButton release], cancelButton = nil;
	[toolbar release];
    [super dealloc];
}


@end
