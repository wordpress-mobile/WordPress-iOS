//
//  RevisionSelectorViewController.h
//  WordPress
//
//  Created by Maxime Biais on 10/07/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AbstractPost;

@interface RevisionSelectorViewController : UIViewController <UIScrollViewDelegate> {

}

@property (nonatomic, strong) NSArray *revisions;
@property (nonatomic, strong) AbstractPost *originalPost;
@property (nonatomic) BOOL conflictMode;

@end

