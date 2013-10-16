//
//  MGImageUtilitiesAppDelegate.m
//  MGImageUtilities
//
//  Created by Matt Gemmell on 04/07/2010.
//  Copyright Instinctive Code 2010.
//

#import "MGImageUtilitiesAppDelegate.h"
#import "UIImage+ProportionalFill.h"
#import "UIImage+Tint.h"

@implementation MGImageUtilitiesAppDelegate


@synthesize window;
@synthesize originalView;
@synthesize resultView;
@synthesize methodControl;
@synthesize tintSwitch;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Load a sample image for the demo.
    originalView.image = [UIImage imageNamed:@"original.png"];
	[self updateResult];
	
    [window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc
{
    [window release];
	
    [super dealloc];
}


- (IBAction)methodChanged:(id)sender
{
	[self updateResult];
}


- (IBAction)tintChanged:(id)sender
{
	[self updateResult];
}


- (void)updateResult
{
	UIImage *oldImage = originalView.image;
	UIImage *newImage;
	CGSize newSize = resultView.frame.size;
	
	// Resize the image using the user's chosen method.
	switch (methodControl.selectedSegmentIndex) {
		case 0:
			newImage = [oldImage imageScaledToFitSize:newSize]; // uses MGImageResizeScale
			break;
		case 1:
			newImage = [oldImage imageCroppedToFitSize:newSize]; // uses MGImageResizeCrop
			break;
		case 2:
			newImage = [oldImage imageToFitSize:newSize method:MGImageResizeCropStart];
			break;
		case 3:
			newImage = [oldImage imageToFitSize:newSize method:MGImageResizeCropEnd];
			break;
		default:
			break;
	}
	
	// If appropriate, tint the resulting image.
	if (tintSwitch.on) {
		newImage = [newImage imageTintedWithColor:[UIColor redColor]];
	}
	
	resultView.image = newImage;
}


@end
