//
//  SPBinaryManager.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-22.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "Simperium.h"
#import "SPBinaryTransportDelegate.h"
#import "SPBinaryManager.h"
#import "SPUser.h"
#import "SPEnvironment.h"
#import "SPManagedObject.h"
#import "SPGhost.h"
#import "NSString+Simperium.h"
#import "JSONKit+Simperium.h"

@interface SPBinaryManager()
-(void)loadPendingBinaryDownloads;
-(void)loadPendingBinaryUploads;
@end

@implementation SPBinaryManager
@synthesize binaryAuthURL;
@synthesize pendingBinaryDownloads;
@synthesize pendingBinaryUploads;
@synthesize transmissionProgress;
@synthesize directory;
@synthesize delegates;
@synthesize keyPrefix;

-(id)initWithSimperium:(Simperium *)aSimperium {

    if (self = [super init]) {
        simperium = aSimperium;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.directory = [paths objectAtIndex:0];
        
        pendingBinaryDownloads = [NSMutableDictionary dictionaryWithCapacity:3];
        pendingBinaryUploads = [NSMutableDictionary dictionaryWithCapacity:3];
        delegates = [NSMutableSet setWithCapacity:3];
        transmissionProgress = [NSMutableDictionary dictionaryWithCapacity:3];
        [self loadPendingBinaryDownloads];
        [self loadPendingBinaryUploads];
    }
    
    return self;
}


-(void)loadPendingBinaryDownloads {
    NSString *pendingKey = [NSString stringWithFormat:@"SPPendingBinaryDownloads"];
	NSString *pendingJSON = [[NSUserDefaults standardUserDefaults] objectForKey:pendingKey];
    NSDictionary *pendingDict = [pendingJSON sp_objectFromJSONString];
    if (pendingDict && [pendingDict count] > 0)
        [pendingBinaryDownloads setValuesForKeysWithDictionary:pendingDict];    
}


-(void)loadPendingBinaryUploads {
    NSString *pendingKey = [NSString stringWithFormat:@"SPPendingBinaryUploads"];
	NSString *pendingJSON = [[NSUserDefaults standardUserDefaults] objectForKey:pendingKey];
    NSDictionary *pendingDict = [pendingJSON sp_objectFromJSONString];
    if (pendingDict && [pendingDict count] > 0)
        [pendingBinaryUploads setValuesForKeysWithDictionary:pendingDict];

}

-(void)savePendingBinaryDownloads {
    NSString *json = [pendingBinaryDownloads sp_JSONString];
    NSString *key = [NSString stringWithFormat:@"SPPendingBinaryDownloads"];
	[[NSUserDefaults standardUserDefaults] setObject:json forKey: key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)savePendingBinaryUploads {
    NSString *json = [pendingBinaryUploads sp_JSONString];
    NSString *key = [NSString stringWithFormat:@"SPPendingBinaryUploads"];
	[[NSUserDefaults standardUserDefaults] setObject:json forKey: key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)checkOrGetBinaryAuthentication {
    return NO;
}

- (void)setupAuth:(SPUser *)user {
    self.binaryAuthURL = [NSString stringWithFormat:@"%@%@/binary_token/",SPAuthURL,simperium.appID];
    /* once auth has been set, acquire binary credentials and make local dir */
    [self checkOrGetBinaryAuthentication];
}

-(void)addPendingReferenceToFile:(NSString *)filename fromKey:(NSString *)fromKey bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName
{
    NSMutableDictionary *binaryPath = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 fromKey, BIN_KEY,
                                 bucketName, BIN_BUCKET,
                                 attributeName, BIN_ATTRIBUTE, nil];

    //SPObjectPath *binaryPath = [[SPObjectPath alloc] initWithKey:fromKey className:bucketName memberName:memberName];
    NSLog(@"Simperium adding pending file reference for %@.%@=%@", fromKey, attributeName, filename);
    
    // Check to see if any references are already being tracked for this entity
    NSMutableArray *paths = [pendingBinaryDownloads objectForKey: filename];
    if (paths == nil) {
        paths = [NSMutableArray arrayWithCapacity:3];
        [pendingBinaryDownloads setObject: paths forKey: filename];
    }
    
    [paths addObject:binaryPath];
    [self startDownloading:filename];
    [self savePendingBinaryDownloads];
}

-(void)resolvePendingReferencesToFile:(NSString *)filename
{
    // The passed entity is now synced, so check for any pending references to it that can now be resolved
    NSMutableArray *paths = [pendingBinaryDownloads objectForKey: filename];
    if (paths != nil) {
        for (NSDictionary *path in paths) {
            NSString *fromKey = [path objectForKey:BIN_KEY];
            NSString *fromBucketName = [path objectForKey:BIN_BUCKET];
            NSString *attributeName = [path objectForKey:BIN_ATTRIBUTE];

            NSLog(@"Simperium resolving pending file reference for %@.%@=%@", fromKey, attributeName, filename);
            //for (id<SimperiumDelegate>delegate in delegates) {
                //                if ([delegate respondsToSelector:@selector(fileLoaded:forEntity:memberName:)]) {
                //                    [delegate fileLoaded:filename forEntity:binaryPath.entity memberName:binaryPath.memberName];
                //                }
            //}
            SPBucket *bucket = [simperium bucketForName:fromBucketName];
            SPManagedObject *object = [bucket objectForKey:fromKey];
            [object setValue:filename forKey: attributeName];
            [object.ghost.memberData setObject:filename forKey: attributeName];
            object.ghost.needsSave = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [simperium saveWithoutSyncing];
                NSSet *changedKeys = [NSSet setWithObject:fromKey];
                NSDictionary *userInfoAdded = [NSDictionary dictionaryWithObjectsAndKeys:
                                               fromBucketName, @"bucketName",
                                               changedKeys, @"keys", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ProcessorDidChangeObjectsNotification" object:self userInfo:userInfoAdded];
            });
        }
        
        // All references to entity were resolved above, so remove it from the pending array
        [pendingBinaryDownloads removeObjectForKey:filename];
    }
    [self savePendingBinaryDownloads];
}

-(NSString *)pathForFilename:(NSString *)filename {
    NSString *binaryPath = [NSString stringWithFormat:@"%@/%@",self.directory,filename];
    return binaryPath;
}

-(NSString *)createNewFilename
{
    return [NSString sp_makeUUID];
}

-(NSString *)addBinary:(NSData *)binaryData toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName
{
    // Create paths to output image
    NSString *filename = [self createNewFilename];
    NSString *binaryPath = [self pathForFilename:filename];
    
    NSError *theError;
    if (![binaryData writeToFile:binaryPath options:NSDataWritingAtomic error: &theError]) {
        NSLog(@"Simperium error storing binary file: %@", [theError localizedDescription]);
    }
    
    [self addBinaryWithFilename:filename toObject:object bucketName:bucketName attributeName:attributeName];
    return [self prefixFilename: filename];
}

-(void)addBinaryWithFilename:(NSString *)filename toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName
{
    // Remember all the details so the filename can be set AFTER it has finished uploading
    // (otherwise other clients will try to download it before it's ready)
    //SPObjectPath *path = [[SPObjectPath alloc] initWithKey:object.simperiumKey className:bucketName attributeName:attributeName];
    NSMutableDictionary *path = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       object.simperiumKey, BIN_KEY,
                                       bucketName, BIN_BUCKET,
                                       attributeName, BIN_ATTRIBUTE, nil];

    [pendingBinaryUploads setObject:path forKey:[self prefixFilename: filename]];
    [self savePendingBinaryUploads];
    
    [self startUploading:filename];
}

-(void)finishedDownloading:(NSString *)filename
{
    [self resolvePendingReferencesToFile:filename];
    [transmissionProgress setObject:[NSNumber numberWithInt:0] forKey:filename];
    for (id<SPBinaryTransportDelegate>delegate in delegates) {
        if ([delegate respondsToSelector:@selector(binaryDownloadSuccessful:)]) 
            [delegate binaryDownloadSuccessful:filename];
    }
}

-(void)finishedUploading:(NSString *)filename
{
    // Safe now to set the filename parameter and sync it to other clients
    NSDictionary *path = [pendingBinaryUploads objectForKey:filename];
    NSString *fromKey = [path objectForKey:BIN_KEY];
    NSString *fromBucketName = [path objectForKey:BIN_BUCKET];
    NSString *attributeName = [path objectForKey:BIN_ATTRIBUTE];
    
    SPBucket *bucket = [simperium bucketForName:fromBucketName];
    NSManagedObject *object = [bucket objectForKey:fromKey];
    [object setValue:filename forKey:attributeName];
    [simperium save];
    [pendingBinaryUploads removeObjectForKey:filename];
    [self savePendingBinaryUploads];
    
    //[self resolvePendingReferencesToFile:filename];
    [transmissionProgress setObject:[NSNumber numberWithInt:0] forKey:filename];
    for (id<SPBinaryTransportDelegate>delegate in delegates) {
        if ([delegate respondsToSelector:@selector(binaryUploadSuccessful:)]) 
            [delegate binaryUploadSuccessful:filename];
    }
}

-(BOOL)binaryExists:(NSString *)filename {
    // Implemented by subclass
    return NO;
}

-(NSData *)dataForFilename:(NSString *)filename {
    // Implemented by subclass
    return nil;
}
-(void)startDownloading:(NSString *)filename {
    // Implemented by subclass
}
-(void)startUploading:(NSString *)filename {
    // Implemented by subclass
}

-(NSString *)prefixFilename:(NSString *)filename {
    return filename;
}

-(BOOL)createLocalDirectoryForPrefix: (NSString *)prefixString {

    NSFileManager *filemgr;
    NSArray *dirPaths;
    NSString *docsDir;
    NSString *newDir;
    
    filemgr =[NSFileManager defaultManager];
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                   NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    newDir = [docsDir stringByAppendingPathComponent:prefixString];
    BOOL tempBool;
    
    if (([filemgr fileExistsAtPath:newDir isDirectory:&tempBool]) && (tempBool)) {
        return YES;
    }
    
    if ([filemgr createDirectoryAtPath:newDir withIntermediateDirectories:YES attributes:nil error: NULL] == NO)
    {
        return NO;
    }
    
    return YES;
}

-(int)sizeOfLocalFile:(NSString *)filename {
        
    if (![self binaryExists:filename])
        return 0;
    
    NSString *binaryPath = [self pathForFilename:filename];
    
    NSError *theError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:binaryPath error:&theError];
    
    if (theError) {
        NSLog(@"Simperium error loading binary file (%@): %@", binaryPath, [theError localizedDescription]);
        return 0;
    }
    
    NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
    return [fileSize intValue];
}

-(int)sizeOfRemoteFile:(NSString *)filename {
    // To be implemented by subclass
    return -1;
}

-(int)sizeRemainingToTransmit:(NSString *)filename {
    return [[transmissionProgress objectForKey:filename] intValue];
}

-(void)addDelegate:(id)delegate {
    [delegates addObject: delegate];
}

-(void)removeDelegate:(id)delegate {
    [delegates removeObject: delegate];
}

@end
