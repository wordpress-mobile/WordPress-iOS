//
//  ReaderPostDetailViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"

@interface ReaderPostDetailViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, DetailViewDelegate>

- (id)initWithPost:(ReaderPost *)apost;

@end
