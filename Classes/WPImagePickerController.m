//
//  WPImagePickerController.m
//  WordPress
//
//  Created by Janakiram on 01/10/08.
//

#import "WPImagePickerController.h"
#import "WordPressAppDelegate.h"

@implementation WPImagePickerController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [super dealloc];
}

@end
