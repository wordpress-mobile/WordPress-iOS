//
//  WPPageControl.h
//  WordPress
//
//  Created by Dan Roundhill on 11/2/10.
//  Copyright 2010 WordPress. All rights reserved.
//	This class is used to have a blue dotted UIPageControl
//	http://www.onidev.com/2009/12/02/customisable-uipagecontrol/

#import <UIKit/UIKit.h>


@interface WPPageControl : UIPageControl {
	UIImage* mImageNormal;
	UIImage* mImageCurrent;
}

@property (nonatomic, readwrite, retain) UIImage* imageNormal;
@property (nonatomic, readwrite, retain) UIImage* imageCurrent;

@end
