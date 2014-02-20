/*
 * BlogSelectorViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import <UIKit/UIKit.h>

@interface BlogSelectorViewController : UITableViewController <NSFetchedResultsControllerDelegate>

- (id)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                selectedCompletion:(void (^)(NSManagedObjectID *selectedObjectID))selected
                  cancelCompletion:(void (^)())cancel;

@end
