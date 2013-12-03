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

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];
	_appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	DDLogVerbose(@"media: %@", _media);
	
	if((_media != nil) && ([_media.mediaType isEqualToString:@"video"])) {
		self.navigationItem.title = NSLocalizedString(@"Video", @"");
		MPMoviePlayerController *vp = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:_media.localURL]];
        _videoPlayer = vp;
		_videoPlayer.view.frame = _scrollView.frame;
		_videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view insertSubview:_videoPlayer.view belowSubview:_toolbar];
		[_scrollView removeFromSuperview];
		[_videoPlayer prepareToPlay];
	}
	else if((_media != nil) && ([_media.mediaType isEqualToString:@"image"])) {
		self.navigationItem.title = NSLocalizedString(@"Image", @"");
		_imageView.image = [UIImage imageWithContentsOfFile:_media.localURL];
		if((_imageView.image == nil) && (_media.remoteURL != nil)) {
            [_imageView setImageWithURL:[NSURL URLWithString:_media.remoteURL]];
		}
	}
	 
	if (IS_IPAD) {
        CGRect rect = self.scrollView.frame;
        rect.origin.y = 44.0f;
        rect.size.height = rect.size.height - 44.0f;
        self.scrollView.frame = rect;
        
        UIToolbar *topToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
        topToolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        topToolbar.items = [NSArray arrayWithObjects:flex, _cancelButton, nil];
        [self.view addSubview:topToolbar];
	}
 
    self.toolbar.translucent = NO;
    self.toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    self.toolbar.tintColor = [UIColor whiteColor];
    self.leftSpacer.width = 1.0;
    self.rightSpacer.width = -8.0;

    _deleteButton.tintColor = [UIColor whiteColor];
    _cancelButton.tintColor = _deleteButton.tintColor;
    _insertButton.tintColor = _deleteButton.tintColor;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_videoPlayer && !_videoPlayer.fullscreen) {
        [_videoPlayer stop];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark UIScrollView delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)pScrollView {
	CGRect innerFrame = _imageView.frame;
	CGRect scrollerBounds = pScrollView.bounds;
	
	if ((innerFrame.size.width < scrollerBounds.size.width) || (innerFrame.size.height < scrollerBounds.size.height))
	{
		CGFloat tempx = _imageView.center.x - ( scrollerBounds.size.width / 2 );
		CGFloat tempy = _imageView.center.y - ( scrollerBounds.size.height / 2 );
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
    if(_isDeleting) {
		switch (buttonIndex) {
			case 0:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:_media];
                [_media remove];
				if(IS_IPAD)
                    [self dismissViewControllerAnimated:YES completion:nil];
				else
					[self.navigationController popViewControllerAnimated:YES];
				break;
			default:
				break;
		}
	}
	else if(_isInserting) {
		switch (buttonIndex) {
			case 0:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaAbove" object:_media];
				if(IS_IPAD)
                    [self dismissViewControllerAnimated:YES completion:nil];
				else
					[self.navigationController popViewControllerAnimated:YES];
				break;
			case 1:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:_media];
				if(IS_IPAD)
                    [self dismissViewControllerAnimated:YES completion:nil];
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
    if(_currentActionSheet) return;
    
	_isDeleting = YES;
	_isInserting = NO;
	
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"Delete %@?", @""), _media.mediaTypeName];
	UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
													 destructiveButtonTitle:NSLocalizedString(@"Delete", @"") 
														  otherButtonTitles:nil];
    
    if (IS_IPAD) {
        [deleteActionSheet showFromBarButtonItem:_deleteButton animated:YES];
    } else {
        [deleteActionSheet showInView:self.view];
    }
    self.currentActionSheet = deleteActionSheet;
}

- (IBAction)insertObject:(id)sender {
    if (_currentActionSheet) return;
    
	_isDeleting = NO;
	_isInserting = YES;
	
	NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"Insert %@:", @""), _media.mediaTypeName];
	UIActionSheet *insertActionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
																   delegate:self 
														  cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
													 destructiveButtonTitle:nil
														  otherButtonTitles:NSLocalizedString(@"Above Content", @""), NSLocalizedString(@"Below Content", @""), nil];
    if (IS_IPAD) {
        [insertActionSheet showFromBarButtonItem:_insertButton animated:YES];
    } else {
        [insertActionSheet showInView:self.view];
    }
    self.currentActionSheet = insertActionSheet;
}

- (IBAction)cancelSelection:(id)sender { 
 	if (IS_IPAD) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
