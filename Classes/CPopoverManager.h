//
//  CPopoverManager.h
//  WordPress
//
//  Created by Jonathan Wight on 03/29/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKIt.h>

@interface CPopoverManager : NSObject {
	UIPopoverController *currentPopoverController;
}

+ (CPopoverManager *)instance;

@property (readwrite, nonatomic, strong) UIPopoverController *currentPopoverController;

@end
