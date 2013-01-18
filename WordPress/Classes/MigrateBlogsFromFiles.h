//
//  MigrateBlogsFromFiles.h
//  WordPress
//
//  Created by Jorge Bernal on 2/14/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface MigrateBlogsFromFiles : NSEntityMigrationPolicy {

}
- (BOOL)forceBlogsMigrationInContext:(NSManagedObjectContext *)destMOC error:(NSError **)error;
@end
