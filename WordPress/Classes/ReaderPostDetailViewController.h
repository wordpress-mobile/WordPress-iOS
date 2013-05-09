//
//  ReaderPostDetailViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "WPRefreshViewController.h"

@interface ReaderPostDetailViewController : WPRefreshViewController <DetailViewDelegate>

- (id)initWithPost:(ReaderPost *)apost;

@end
