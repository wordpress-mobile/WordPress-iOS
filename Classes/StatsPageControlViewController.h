//
//  StatsPageControlViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 10/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface StatsPageControlViewController : UIViewController <UIScrollViewDelegate>{
	
	UIScrollView *scrollView;
	UIPageControl *pageControl;
    NSMutableArray *viewControllers;
	BOOL pageControlUsed;
	NSString *chart1URL, *chart2URL, *chart3URL;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;
@property (nonatomic, retain) NSMutableArray *viewControllers;
@property (nonatomic, retain) NSString *chart1URL;
@property (nonatomic, retain) NSString *chart2URL;
@property (nonatomic, retain) NSString *chart3URL;

- (void) refreshImage:(int)chartID;
- (void)loadScrollViewWithPage:(int)page;

@end
