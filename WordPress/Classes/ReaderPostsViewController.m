//
//  ReaderPostsViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostsViewController.h"
#import "ReaderContext.h"

NSString *const ReaderLastSyncDateKey = @"ReaderLastSyncDate";

@interface ReaderPostsViewController ()

@end

@implementation ReaderPostsViewController

@synthesize currentTopic;

#pragma mark - DetailView Delegate Methods

- (void)resetView {
	
}

- (void)setBlog:(Blog *)blog {
	// Noop. The reader doesn't use a Blog entity.
}


- (NSString *)entityName {
	return @"ReaderPost";
}

- (NSDate *)lastSyncDate {
	return [[NSUserDefaults standardUserDefaults] objectForKey:ReaderLastSyncDateKey];
}

- (BOOL)hasMoreContent {
    return YES;
}


- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	
}

- (NSManagedObjectContext *)managedObjectContext {
	return [[ReaderContext sharedReaderContext] managedObjectContext];
}

- (NSFetchRequest *)fetchRequest {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(topicID == %@)", [self.currentTopic stringValue]]];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

	return fetchRequest;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
}


- (UITableViewCell *)newCell {
    // To comply with apple ownership and naming conventions, returned cell should have a retain count > 0, so retain the dequeued cell.
    NSString *cellIdentifier = [NSString stringWithFormat:@"_WPTable_%@_Cell", [self entityName]];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}


@end
