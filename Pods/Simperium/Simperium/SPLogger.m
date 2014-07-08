//
//  SPLogger.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 02/13/14.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPLogger.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static unsigned long long const SPLoggerDefaultMaxFilesize  = (1024 * 1024 * 2);
static NSUInteger const SPLoggerDefaultMaxLogfiles          = 20;
static NSString *const SPLoggerDefaultFileExtension         = @"log";


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPLogger ()
@property (nonatomic, strong) dispatch_queue_t      queue;
@property (nonatomic, strong) NSFileHandle          *logfileHandle;
@property (nonatomic, strong) dispatch_source_t     logfileNode;
@property (nonatomic, strong) NSDateFormatter       *logDateFormatter;
@end


#pragma mark ====================================================================================
#pragma mark SPLogger
#pragma mark ====================================================================================

@implementation SPLogger

- (void)dealloc {
    [self closeLogfile];
}

- (instancetype)init {
	if ((self = [super init])) {
		self.sharedLogLevel     = SPLogLevelsOff;
        self.queue              = dispatch_queue_create("com.simperium.SPLogger", NULL);
        self.maxLogfileSize     = SPLoggerDefaultMaxFilesize;
        self.maxLogfiles        = SPLoggerDefaultMaxLogfiles;
        self.writesToDisk       = NO;
	}
	return self;
}

+ (instancetype)sharedInstance {
	static SPLogger* logger;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		logger = [[[self class] alloc] init];
	});
	
	return logger;
}

- (void)logWithLevel:(SPLogLevels)level flag:(SPLogFlags)flag format:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	dispatch_async(self.queue, ^{
		if (_delegate) {
			[_delegate handleLogMessage:message];
		}
		
        if (_writesToDisk) {
            [self writeLogMessage:message];
        }
        
		NSLog(@"%@", message);
	});
}


#pragma mark ====================================================================================
#pragma mark Writing to Disk!
#pragma mark ====================================================================================

- (void)writeLogMessage:(NSString *)message {
    
    NSString *formattedDate     = [self.logDateFormatter stringFromDate:[NSDate date]];
    NSString *formattedMessage  = [NSString stringWithFormat:@"[%@] %@\n", formattedDate, message];
    NSData *logData             = [formattedMessage dataUsingEncoding:NSUTF8StringEncoding];
    
    @try {
        [self.logfileHandle writeData:logData];
        [self rotateLogfileIfNeeded];
    } @catch (NSException *exception) {
        NSLog(@"Disk Logger Error: %@", exception);
    }
}

- (NSDateFormatter *)logDateFormatter
{
    if (!_logDateFormatter) {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat        = @"yyyy-MM-dd HH:mm:ss.sss";
        _logDateFormatter               = dateFormatter;
    }
    return _logDateFormatter;
}

- (NSFileHandle *)logfileHandle {
    if (!_logfileHandle) {

        // Nuke old logfiles
        [self nukeOldLogfiles];
        
        // Prepare the fileHandle
        NSURL *logFileURL = [self createLogfileIfNeeded];
        
        _logfileHandle = [NSFileHandle fileHandleForWritingAtPath:logFileURL.path];
        [_logfileHandle seekToEndOfFile];
        
        // Listen for Deletions / Rename's
        if (_logfileHandle) {
            // Listen for Logfile Deletion / Rename events, and react!
            _logfileNode = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                  _logfileHandle.fileDescriptor,
                                                  DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME,
                                                  self.queue);
            
            dispatch_source_set_event_handler(_logfileNode, ^{ @autoreleasepool {
                NSLog(@"Logfile nuked. Generating a new one!");
                [self closeLogfile];
            }});
            
            dispatch_resume(_logfileNode);
        }
    }
    
    return _logfileHandle;
}


#pragma mark ====================================================================================
#pragma mark File Logging: Creation
#pragma mark ====================================================================================

- (NSURL *)createLogfileIfNeeded {    
    // Make sure the baseURL exists
    NSError *error	= nil;
    NSURL *baseURL	= self.logfilesFolderURL;
    BOOL success	= [[NSFileManager defaultManager] createDirectoryAtURL:baseURL withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success) {
        NSLog(@"%@ could not create folder %@ :: %@", NSStringFromClass([self class]), baseURL, error);
    }
    
    // Let's create the logfile, if it's not already there
    NSString *fileName  = [self newLogfileName];
    NSURL *fileURL      = [baseURL URLByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSDictionary *attributes = nil;
            
#if TARGET_OS_IPHONE
        NSString *key   = [self supportsBackgroundMode] ? NSFileProtectionCompleteUntilFirstUserAuthentication : NSFileProtectionCompleteUnlessOpen;
        attributes      = @{ NSFileProtectionKey : key };
#endif
        
        if (![[NSFileManager defaultManager] createFileAtPath:fileURL.path contents:nil attributes:attributes]) {
            NSLog(@"%@ could not create file at path %@", NSStringFromClass([self class]), fileURL.path);
        } else {
            NSLog(@"%@ successfully created file at path %@", NSStringFromClass([self class]), fileURL.path);            
        }
    }
    
    return fileURL;
}

- (void)nukeOldLogfiles
{
    // Do we need to proceed?
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    NSArray *filenames          = [fileManager contentsOfDirectoryAtPath:self.logfilesFolderURL.path error:nil];
    if (_maxLogfiles == 0 || filenames.count < _maxLogfiles) {
        return;
    }
    
    // Make sure we nuke the oldest items
    NSMutableArray *sortedFilenames = [[filenames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    NSInteger logfileCount          = filenames.count;
    
    while (logfileCount >= _maxLogfiles) {
        // Lookup the filename
        NSString *filename = [sortedFilenames firstObject];
        [sortedFilenames removeObject:filename];

        // Failsafe: check the file extension
        NSURL *path = [self.logfilesFolderURL URLByAppendingPathComponent:filename];
        if ([path.pathExtension isEqual:SPLoggerDefaultFileExtension]) {
            [fileManager removeItemAtURL:path error:nil];
        }
        --logfileCount;
    }
}


#pragma mark ====================================================================================
#pragma mark File Logging: Paths
#pragma mark ====================================================================================

#if TARGET_OS_IPHONE

- (NSURL *)logfilesFolderURL {
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	return [appSupportURL URLByAppendingPathComponent:NSStringFromClass([self class])];
}

#else

- (NSURL *)logfilesFolderURL {
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	return [appSupportURL URLByAppendingPathComponent:NSStringFromClass([self class])];
}

#endif

- (NSString *)newLogfileName {
    NSString *filename = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!filename) {
        filename = [[NSProcessInfo processInfo] processName];
    }
    
    if (!filename) {
        filename = @"";
    }
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat        = @"yyyyMMdd-HHmmss";
    NSString *date                  = [dateFormatter stringFromDate:[NSDate date]];
    
    return [NSString stringWithFormat:@"%@-%@.%@", filename, date, SPLoggerDefaultFileExtension];
}


#if TARGET_OS_IPHONE

- (BOOL)supportsBackgroundMode {
    NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
    
    for (NSString *mode in backgroundModes) {
        if (mode.length > 0) {
            return YES;
        }
    }
    
    return NO;
}

#endif


#pragma mark ====================================================================================
#pragma mark File Logging: Properties
#pragma mark ====================================================================================

- (void)setMaximumFileSize:(unsigned long long)newMaximumFileSize {
    dispatch_async(self.queue, ^{
        self.maxLogfileSize = newMaximumFileSize;
        [self rotateLogfileIfNeeded];
    });
}


#pragma mark ====================================================================================
#pragma mark File Logging: Rotation
#pragma mark ====================================================================================

- (void)rotateLogfileIfNeeded {
    if (_maxLogfileSize <= 0) {
        return;
    }

    if (self.logfileHandle.offsetInFile >= _maxLogfileSize) {
        NSLog(@"Rotating Logfile!...");
        [self closeLogfile];
    }
}

- (void)closeLogfile {
    if (!_logfileHandle) {
        return;
    }

    if (_logfileNode) {
        dispatch_source_cancel(_logfileNode);
        _logfileNode = nil;
    }
    
    [_logfileHandle synchronizeFile];
    [_logfileHandle closeFile];
    _logfileHandle = nil;
}

@end
