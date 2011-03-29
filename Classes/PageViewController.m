    //
//  PageViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/17/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "PageViewController.h"
#import "EditPageViewController.h"
#import "Page.h"

@implementation PageViewController

- (void)checkForNewItem {
	if(!self.apost) //when it was a new page and user clicked on cancel
		self.apost = [Page newDraftForBlog:self.blog];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect frame = self.contentView.frame;
    // 93 is the height of Tags+Categories rows
    frame.origin.y -= 93;
    frame.size.height += 93;
    self.contentView.frame = frame;
}

-(EditPostViewController *) getPostOrPageController: (AbstractPost *) revision {
	EditPostViewController *postViewController = [[[EditPageViewController alloc] initWithPost:revision] autorelease];
	return postViewController;
}
@end
