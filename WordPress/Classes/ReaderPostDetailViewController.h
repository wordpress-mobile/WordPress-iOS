/*
 * ReaderPostDetailViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

@class ReaderPost;

@interface ReaderPostDetailViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

- (id)initWithPost:(ReaderPost *)apost;

@end
