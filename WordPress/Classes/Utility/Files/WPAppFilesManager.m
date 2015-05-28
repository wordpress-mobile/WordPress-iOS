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

@end
