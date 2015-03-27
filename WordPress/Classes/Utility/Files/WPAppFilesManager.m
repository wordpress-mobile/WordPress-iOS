#import "WPAppFilesManager.h"

#import "ContextManager.h"
#import "Media.h"

@implementation WPAppFilesManager

#pragma mark - Application directories

+ (void)changeWorkingDirectoryToWordPressSubdirectory
{
    // Set current directory for WordPress app
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];
    
    BOOL isDir;
    if (![fileManager fileExistsAtPath:currentDirectoryPath isDirectory:&isDir] || !isDir) {
        [fileManager createDirectoryAtPath:currentDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [fileManager changeCurrentDirectoryPath:currentDirectoryPath];
}

#pragma mark - Media cleanup

+ (void)cleanUnusedMediaFileFromTmpDir
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{
        
        // Fetch Media URL's and return them as Dictionary Results:
        // This way we'll avoid any CoreData Faulting Exception due to deletions performed on another context
        NSString *localUrlProperty      = NSStringFromSelector(@selector(localURL));
        
        NSFetchRequest *fetchRequest    = [[NSFetchRequest alloc] init];
        fetchRequest.entity             = [NSEntityDescription entityForName:NSStringFromClass([Media class]) inManagedObjectContext:context];
        fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"ANY posts.blog != NULL AND remoteStatusNumber <> %@", @(MediaRemoteStatusSync)];
        
        fetchRequest.propertiesToFetch  = @[ localUrlProperty ];
        fetchRequest.resultType         = NSDictionaryResultType;
        
        NSError *error = nil;
        NSArray *mediaObjectsToKeep     = [context executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            DDLogError(@"Error cleaning up tmp files: %@", error.localizedDescription);
            return;
        }
        
        // Get a references to media files linked in a post
        DDLogInfo(@"%i media items to check for cleanup", mediaObjectsToKeep.count);
        
        NSMutableSet *pathsToKeep       = [NSMutableSet set];
        for (NSDictionary *mediaDict in mediaObjectsToKeep) {
            NSString *path = mediaDict[localUrlProperty];
            if (path) {
                [pathsToKeep addObject:path];
            }
        }
        
        // Search for [JPG || JPEG || PNG || GIF] files within the Documents Folder
        NSString *documentsDirectory    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSArray *contentsOfDir          = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        
        NSSet *mediaExtensions          = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", nil];
        
        for (NSString *currentPath in contentsOfDir) {
            NSString *extension = currentPath.pathExtension.lowercaseString;
            if (![mediaExtensions containsObject:extension]) {
                continue;
            }
            
            // If the file is not referenced in any post we can delete it
            NSString *filepath = [documentsDirectory stringByAppendingPathComponent:currentPath];
            
            if (![pathsToKeep containsObject:filepath]) {
                NSError *nukeError = nil;
                if ([[NSFileManager defaultManager] removeItemAtPath:filepath error:&nukeError] == NO) {
                    DDLogError(@"Error [%@] while nuking Unused Media at path [%@]", nukeError.localizedDescription, filepath);
                }
            }
        }
    }];
}

@end
