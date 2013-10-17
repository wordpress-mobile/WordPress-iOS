/*
 * Copyright 2012 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License.
 *
 */

#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#error "Quantcast Measurement is not designed to be used with ARC. Please add '-fno-objc-arc' to this file's compiler flags"
#endif // __has_feature(objc_arc)


#import "QuantcastDataManager.h"
#import "QuantcastUtils.h"
#import "QuantcastDatabase.h"
#import "QuantcastEvent.h"
#import "QuantcastUploadManager.h"
#import "QuantcastParameters.h"
#import "QuantcastPolicy.h"
#import "QuantcastNetworkReachability.h"

#ifndef QCMEASUREMENT_DEFAULT_MAX_EVENT_RETENTION_COUNT 
#define QCMEASUREMENT_DEFAULT_MAX_EVENT_RETENTION_COUNT 10000
#endif

@interface QuantcastDataManager ()
@property (readonly) QuantcastDatabase* db;
@property (assign,nonatomic) NSUInteger maxEventRetentionCount;
@property (assign) BOOL isDataDumpInprogress;

-(BOOL)setUpEventDatabaseConnection;

-(NSArray*)recordedEventsWithDeleteDBEvents:(BOOL)inDoDeleteDBEvents;

@end

@implementation QuantcastDataManager
@synthesize db=_db;
@synthesize uploadManager=_uploadManager;
@synthesize policy=_policy;
@synthesize maxEventRetentionCount;
@synthesize opQueue=_opQueue;
@synthesize isDataDumpInprogress;

-(id)initWithOptOut:(BOOL)inOptOutStatus policy:(QuantcastPolicy*)inPolicy {
    self = [super init];
    
    if (self) {
        uploadEventCount = QCMEASUREMENT_DEFAULT_UPLOAD_EVENT_COUNT;
        backgroundUploadEventCount = QCMEASUREMENT_DEFAULT_BACKGROUND_UPLOAD_EVENT_COUNT;
        maxEventRetentionCount = QCMEASUREMENT_DEFAULT_MAX_EVENT_RETENTION_COUNT;
        isDataDumpInprogress = NO;
        
        _isOptOut = inOptOutStatus;
        
        if (![self setUpEventDatabaseConnection]) {
            return nil;
        }

        _uploadManager = nil;
        
        _opQueue = [[NSOperationQueue alloc] init];
        _opQueue.maxConcurrentOperationCount = 4; // prevent too many events from hitting datbase at once
        [_opQueue setName:@"com.quantcast.measure.operationsqueue.datamanager"];
         
        if ( nil != inPolicy) {
            _policy = [inPolicy retain];
        }
    }
    
    return self;
}

-(void)dealloc {
    
    [_opQueue cancelAllOperations];
    [_opQueue release];
    _opQueue = nil;

    
    [_uploadManager release];
    [_db release];
    [_policy release];
    
    [super dealloc];
}

-(void)enableDataUploadingWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachability {
    
    if ( nil == _uploadManager ) {
        _uploadManager = [[QuantcastUploadManager alloc] initWithReachability:inNetworkReachability];
        _uploadManager.enableLogging = self.enableLogging;
    }
}
#pragma mark - Debugging
@synthesize enableLogging=_enableLogging;

-(void)setEnableLogging:(BOOL)inEnableLogging {
    _enableLogging = inEnableLogging;
    
    self.uploadManager.enableLogging = inEnableLogging;
    self.db.enableLogging = inEnableLogging;
    self.policy.enableLogging = inEnableLogging;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"<QuantcastDataManager %p: database = %@>", self, self.db ];
}



#pragma mark - Measurement Database Management

#define QCSQL_CREATETABLE_EVENTS    @"create table events ( id integer primary key autoincrement, sessionId varchar not null, timestamp integer not null );"
#define QCSQL_CREATETABLE_EVENT     @"create table event ( eventid integer, name varchar not null, value varchar not null, FOREIGN KEY( eventid ) REFERENCES events ( id ) );"
#define QCSQL_CREATEINDEX_EVENT     @"create index event_eventid_idx on event (eventid);"

#define QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENT   @"insert-new-event"
#define QCSQL_PREPAREDQUERY_INSERTNEWEVENT      @"INSERT INTO events (sessionId, timestamp) VALUES ( ?1, ?2 );"

#define QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENTPARAMS   @"insert-new-event-params"
#define QCSQL_PREPAREDQUERY_INSERTNEWEVENTPARAMS      @"INSERT INTO event (eventid, name, value) VALUES ( ?1, ?2, ?3 );"

+(void)initializeMeasurementDatabase:(QuantcastDatabase*)inDB {
    
    @synchronized( self ) {
        // first determine if this is a new database.
        
        [inDB beginDatabaseTransaction];
        [inDB executeSQL:@"PRAGMA foreign_keys = ON;"];
        [inDB executeSQL:QCSQL_CREATETABLE_EVENTS];
        [inDB executeSQL:QCSQL_CREATETABLE_EVENT];
        [inDB executeSQL:QCSQL_CREATEINDEX_EVENT];
        [inDB endDatabaseTransaction];
    }
}

-(BOOL)setUpEventDatabaseConnection {
    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPathCreatingIfNeeded];
    
    if ( nil == cacheDir) {
        return NO;
    }
    
    NSString* qcDatabasePath = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_DATABASE_FILENAME];
    
    BOOL isNewDB = ![[NSFileManager defaultManager] fileExistsAtPath:qcDatabasePath];
    
    
    _db = [[QuantcastDatabase databaseWithFilePath:qcDatabasePath] retain];
    
    if (isNewDB) {
        // it's a new database, set it up.
        
        [QuantcastDataManager initializeMeasurementDatabase:_db];
    }
    
    
    // create prepared queries
    
    [self.db prepareQuery:QCSQL_PREPAREDQUERY_INSERTNEWEVENT withKey:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENT];
    [self.db prepareQuery:QCSQL_PREPAREDQUERY_INSERTNEWEVENTPARAMS withKey:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENTPARAMS];
    
    return YES;
}


#pragma mark - Recording Events
@synthesize uploadEventCount;
@synthesize backgroundUploadEventCount;

-(void)recordEvent:(QuantcastEvent*)inEvent {
    if ( nil != self.policy && (self.policy.isMeasurementBlackedout ) ) {
        return;
    }
    
    [self.opQueue addOperationWithBlock:^{
        
        if ( nil == self.db ) {
            if (self.enableLogging) {
                NSLog(@"QC Measurement: Tried to log event %@, but there was no database connection available.", inEvent);
            }
            return;
        }
            
        NSUInteger eventCount = 0;
        
        NSArray* eventInsertBoundData = [NSArray arrayWithObjects:inEvent.sessionID,[NSString stringWithFormat:@"%qi",(int64_t)[inEvent.timestamp timeIntervalSince1970]],nil];
        
        @synchronized( self ) {
            [self.db beginDatabaseTransaction];
            
            [self.db executePreparedQuery:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENT bindingInsertData:eventInsertBoundData];
            
            int64_t eventId = [self.db getLastInsertRowId];
            
            for (NSString* param in [inEvent.parameters allKeys]) {
                
                if ( nil != self.policy && [self.policy isBlacklistedParameter:param] ) {
                    continue;
                }
                
                id valueObj = [inEvent.parameters objectForKey:param];
                
                NSString* valueStr;
                
                if ( [valueObj isKindOfClass:[NSValue class]] ) { 
                    valueStr = [valueObj stringValue];
                }
                else if ( [valueObj isKindOfClass:[NSString class]] ) {
                    valueStr = (NSString*)valueObj;
                }
                else {
                    valueStr = [valueObj description];
                }
                
                NSArray* paramsInsertBoundData = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%qi",eventId], param, valueStr, nil];
                
                [self.db executePreparedQuery:QCSQL_PREPAREDQUERYKEY_INSERTNEWEVENTPARAMS bindingInsertData:paramsInsertBoundData];
            }
            
            [self.db endDatabaseTransaction];
            
            eventCount = [self eventCount];
            
        }
       
        if ( self.policy.hasUpdatedPolicyBeenDownloaded && !self.isDataDumpInprogress && ( eventCount >= self.uploadEventCount || ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground && eventCount >= self.backgroundUploadEventCount ) ) ) {
            [self initiateDataUpload];
        }
        else if ( eventCount >= self.maxEventRetentionCount ) {
            // delete the equivalent a upload
            
            [self trimEventsDatabaseBy:self.uploadEventCount];
            
        }

    } ];
    
 }

-(void)initiateDataUpload {

    self.isDataDumpInprogress = YES;
    
    [self.opQueue addOperationWithBlock:^{
        __block UIBackgroundTaskIdentifier backgroundTask = UIBackgroundTaskInvalid;
        
        backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            if ( UIBackgroundTaskInvalid != backgroundTask ) {
                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Ran out of time on background task %d", backgroundTask );
                }
                UIBackgroundTaskIdentifier taskToEnd = backgroundTask;
                backgroundTask = UIBackgroundTaskInvalid;
                [[UIApplication sharedApplication] endBackgroundTask:taskToEnd];
            }
        } ];

#ifndef QUANTCAST_UNIT_TEST // beginBackgroundTaskWithExpirationHandler: always returns UIBackgroundTaskInvalid when unit testing
        if ( UIBackgroundTaskInvalid == backgroundTask ) {
            if (self.enableLogging ) {
                  NSLog(@"QC Measurement: Could not start data manager dump due to the system providing a UIBackgroundTaskInvalid");
            }
            
            return;
        }
#endif
        
        if (self.enableLogging ) {
            NSLog(@"QC Measurement: Started data manager dump with background task %d", backgroundTask );
        }
        
        @synchronized(self) {
            if (self.policy.hasUpdatedPolicyBeenDownloaded) {
                NSString* uploadID = [QuantcastUploadManager generateUploadID];
                
                NSString* jsonFilePath = [self dumpDataManagerToFileWithUploadID:uploadID];
                
                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Dumped data manager to JSON file = %@",jsonFilePath);
                }
                
                if ( nil != self.uploadManager ) {
                    [self.uploadManager initiateUploadForReadyJSONFilesWithDataManager:self];
                }
                
            }
            
            self.isDataDumpInprogress = NO;           
        }
        
        if ( UIBackgroundTaskInvalid != backgroundTask ) {
            // sleep for a bit so that upload tasks have some time to start
            [NSThread sleepForTimeInterval:2.0];
            if (self.enableLogging ) {
                NSLog(@"QC Measurement: Ended data dump background task %d", backgroundTask);
            }
            UIBackgroundTaskIdentifier taskToEnd = backgroundTask;
            backgroundTask = UIBackgroundTaskInvalid;
            [[UIApplication sharedApplication] endBackgroundTask:taskToEnd];
        }
    } ];
    
}

-(NSArray*)recordedEvents {
    return [self recordedEventsWithDeleteDBEvents:NO];
}

-(NSArray*)recordedEventsWithDeleteDBEvents:(BOOL)inDoDeleteDBEvents {

    if ( nil == self.db ) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Could not generate list of recorded events because there is no database connection");
        }
        return nil;
        
    }
    NSMutableArray* eventList = nil;
    
    @synchronized( self ) {
        [self.db beginDatabaseTransaction];
        
        NSArray* dbEventList = nil;
        
        // first we move up to self.uploadEventCount records into a working table
        
        NSString* tempTableName = [NSString stringWithFormat:@"events_%qi", (int64_t) floor([[NSDate date] timeIntervalSince1970]*1000) ];
        
        NSString* createTempTableSQL = [NSString stringWithFormat:@"CREATE TEMPORARY TABLE %@ ( id integer primary key, sessionId varchar not null, timestamp integer not null );", tempTableName];
        
        [self.db executeSQL:createTempTableSQL];
        
        NSString* moveToTmpSQL = [NSString stringWithFormat:@"INSERT INTO %@ ( id, sessionId, timestamp ) SELECT id, sessionId, timestamp FROM events ORDER BY id LIMIT %d;", tempTableName, self.uploadEventCount ];
        
        if ( ![self.db executeSQL:moveToTmpSQL] ) {
            if (self.enableLogging) {
                NSLog(@"QC Measurement: Could not move events to dump to temporary table named %@", tempTableName );
            }
            
            return nil;
        }
        
        NSString* getEventsSQL = [NSString stringWithFormat:@"SELECT id, sessionId, timestamp FROM %@;", tempTableName];
        
        if ( ![self.db executeSQL:getEventsSQL withResultsColumCount:3 producingResults:&dbEventList]) {
            return nil;
        }

        if ( self.enableLogging ) {
            NSLog(@"QC Measurement: Starting dump of %d events from the event database.", [dbEventList count]);
        }
        
        eventList = [NSMutableArray arrayWithCapacity:[dbEventList count]];

        for ( NSArray* dbEventListRow in dbEventList ) {
            
            NSString* eventIdStr = [dbEventListRow objectAtIndex:0];
            
            
            int64_t eventId = 0;
            
            if (![[NSScanner scannerWithString:eventIdStr] scanLongLong:&eventId]) {
                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Could not scan an int64_t event ID from eventIdStr = %@ - skipping",eventIdStr);
                }
                continue;
            }
            
            
            NSString* sessionId = [dbEventListRow objectAtIndex:1];
            
            NSString* eventTimeIntervalStr = [dbEventListRow objectAtIndex:2];
            
            int64_t eventTimeStamp = 0;
            if (![[NSScanner scannerWithString:eventTimeIntervalStr] scanLongLong:&eventTimeStamp]) {
                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Could not scan an long long timestamp from eventTimeItnervalStr = %@ - skipping",eventTimeIntervalStr);
                }
                continue;
            }
            
            
            NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:eventTimeStamp];
            
            QuantcastEvent* e = [[[QuantcastEvent alloc] initWithSessionID:sessionId timeStamp:timestamp] autorelease];
            
            NSArray* eventParamList = nil;
            
            if (![self.db executeSQL:[NSString stringWithFormat:@"SELECT name, value FROM event WHERE eventid = %qi;",eventId] withResultsColumCount:2 producingResults:&eventParamList]) {
                return nil;
            }
            
            for ( NSArray* eventParamRow in eventParamList ) {
                
                NSString* param = [eventParamRow objectAtIndex:0];
                NSString* value = [eventParamRow objectAtIndex:1];
                
                [e putParameter:param withValue:value  enforcingPolicy:self.policy];
            }
            
            [eventList addObject:e];
        }
        
        if (inDoDeleteDBEvents) {
            
            NSString* deleteEventsSQL = [NSString stringWithFormat:@"DELETE FROM events WHERE id IN ( SELECT id FROM %@ );", tempTableName];
            NSString* deleteEventRecordsSQL = [NSString stringWithFormat:@"DELETE FROM event WHERE eventid IN ( SELECT id FROM %@ temp );", tempTableName];
            
            [self.db executeSQL:deleteEventsSQL];
            [self.db executeSQL:deleteEventRecordsSQL];
            
            // reset autoincrement in table?
            
            if ( [self.db rowCountForTable:@"events"] == 0 ) {
            
                [self.db setAutoIncrementTo:0 forTable:@"events"];
            }
        }

        [self.db endDatabaseTransaction];
    }
    
    return eventList;
}

-(NSUInteger)eventCount {
    
    if (nil == self.db) {
        return 0;
    }
    
    return [self.db rowCountForTable:@"events"];
}

-(void)trimEventsDatabaseBy:(NSUInteger)inEventsToDelete {
    
    self.isDataDumpInprogress = YES;
    
    [self.opQueue addOperationWithBlock:^{
        @synchronized(self) {
            [self.db beginDatabaseTransaction];
            
            int64_t curEventCount = [self.db rowCountForTable:@"events"];
            
            NSUInteger deleteEventCount = inEventsToDelete;
            
            if ( curEventCount < inEventsToDelete ) {
                deleteEventCount = curEventCount;
            }
            
            if (self.enableLogging) {
                NSLog(@"QC Measurement: Deleting %d events from the event database.", deleteEventCount);
            }
            // first we move up to MAX_EVENTS_PER_UPLOAD records into a working table
            
            NSString* tempTableName = [NSString stringWithFormat:@"events_%qi", (int64_t) floor([[NSDate date] timeIntervalSince1970]*1000) ];
            
            NSString* createTempTableSQL = [NSString stringWithFormat:@"CREATE TEMPORARY TABLE %@ ( id integer primary key, sessionId varchar not null, timestamp integer not null );", tempTableName];
            
            [self.db executeSQL:createTempTableSQL];
            
            
            NSString* moveToTmpSQL = [NSString stringWithFormat:@"INSERT INTO %@ ( id, sessionId, timestamp ) SELECT id, sessionId, timestamp FROM events ORDER BY id LIMIT %d;", tempTableName, deleteEventCount ];
            
            if ( ![self.db executeSQL:moveToTmpSQL] ) {
                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Could not move events to dump to temporary table named %@", tempTableName );
                }
                
                return;
            }
            
            NSString* deleteEventsSQL = [NSString stringWithFormat:@"DELETE FROM events WHERE id IN ( SELECT id FROM %@ );", tempTableName];
            NSString* deleteEventRecordsSQL = [NSString stringWithFormat:@"DELETE FROM event WHERE eventid IN ( SELECT id FROM %@ temp );", tempTableName];
            
            [self.db executeSQL:deleteEventsSQL];
            [self.db executeSQL:deleteEventRecordsSQL];

            if ( [self.db rowCountForTable:@"events"] == 0 ) {
                
                [self.db setAutoIncrementTo:0 forTable:@"events"];
            }
            
            [self.db endDatabaseTransaction];
            
            self.isDataDumpInprogress = NO;
        }
    } ];
}

#pragma mark - Data File Management

-(NSString*)dumpDataManagerToFileWithUploadID:(NSString*)inUploadID {
    
    // first check to see if policy is ready
    if (!self.policy.hasUpdatedPolicyBeenDownloaded) {
        return nil;
    }
    
    NSString* genDirPath = [QuantcastUtils quantcastDataGeneratingDirectoryPath];
    
    NSString* filename = [inUploadID stringByAppendingPathExtension:@"json"];
    NSString* creationFilepath = [genDirPath stringByAppendingPathComponent:filename];
    NSString* finalFilepath =[[QuantcastUtils quantcastDataReadyToUploadDirectoryPath] stringByAppendingPathComponent:filename];
    
    // first check if file exists
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:creationFilepath]) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Upload file '%@' already exists at path '%@'. Deleting ...", filename, creationFilepath );
        }
        
        [fileManager removeItemAtPath:creationFilepath error:nil];
    }
    if ([fileManager fileExistsAtPath:finalFilepath]) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Upload file '%@' already exists at path '%@'. Deleting ...", filename, finalFilepath );
        }
        
        [fileManager removeItemAtPath:finalFilepath error:nil];
    }
    
    // generate JSON string
    
    NSString* eventJSONStr = [self genJSONStringWithDeletingDatabase:YES];
    
    NSString* fileJSONStr = [NSString stringWithFormat:@"{\"uplid\":\"%@\",\"qcv\":\"%@\",\"events\":%@}",inUploadID,QCMEASUREMENT_API_IDENTIFIER,eventJSONStr];
    
    NSData* fileJSONData = [fileJSONStr dataUsingEncoding:NSUTF8StringEncoding];
    
    if ( ![fileManager createFileAtPath:creationFilepath contents:fileJSONData attributes:nil] ) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Could not create JSON file at path '%@' with contents = %@", creationFilepath, fileJSONStr );
        }
        
        return nil;
    }
    
    // file has been created. Now move it to it's ready loacation.
    
    NSError* error;
    
    if ( ![fileManager moveItemAtPath:creationFilepath toPath:finalFilepath error:&error] ) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Could note move file '%@' to location '%@'. Error = %@", creationFilepath, finalFilepath, [error localizedDescription] );
        }
        
        return nil;
    }
    
    return finalFilepath;
}


#pragma mark - JSON conversion

-(NSString*)genJSONStringWithDeletingDatabase:(BOOL)inDoDeleteDB {
    if (nil == self.db) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: could not dump events to JSON because there is no database connection");
        }
        return @"[]";
    }
    NSString* jsonStr= @"[";
    
    NSArray* eventList = [self recordedEventsWithDeleteDBEvents:inDoDeleteDB];
    
    NSUInteger itemCount = 1;
    
    for ( QuantcastEvent* e in eventList ) {
        
        jsonStr = [jsonStr stringByAppendingString:[e JSONStringEnforcingPolicy:self.policy]];
        
        if ( itemCount < [eventList count] ){
            jsonStr = [jsonStr stringByAppendingString:@","];
        }
        itemCount++;
    }
    
    jsonStr = [jsonStr stringByAppendingString:@"]"];
    
    return jsonStr;
}

#pragma mark - Opt-Out Handleing
@synthesize isOptOut=_isOptOut;


-(void)setIsOptOut:(BOOL)inIsOptOut {
    BOOL originalValue = _isOptOut;
    
    _isOptOut = inIsOptOut;
    
    if ( originalValue != inIsOptOut ) {
        if ( inIsOptOut ) {
            // cancel all pending operations            
            [self.opQueue cancelAllOperations];
            
            // stop all uploading
            [_uploadManager release];
            _uploadManager = nil;

            // make sure database connection is closed
            [self.db closeDatabaseConnection];
            [_db release];
            _db = nil;
            
            // get rid of all Quantcast data on device
            [QuantcastUtils emptyAllQuantcastCaches];
        }
        else {
            [self setUpEventDatabaseConnection];
        }
    }
}

@end
