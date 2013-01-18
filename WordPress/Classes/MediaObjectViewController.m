//
//  MediaObjectViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//  Code is poetry.
//

#import "MediaObjectViewController.h"
#import "UIColor+Helpers.h"

@implementation MediaObjectViewController

@synthesize media, imageView, videoPlayer, deleteButton, insertButton, cancelButton, isDeleting, isInserting, appDelegate, toolbar;
@synthesize scrollView;
@synthesize currentActionSheet;

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
		videoPlayer.view.frame = scrollView.frame;
		videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view insertSubview:videoPlayer.view belowSubview:toolbar];
		[scrollView removeFromSuperview];
		[videoPlayer prepareToPlay];
	}
	else if((media != nil) && ([media.mediaType isEqualToString:@"image"])) {
		self.navigationItem.title = NSLocalizedString(@"Image", @"");
		imageView.image = [UIImage imageWithContentsOfFile:media.localURL];
		if((imageView.image == nil) && (media.remoteURL != nil)) {
            [imageView setImageWithURL:[NSURL URLWithString:media.remoteURL]];
		}
	}
	
    if ([deleteButton respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        deleteButton.tintColor = color;
        cancelButton.tintColor = color;
        insertButton.tintColor = color;
    }    
	if (IS_IPAD) {
        CGRect rect = self.scrollView.frame;
        rect.origin.y = 44.0f;
        rect.size.height = rect.size.height - 44.0f;
        self.scrollView.frame = rect;
        
        UIToolbar *topToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
        topToolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        topToolbar.items = [NSArray arrayWithObjects:flex, cancelButton, nil];
        [self.view addSubview:topToolbar];
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.imageView = nil;
    self.insertButton = nil;
    self.deleteButton = nil;
    self.cancelButton = nil;
    self.scrollView = nil;
    self.toolbar = nil;
    self.currentActionSheet = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (videoPlayer && !videoPlayer.fullscreen) {
        [videoPlayer stop];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.currentActionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(isDeleting == YES) {
		switch (buttonIndex) {
			case 0:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:media];
                [media remove];
				if(IS_IPAD == YES)
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
				if(IS_IPAD == YES)
					[self dismissModalViewControllerAnimated:YES];
				else
					[self.navigationController popViewControllerAnimated:YES];
				break;
			case 1:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
				if(IS_IPAD == YES)
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
    if(currentActionSheet) return;
    
	isDeleting = YES;
	isInserting = NO;
	
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"Delete %@?", @""), media.mediaTypeName];
	UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
													 destructiveButtonTitle:NSLocalizedString(@"Delete", @"") 
														  otherButtonTitles:nil];
    
    if (IS_IPAD) {
        [deleteActionSheet showFromBarButtonItem:deleteButton animated:YES];
    } else {
        [deleteActionSheet showInView:self.view];
    }
    self.currentActionSheet = deleteActionSheet;
}

- (IBAction)insertObject:(id)sender {
    if (currentActionSheet) return;
    
	isDeleting = NO;
	isInserting = YES;
	
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"Insert %@:", @""), media.mediaTypeName];
	UIActionSheet *insertActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
													 destructiveButtonTitle:nil
														  otherButtonTitles:NSLocalizedString(@"Above Content", @""), NSLocalizedString(@"Below Content", @""), nil];
    if (IS_IPAD) {
        [insertActionSheet showFromBarButtonItem:insertButton animated:YES];
    } else {
        [insertActionSheet showInView:self.view];
    }
    self.currentActionSheet = insertActionSheet;
}

- (IBAction)cancelSelection:(id)sender { 
 	if (IS_IPAD) 
		[self dismissModalViewControllerAnimated:YES]; 
} 

@end
