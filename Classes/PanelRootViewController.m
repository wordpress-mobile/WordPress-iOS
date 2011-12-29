//
//  PanelRootViewController.m
//  WordPress
//
//  Created by Brad Angelcyk on 12/28/11.
//  Copyright (c) 2011 WordPress. All rights reserved.
//

#import "PanelRootViewController.h"
#import "StackScrollViewController.h"

@interface UIViewExt : UIView {} 
@end

@implementation UIViewExt
- (UIView *) hitTest: (CGPoint) pt withEvent: (UIEvent *) event 
{   
	
	UIView* viewToReturn=nil;
	CGPoint pointToReturn;
	
	UIView* uiRightView = (UIView*)[[self subviews] objectAtIndex:1];
	
	if ([[uiRightView subviews] objectAtIndex:0]) {
		
		UIView* uiStackScrollView = [[uiRightView subviews] objectAtIndex:0];	
		
		if ([[uiStackScrollView subviews] objectAtIndex:1]) {	 
			
			UIView* uiSlideView = [[uiStackScrollView subviews] objectAtIndex:1];	
			
			for (UIView* subView in [uiSlideView subviews]) {
				CGPoint point  = [subView convertPoint:pt fromView:self];
				if ([subView pointInside:point withEvent:event]) {
					viewToReturn = subView;
					pointToReturn = point;
				}
				
			}
		}
		
	}
	
	if(viewToReturn != nil) {
		return [viewToReturn hitTest:pointToReturn withEvent:event];		
	}
	
	return [super hitTest:pt withEvent:event];	
	
}

@end


@implementation PanelRootViewController
@synthesize stackScrollViewController, blogsViewController, delegate;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {		
        delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
        delegate.stackScrollViewController = [[StackScrollViewController alloc] init];	
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    rootView = [[UIViewExt alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    [rootView setBackgroundColor:[UIColor clearColor]];

    leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, self.view.frame.size.height)];
    leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    blogsViewController = [[BlogsViewController alloc] initWithFrame:CGRectMake(0, 0, leftMenuView.frame.size.width, leftMenuView.frame.size.height)];
    [blogsViewController.view setBackgroundColor:[UIColor clearColor]];
    [blogsViewController viewWillAppear:FALSE];
    [blogsViewController viewDidAppear:FALSE];
    [leftMenuView addSubview:blogsViewController.view];
    
    rightSlideView = [[UIView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, 0, rootView.frame.size.width - leftMenuView.frame.size.width, rootView.frame.size.height)];
    rightSlideView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    [delegate.stackScrollViewController.view setFrame:CGRectMake(0, 0, rightSlideView.frame.size.width, rightSlideView.frame.size.height)];
    [delegate.stackScrollViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight];
    [delegate.stackScrollViewController viewWillAppear:FALSE];
    [delegate.stackScrollViewController viewDidAppear:FALSE];
    [rightSlideView addSubview:delegate.stackScrollViewController.view];

    [rootView addSubview:leftMenuView];
    [rootView addSubview:rightSlideView];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"fabric.png"]]];
    [self.view addSubview:rootView];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [blogsViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [delegate.stackScrollViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[blogsViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [delegate.stackScrollViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}	
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    [super dealloc];
}

@end
