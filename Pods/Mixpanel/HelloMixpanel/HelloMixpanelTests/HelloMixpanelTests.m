//
//  HelloMixpanelTests.m
//  HelloMixpanelTests
//
// Copyright 2012 Mixpanel
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "HelloMixpanelTests.h"

#import "Mixpanel.h"
#import "MPSurvey.h"
#import "MPSurveyQuestion.h"
#import "HTTPServer.h"
#import "MixpanelDummyHTTPConnection.h"

#define TEST_TOKEN @"abc123"

@interface Mixpanel (Test)

// get access to private members
@property(nonatomic,retain) NSMutableArray *eventsQueue;
@property(nonatomic,retain) NSMutableArray *peopleQueue;
@property(nonatomic,retain) NSTimer *timer;
@property(nonatomic,assign) dispatch_queue_t serialQueue;

- (NSData *)JSONSerializeObject:(id)obj;
- (NSString *)defaultDistinctId;
- (void)archive;
- (NSString *)eventsFilePath;
- (NSString *)peopleFilePath;
- (NSString *)propertiesFilePath;

@end

@interface MixpanelPeople (Test)

// get access to private members
@property(nonatomic,retain) NSMutableArray *unidentifiedQueue;
@property(nonatomic,copy) NSMutableArray *distinctId;

@end

@interface HelloMixpanelTests ()  <MixpanelDelegate>

@property(nonatomic,retain) Mixpanel *mixpanel;
@property(nonatomic,retain) HTTPServer *httpServer;
@property(atomic) BOOL mixpanelWillFlush;

@end

@implementation HelloMixpanelTests

- (void)setUp
{
    NSLog(@"starting test setup...");
    [super setUp];
    self.mixpanel = [[[Mixpanel alloc] initWithToken:TEST_TOKEN andFlushInterval:0] autorelease];
    [self.mixpanel reset];
    self.mixpanelWillFlush = NO;
    [self waitForSerialQueue];

    NSLog(@"finished test setup");
}

- (void)tearDown
{
    [super tearDown];
    self.mixpanel = nil;
}

- (void) setupHTTPServer
{
    if (!self.httpServer) {
        self.httpServer = [[HTTPServer alloc] init];
        [self.httpServer setConnectionClass:[MixpanelDummyHTTPConnection class]];
        [self.httpServer setType:@"_http._tcp."];
        [self.httpServer setPort:31337];

        NSString *webPath = [[NSBundle mainBundle] resourcePath];
        [self.httpServer setDocumentRoot:webPath];

        NSError *error;
        if([self.httpServer start:&error])
        {
            NSLog(@"Started HTTP Server on port %hu", [self.httpServer listeningPort]);
        }
        else
        {
            NSLog(@"Error starting HTTP Server: %@", error);
        }
    }
}

- (void)waitForSerialQueue
{
    NSLog(@"starting wait for serial queue...");
    dispatch_sync(self.mixpanel.serialQueue, ^{ return; });
    NSLog(@"finished wait for serial queue");
}

- (BOOL)mixpanelWillFlush:(Mixpanel *)mixpanel
{
    return self.mixpanelWillFlush;
}

- (NSDictionary *)allPropertyTypes
{
    NSNumber *number = [NSNumber numberWithInt:3];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    NSDate *date = [dateFormatter dateFromString:@"2012-09-28 19:14:36 PDT"];
    [dateFormatter release];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:@"v" forKey:@"k"];
    NSArray *array = [NSArray arrayWithObject:@"1"];
    NSNull *null = [NSNull null];
    NSDictionary *nested = [NSDictionary dictionaryWithObject:
                            [NSDictionary dictionaryWithObject:
                             [NSArray arrayWithObject:
                              [NSDictionary dictionaryWithObject:
                               [NSArray arrayWithObject:@"bottom"]
                                                          forKey:@"p3"]]
                                                        forKey:@"p2"]
                                                       forKey:@"p1"];
    NSURL *url = [NSURL URLWithString:@"https://mixpanel.com/"];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"yello",   @"string",
            number,     @"number",
            date,       @"date",
            dictionary, @"dictionary",
            array,      @"array",
            null,       @"null",
            nested,     @"nested",
            url,        @"url",
            @1.3,       @"float",
            nil];
}

- (void)assertDefaultPeopleProperties:(NSDictionary *)p
{
    STAssertNotNil([p objectForKey:@"$ios_device_model"], @"missing $ios_device_model property");
    STAssertNotNil([p objectForKey:@"$ios_version"], @"missing $ios_version property");
    STAssertNotNil([p objectForKey:@"$ios_app_version"], @"missing $ios_app_version property");
    STAssertNotNil([p objectForKey:@"$ios_app_release"], @"missing $ios_app_release property");
    STAssertNotNil([p objectForKey:@"$ios_ifa"], @"missing $ios_ifa property");
}

- (void)testHTTPServer {
    [self setupHTTPServer];
    int requestCount = [MixpanelDummyHTTPConnection getRequestCount];

    NSString *post = @"Test Data";
    NSURL *url = [NSURL URLWithString:[@"http://localhost:31337" stringByAppendingString:@"/engage/"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil;
    NSURLResponse *urlResponse = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    NSString *response = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];

    STAssertTrue([response length] > 0, @"HTTP server response not valid");
    STAssertEquals([MixpanelDummyHTTPConnection getRequestCount] - requestCount, 1, @"One server request should have been made");
}

- (void)testFlushEvents
{
    [self setupHTTPServer];
    self.mixpanel.serverURL = @"http://localhost:31337";
    self.mixpanel.delegate = self;
    self.mixpanelWillFlush = YES;
    int requestCount = [MixpanelDummyHTTPConnection getRequestCount];

    [self.mixpanel identify:@"d1"];
    for(uint i=0, n=50; i<n; i++) {
        [self.mixpanel track:[NSString stringWithFormat:@"event %d", i]];
    }
    [self.mixpanel flush];
    [self waitForSerialQueue];

    STAssertTrue(self.mixpanel.eventsQueue.count == 0, @"events should have been flushed");
    STAssertEquals([MixpanelDummyHTTPConnection getRequestCount] - requestCount, 1, @"50 events should have been batched in 1 HTTP request");

    requestCount = [MixpanelDummyHTTPConnection getRequestCount];
    for(uint i=0, n=60; i<n; i++) {
        [self.mixpanel track:[NSString stringWithFormat:@"event %d", i]];
    }
    [self.mixpanel flush];
    [self waitForSerialQueue];

    STAssertTrue(self.mixpanel.eventsQueue.count == 0, @"events should have been flushed");
    STAssertEquals([MixpanelDummyHTTPConnection getRequestCount] - requestCount, 2, @"60 events should have been batched in 2 HTTP requests");
}

- (void)testFlushPeople
{
    [self setupHTTPServer];
    self.mixpanel.serverURL = @"http://localhost:31337";
    self.mixpanel.delegate = self;
    self.mixpanelWillFlush = YES;
    int requestCount = [MixpanelDummyHTTPConnection getRequestCount];

    [self.mixpanel identify:@"d1"];
    for(uint i=0, n=50; i<n; i++) {
        [self.mixpanel.people set:@"p1" to:[NSString stringWithFormat:@"%d", i]];
    }
    [self.mixpanel flush];
    [self waitForSerialQueue];

    STAssertTrue([self.mixpanel.eventsQueue count] == 0, @"people should have been flushed");
    STAssertEquals(requestCount + 1, [MixpanelDummyHTTPConnection getRequestCount], @"50 people properties should have been batched in 1 HTTP request");

    requestCount = [MixpanelDummyHTTPConnection getRequestCount];
    for(uint i=0, n=60; i<n; i++) {
        [self.mixpanel.people set:@"p1" to:[NSString stringWithFormat:@"%d", i]];
    }
    [self.mixpanel flush];
    [self waitForSerialQueue];

    STAssertTrue([self.mixpanel.eventsQueue count] == 0, @"people should have been flushed");
    STAssertEquals([MixpanelDummyHTTPConnection getRequestCount] - requestCount, 2, @"60 people properties should have been batched in 2 HTTP requests");
}

- (void)testFlushFailure
{
    [self setupHTTPServer];
    self.mixpanel.serverURL = @"http://0.0.0.0";
    self.mixpanel.delegate = self;
    self.mixpanelWillFlush = YES;
    int requestCount = [MixpanelDummyHTTPConnection getRequestCount];

    [self.mixpanel identify:@"d1"];
    for(uint i=0, n=50; i<n; i++) {
        [self.mixpanel track:[NSString stringWithFormat:@"event %d", i]];
    }
    [self waitForSerialQueue];
    STAssertTrue([self.mixpanel.eventsQueue count] == 50U, @"50 events should be queued up");
    [self.mixpanel flush];
    [self waitForSerialQueue];

    STAssertTrue([self.mixpanel.eventsQueue count] == 50U, @"events should still be in the queue if flush fails");
    STAssertEquals([MixpanelDummyHTTPConnection getRequestCount] - requestCount, 0, @"The request should have failed.");
}

- (void)testAddingEventsAfterFlush
{
    [self setupHTTPServer];
    self.mixpanel.serverURL = @"http://localhost:31337";
    self.mixpanel.delegate = self;
    self.mixpanelWillFlush = YES;
    int requestCount = [MixpanelDummyHTTPConnection getRequestCount];

    [self.mixpanel identify:@"d1"];
    for(uint i=0, n=10; i<n; i++) {
        [self.mixpanel track:[NSString stringWithFormat:@"event %d", i]];
    }
    [self waitForSerialQueue];
    STAssertTrue([self.mixpanel.eventsQueue count] == 10U, @"10 events should be queued up");
    [self.mixpanel flush];
    for(uint i=0, n=5; i<n; i++) {
        [self.mixpanel track:[NSString stringWithFormat:@"event %d", i]];
    }
    [self waitForSerialQueue];
    STAssertTrue([self.mixpanel.eventsQueue count] == 5U, @"5 more events should be queued up");
    [self.mixpanel flush];
    [self waitForSerialQueue];

    STAssertTrue([self.mixpanel.eventsQueue count] == 0, @"events should have been flushed");
    STAssertEquals([MixpanelDummyHTTPConnection getRequestCount] - requestCount, 2, @"There should be 2 HTTP requests");
}


- (void)testJSONSerializeObject {
    NSDictionary *test = [self allPropertyTypes];
    NSData *data = [self.mixpanel JSONSerializeObject:[NSArray arrayWithObject:test]];
    NSString *json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    STAssertEqualObjects(json, @"[{\"float\":1.3,\"string\":\"yello\",\"url\":\"https:\\/\\/mixpanel.com\\/\",\"nested\":{\"p1\":{\"p2\":[{\"p3\":[\"bottom\"]}]}},\"array\":[\"1\"],\"date\":\"2012-09-29T02:14:36.000Z\",\"dictionary\":{\"k\":\"v\"},\"null\":null,\"number\":3}]", nil);
    test = [NSDictionary dictionaryWithObject:@"non-string key" forKey:@3];
    data = [self.mixpanel JSONSerializeObject:[NSArray arrayWithObject:test]];
    json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    STAssertEqualObjects(json, @"[{\"3\":\"non-string key\"}]", @"json serialization failed");
}

- (void)testIdentify
{
    NSLog(@"starting testIdentify...");
    for (int i = 0; i < 2; i++) { // run this twice to test reset works correctly wrt to distinct ids
        NSString *distinctId = @"d1";
        // try this for IFA, ODIN and nil
        STAssertEqualObjects(self.mixpanel.distinctId, self.mixpanel.defaultDistinctId, @"mixpanel identify failed to set default distinct id");
        STAssertNil(self.mixpanel.people.distinctId, @"mixpanel people distinct id should default to nil");
        [self.mixpanel track:@"e1"];
        [self waitForSerialQueue];
        STAssertTrue(self.mixpanel.eventsQueue.count == 1, @"events should be sent right away with default distinct id");
        STAssertEqualObjects(self.mixpanel.eventsQueue.lastObject[@"properties"][@"distinct_id"], self.mixpanel.defaultDistinctId, @"events should use default distinct id if none set");
        [self.mixpanel.people set:@"p1" to:@"a"];
        [self waitForSerialQueue];
        STAssertTrue(self.mixpanel.peopleQueue.count == 0, @"people records should go to unidentified queue before identify:");
        STAssertTrue(self.mixpanel.people.unidentifiedQueue.count == 1, @"unidentified people records not queued");
        STAssertEqualObjects(self.mixpanel.people.unidentifiedQueue.lastObject[@"$token"], TEST_TOKEN, @"incorrect project token in people record");
        [self.mixpanel identify:distinctId];
        [self waitForSerialQueue];
        STAssertEqualObjects(self.mixpanel.distinctId, distinctId, @"mixpanel identify failed to set distinct id");
        STAssertEqualObjects(self.mixpanel.people.distinctId, distinctId, @"mixpanel identify failed to set people distinct id");
        STAssertTrue(self.mixpanel.people.unidentifiedQueue.count == 0, @"identify: should move records from unidentified queue");
        STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"identify: should move records to main people queue");
        STAssertEqualObjects(self.mixpanel.peopleQueue.lastObject[@"$token"], TEST_TOKEN, @"incorrect project token in people record");
        STAssertEqualObjects(self.mixpanel.peopleQueue.lastObject[@"$distinct_id"], distinctId, @"distinct id not set properly on unidentified people record");
        NSDictionary *p = self.mixpanel.peopleQueue.lastObject[@"$set"];
        STAssertEqualObjects([p objectForKey:@"p1"], @"a", @"custom people property not queued");
        [self assertDefaultPeopleProperties:p];
        [self.mixpanel.people set:@"p1" to:@"a"];
        [self waitForSerialQueue];
        STAssertTrue(self.mixpanel.people.unidentifiedQueue.count == 0, @"once idenitfy: is called, unidentified queue should be skipped");
        STAssertTrue(self.mixpanel.peopleQueue.count == 2, @"once identify: is called, records should go straight to main queue");
        [self.mixpanel track:@"e2"];
        [self waitForSerialQueue];
        STAssertEquals(self.mixpanel.eventsQueue.lastObject[@"properties"][@"distinct_id"], distinctId, @"events should use new distinct id after identify:");
        [self.mixpanel reset];
        [self waitForSerialQueue];
    }
    NSLog(@"finished testIdentify");
}

- (void)testTrack
{
    NSLog(@"starting testTrack...");
    [self.mixpanel track:@"Something Happened"];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.eventsQueue.count == 1, @"event not queued");
    NSDictionary *e = self.mixpanel.eventsQueue.lastObject;
    STAssertEquals([e objectForKey:@"event"], @"Something Happened", @"incorrect event name");
    NSDictionary *p = [e objectForKey:@"properties"];
    STAssertTrue(p.count == 17, @"incorrect number of properties");
    STAssertNotNil([p objectForKey:@"$app_version"], @"$app_version not set");
    STAssertNotNil([p objectForKey:@"$app_release"], @"$app_release not set");
    STAssertNotNil([p objectForKey:@"$lib_version"], @"$lib_version not set");
    STAssertEqualObjects([p objectForKey:@"$manufacturer"], @"Apple", @"incorrect $manufacturer");
    STAssertNotNil([p objectForKey:@"$model"], @"$model not set");
    STAssertNotNil([p objectForKey:@"$os"], @"$os not set");
    STAssertNotNil([p objectForKey:@"$os_version"], @"$os_version not set");
    STAssertNotNil([p objectForKey:@"$screen_height"], @"$screen_height not set");
    STAssertNotNil([p objectForKey:@"$screen_width"], @"$screen_width not set");
    STAssertNotNil([p objectForKey:@"distinct_id"], @"distinct_id not set");
    STAssertNotNil([p objectForKey:@"mp_device_model"], @"mp_device_model not set");
    STAssertEqualObjects([p objectForKey:@"mp_lib"], @"iphone", @"incorrect mp_lib");
    STAssertNotNil([p objectForKey:@"time"], @"time not set");
    STAssertNotNil([p objectForKey:@"$ios_ifa"], @"$ios_ifa not set");
    STAssertEqualObjects([p objectForKey:@"token"], TEST_TOKEN, @"incorrect token");
    NSLog(@"finished testTrack");
}

- (void)testTrackProperties
{
    NSDictionary *p = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"yello",                   @"string",
                       [NSNumber numberWithInt:3], @"number",
                       [NSDate date],              @"date",
                       @"override",                @"$app_version",
                       nil];
    [self.mixpanel track:@"Something Happened" properties:p];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.eventsQueue.count == 1, @"event not queued");
    NSDictionary *e = self.mixpanel.eventsQueue.lastObject;
    STAssertEquals([e objectForKey:@"event"], @"Something Happened", @"incorrect event name");
    p = [e objectForKey:@"properties"];
    STAssertTrue(p.count == 20, @"incorrect number of properties");
    STAssertEqualObjects([p objectForKey:@"$app_version"], @"override", @"reserved property override failed");
}

- (void)testTrackWithCustomDistinctIdAndToken
{
    NSDictionary *p = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"t1",                      @"token",
                       @"d1",                      @"distinct_id",
                       nil];
    [self.mixpanel track:@"e1" properties:p];
    [self waitForSerialQueue];
    NSString *trackToken = [[self.mixpanel.eventsQueue.lastObject objectForKey:@"properties"] objectForKey:@"token"];
    NSString *trackDistinctId = [[self.mixpanel.eventsQueue.lastObject objectForKey:@"properties"] objectForKey:@"distinct_id"];
    STAssertEqualObjects(trackToken, @"t1", @"user-defined distinct id not used in track. got: %@", trackToken);
    STAssertEqualObjects(trackDistinctId, @"d1", @"user-defined distinct id not used in track. got: %@", trackDistinctId);
}

- (void)testSuperProperties
{
    NSDictionary *p = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"a",                       @"p1",
                       [NSNumber numberWithInt:3], @"p2",
                       [NSDate date],              @"p2",
                       nil];
    [self.mixpanel registerSuperProperties:p];
    [self waitForSerialQueue];
    STAssertEqualObjects([self.mixpanel currentSuperProperties], p, @"register super properties failed");
    p = [NSDictionary dictionaryWithObject:@"b" forKey:@"p1"];
    [self.mixpanel registerSuperProperties:p];
    [self waitForSerialQueue];
    STAssertEqualObjects([[self.mixpanel currentSuperProperties] objectForKey:@"p1"], @"b",
                         @"register super properties failed to overwrite existing value");
    p = [NSDictionary dictionaryWithObject:@"a" forKey:@"p4"];
    [self.mixpanel registerSuperPropertiesOnce:p];
    [self waitForSerialQueue];
    STAssertEqualObjects([[self.mixpanel currentSuperProperties] objectForKey:@"p4"], @"a",
                         @"register super properties once failed first time");
    p = [NSDictionary dictionaryWithObject:@"b" forKey:@"p4"];
    [self.mixpanel registerSuperPropertiesOnce:p];
    [self waitForSerialQueue];
    STAssertEqualObjects([[self.mixpanel currentSuperProperties] objectForKey:@"p4"], @"a",
                         @"register super properties once failed second time");
    p = [NSDictionary dictionaryWithObject:@"c" forKey:@"p4"];
    [self.mixpanel registerSuperPropertiesOnce:p defaultValue:@"d"];
    [self waitForSerialQueue];
    STAssertEqualObjects([[self.mixpanel currentSuperProperties] objectForKey:@"p4"], @"a",
                         @"register super properties once with default value failed when no match");
    [self.mixpanel registerSuperPropertiesOnce:p defaultValue:@"a"];
    [self waitForSerialQueue];
    STAssertEqualObjects([[self.mixpanel currentSuperProperties] objectForKey:@"p4"], @"c",
                         @"register super properties once with default value failed when match");
    [self.mixpanel unregisterSuperProperty:@"a"];
    [self waitForSerialQueue];
    STAssertNil([[self.mixpanel currentSuperProperties] objectForKey:@"a"],
                         @"unregister super property failed");
    STAssertNoThrow([self.mixpanel unregisterSuperProperty:@"a"], @"unregister non-existent super property should not throw");
    [self.mixpanel clearSuperProperties];
    [self waitForSerialQueue];
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 0, @"clear super properties failed");
}

- (void)testAssertPropertyTypes
{
    NSDictionary *p = [NSDictionary dictionaryWithObject:[NSData data] forKey:@"data"];
    STAssertThrows([self.mixpanel track:@"e1" properties:p], @"property type should not be allowed");
    STAssertThrows([self.mixpanel registerSuperProperties:p], @"property type should not be allowed");
    STAssertThrows([self.mixpanel registerSuperPropertiesOnce:p], @"property type should not be allowed");
    STAssertThrows([self.mixpanel registerSuperPropertiesOnce:p defaultValue:@"v"], @"property type should not be allowed");
    p = [self allPropertyTypes];
    STAssertNoThrow([self.mixpanel track:@"e1" properties:p], @"property type should be allowed");
    STAssertNoThrow([self.mixpanel registerSuperProperties:p], @"property type should be allowed");
    STAssertNoThrow([self.mixpanel registerSuperPropertiesOnce:p],  @"property type should be allowed");
    STAssertNoThrow([self.mixpanel registerSuperPropertiesOnce:p defaultValue:@"v"],  @"property type should be allowed");
}

- (void)testReset
{
    NSDictionary *p = [NSDictionary dictionaryWithObject:@"a" forKey:@"p1"];
    [self.mixpanel identify:@"d1"];
    self.mixpanel.nameTag = @"n1";
    [self.mixpanel registerSuperProperties:p];
    [self.mixpanel track:@"e1"];
    [self.mixpanel.people set:p];
    [self.mixpanel archive];
    [self.mixpanel reset];
    [self waitForSerialQueue];
    STAssertEqualObjects(self.mixpanel.distinctId, [self.mixpanel defaultDistinctId], @"distinct id failed to reset");
    STAssertNil(self.mixpanel.nameTag, @"name tag failed to reset");
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 0, @"super properties failed to reset");
    STAssertTrue(self.mixpanel.eventsQueue.count == 0, @"events queue failed to reset");
    STAssertNil(self.mixpanel.people.distinctId, @"people distinct id failed to reset");
    STAssertTrue(self.mixpanel.peopleQueue.count == 0, @"people queue failed to reset");
    self.mixpanel = [[[Mixpanel alloc] initWithToken:TEST_TOKEN andFlushInterval:0] autorelease];
    STAssertEqualObjects(self.mixpanel.distinctId, [self.mixpanel defaultDistinctId], @"distinct id failed to reset after archive");
    STAssertNil(self.mixpanel.nameTag, @"name tag failed to reset after archive");
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 0, @"super properties failed to reset after archive");
    STAssertTrue(self.mixpanel.eventsQueue.count == 0, @"events queue failed to reset after archive");
    STAssertNil(self.mixpanel.people.distinctId, @"people distinct id failed to reset after archive");
    STAssertTrue(self.mixpanel.peopleQueue.count == 0, @"people queue failed to reset after archive");
}

- (void)testArchive
{
    [self.mixpanel archive];
    self.mixpanel = [[[Mixpanel alloc] initWithToken:TEST_TOKEN andFlushInterval:0] autorelease];
    STAssertEqualObjects(self.mixpanel.distinctId, [self.mixpanel defaultDistinctId], @"default distinct id archive failed");
    STAssertNil(self.mixpanel.nameTag, @"default name tag archive failed");
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 0, @"default super properties archive failed");
    STAssertTrue(self.mixpanel.eventsQueue.count == 0, @"default events queue archive failed");
    STAssertNil(self.mixpanel.people.distinctId, @"default people distinct id archive failed");
    STAssertTrue(self.mixpanel.peopleQueue.count == 0, @"default people queue archive failed");
    NSDictionary *p = [NSDictionary dictionaryWithObject:@"a" forKey:@"p1"];
    [self.mixpanel identify:@"d1"];
    self.mixpanel.nameTag = @"n1";
    [self.mixpanel registerSuperProperties:p];
    [self.mixpanel track:@"e1"];
    [self.mixpanel.people set:p];
    [self waitForSerialQueue];
    [self.mixpanel archive];
    self.mixpanel = [[[Mixpanel alloc] initWithToken:TEST_TOKEN andFlushInterval:0] autorelease];
    STAssertEqualObjects(self.mixpanel.distinctId, @"d1", @"custom distinct archive failed");
    STAssertEqualObjects(self.mixpanel.nameTag, @"n1", @"custom name tag archive failed");
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 1, @"custom super properties archive failed");
    STAssertTrue(self.mixpanel.eventsQueue.count == 1, @"pending events queue archive failed");
    STAssertEqualObjects(self.mixpanel.people.distinctId, @"d1", @"custom people distinct id archive failed");
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"pending people queue archive failed");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    STAssertTrue([fileManager fileExistsAtPath:[self.mixpanel eventsFilePath]], @"events archive file not found");
    STAssertTrue([fileManager fileExistsAtPath:[self.mixpanel peopleFilePath]], @"people archive file not found");
    STAssertTrue([fileManager fileExistsAtPath:[self.mixpanel propertiesFilePath]], @"properties archive file not found");
    // no existing file
    [fileManager removeItemAtPath:[self.mixpanel eventsFilePath] error:NULL];
    [fileManager removeItemAtPath:[self.mixpanel peopleFilePath] error:NULL];
    [fileManager removeItemAtPath:[self.mixpanel propertiesFilePath] error:NULL];
    STAssertFalse([fileManager fileExistsAtPath:[self.mixpanel eventsFilePath]], @"events archive file not removed");
    STAssertFalse([fileManager fileExistsAtPath:[self.mixpanel peopleFilePath]], @"people archive file not removed");
    STAssertFalse([fileManager fileExistsAtPath:[self.mixpanel propertiesFilePath]], @"properties archive file not removed");
    self.mixpanel = [[[Mixpanel alloc] initWithToken:TEST_TOKEN andFlushInterval:0] autorelease];
    STAssertEqualObjects(self.mixpanel.distinctId, [self.mixpanel defaultDistinctId], @"default distinct id from no file failed");
    STAssertNil(self.mixpanel.nameTag, @"default name tag archive from no file failed");
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 0, @"default super properties from no file failed");
    STAssertNotNil(self.mixpanel.eventsQueue, @"default events queue from no file is nil");
    STAssertTrue(self.mixpanel.eventsQueue.count == 0, @"default events queue from no file not empty");
    STAssertNil(self.mixpanel.people.distinctId, @"default people distinct id from no file failed");
    STAssertNotNil(self.mixpanel.peopleQueue, @"default people queue from no file is nil");
    STAssertTrue(self.mixpanel.peopleQueue.count == 0, @"default people queue from no file not empty");
    // corrupt file
    NSData *garbage = [@"garbage" dataUsingEncoding:NSUTF8StringEncoding];
    [garbage writeToFile:[self.mixpanel eventsFilePath] atomically:NO];
    [garbage writeToFile:[self.mixpanel peopleFilePath] atomically:NO];
    [garbage writeToFile:[self.mixpanel propertiesFilePath] atomically:NO];
    STAssertTrue([fileManager fileExistsAtPath:[self.mixpanel eventsFilePath]], @"garbage events archive file not found");
    STAssertTrue([fileManager fileExistsAtPath:[self.mixpanel peopleFilePath]], @"garbage people archive file not found");
    STAssertTrue([fileManager fileExistsAtPath:[self.mixpanel propertiesFilePath]], @"garbage properties archive file not found");
    self.mixpanel = [[[Mixpanel alloc] initWithToken:TEST_TOKEN andFlushInterval:0] autorelease];
    STAssertEqualObjects(self.mixpanel.distinctId, [self.mixpanel defaultDistinctId], @"default distinct id from garbage failed");
    STAssertNil(self.mixpanel.nameTag, @"default name tag archive from garbage failed");
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 0, @"default super properties from garbage failed");
    STAssertNotNil(self.mixpanel.eventsQueue, @"default events queue from garbage is nil");
    STAssertTrue(self.mixpanel.eventsQueue.count == 0, @"default events queue from garbage not empty");
    STAssertNil(self.mixpanel.people.distinctId, @"default people distinct id from garbage failed");
    STAssertNotNil(self.mixpanel.peopleQueue, @"default people queue from garbage is nil");
    STAssertTrue(self.mixpanel.peopleQueue.count == 0, @"default people queue from garbage not empty");
}

- (void)testPeopleAddPushDeviceToken
{
    [self.mixpanel identify:@"d1"];
    NSData *token = [@"0123456789abcdef" dataUsingEncoding:[NSString defaultCStringEncoding]];
    [self.mixpanel.people addPushDeviceToken:token];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"people records not queued");
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects([r objectForKey:@"$token"], TEST_TOKEN, @"project token not set");
    STAssertEqualObjects([r objectForKey:@"$distinct_id"], @"d1", @"distinct id not set");
    STAssertNotNil([r objectForKey:@"$union"], @"$union dictionary missing");
    NSDictionary *p = [r objectForKey:@"$union"];
    STAssertTrue(p.count == 1, @"incorrect people properties: %@", p);
    NSArray *a = [p objectForKey:@"$ios_devices"];
    STAssertTrue(a.count == 1, @"device token array not set");
    STAssertEqualObjects(a.lastObject, @"30313233343536373839616263646566", @"device token not encoded properly");
}

- (void)testPeopleSet
{
    [self.mixpanel identify:@"d1"];
    [self waitForSerialQueue];
    NSDictionary *p = [NSDictionary dictionaryWithObject:@"a" forKey:@"p1"];
    [self.mixpanel.people set:p];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"people records not queued");
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects([r objectForKey:@"$token"], TEST_TOKEN, @"project token not set");
    STAssertEqualObjects([r objectForKey:@"$distinct_id"], @"d1", @"distinct id not set");
    STAssertNotNil([r objectForKey:@"$time"], @"$time timestamp missing");
    STAssertNotNil([r objectForKey:@"$set"], @"$set dictionary missing");
    p = [r objectForKey:@"$set"];
    STAssertEqualObjects([p objectForKey:@"p1"], @"a", @"custom people property not queued");
    [self assertDefaultPeopleProperties:p];
}

- (void)testPeopleSetOnce
{
    [self.mixpanel identify:@"d1"];
    NSDictionary *p = [NSDictionary dictionaryWithObject:@"a" forKey:@"p1"];
    [self.mixpanel.people setOnce:p];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"people records not queued");
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects([r objectForKey:@"$token"], TEST_TOKEN, @"project token not set");
    STAssertEqualObjects([r objectForKey:@"$distinct_id"], @"d1", @"distinct id not set");
    STAssertNotNil([r objectForKey:@"$time"], @"$time timestamp missing");
    STAssertNotNil([r objectForKey:@"$set_once"], @"$set dictionary missing");
    p = [r objectForKey:@"$set_once"];
    STAssertEqualObjects([p objectForKey:@"p1"], @"a", @"custom people property not queued");
    [self assertDefaultPeopleProperties:p];
}

- (void)testPeopleSetReservedProperty
{
    [self.mixpanel identify:@"d1"];
    NSDictionary *p = [NSDictionary dictionaryWithObject:@"override" forKey:@"$ios_app_version"];
    [self.mixpanel.people set:p];
    [self waitForSerialQueue];
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    p = [r objectForKey:@"$set"];
    STAssertEqualObjects([p objectForKey:@"$ios_app_version"], @"override", @"reserved property override failed");
}

- (void)testPeopleSetTo
{
    [self.mixpanel identify:@"d1"];
    [self.mixpanel.people set:@"p1" to:@"a"];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"people records not queued");
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects([r objectForKey:@"$token"], TEST_TOKEN, @"project token not set");
    STAssertEqualObjects([r objectForKey:@"$distinct_id"], @"d1", @"distinct id not set");
    STAssertNotNil([r objectForKey:@"$set"], @"$set dictionary missing");
    NSDictionary *p = [r objectForKey:@"$set"];
    STAssertEqualObjects([p objectForKey:@"p1"], @"a", @"custom people property not queued");
    [self assertDefaultPeopleProperties:p];
}

- (void)testPeopleIncrement
{
    [self.mixpanel identify:@"d1"];
    NSDictionary *p = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:3] forKey:@"p1"];
    [self.mixpanel.people increment:p];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"people records not queued");
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects([r objectForKey:@"$token"], TEST_TOKEN, @"project token not set");
    STAssertEqualObjects([r objectForKey:@"$distinct_id"], @"d1", @"distinct id not set");
    STAssertNotNil([r objectForKey:@"$add"], @"$add dictionary missing");
    p = [r objectForKey:@"$add"];
    STAssertTrue(p.count == 1, @"incorrect people properties: %@", p);
    STAssertEqualObjects([p objectForKey:@"p1"], [NSNumber numberWithInt:3], @"custom people property not queued");
}

- (void)testPeopleIncrementBy
{
    [self.mixpanel identify:@"d1"];
    [self.mixpanel.people increment:@"p1" by:[NSNumber numberWithInt:3]];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"people records not queued");
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects([r objectForKey:@"$token"], TEST_TOKEN, @"project token not set");
    STAssertEqualObjects([r objectForKey:@"$distinct_id"], @"d1", @"distinct id not set");
    STAssertNotNil([r objectForKey:@"$add"], @"$add dictionary missing");
    NSDictionary *p = [r objectForKey:@"$add"];
    STAssertTrue(p.count == 1, @"incorrect people properties: %@", p);
    STAssertEqualObjects([p objectForKey:@"p1"], [NSNumber numberWithInt:3], @"custom people property not queued");
}

- (void)testPeopleDeleteUser
{
    [self.mixpanel identify:@"d1"];
    [self.mixpanel.people deleteUser];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"people records not queued");
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects([r objectForKey:@"$token"], TEST_TOKEN, @"project token not set");
    STAssertEqualObjects([r objectForKey:@"$distinct_id"], @"d1", @"distinct id not set");
    STAssertNotNil([r objectForKey:@"$delete"], @"$delete dictionary missing");
    NSDictionary *p = [r objectForKey:@"$delete"];
    STAssertTrue(p.count == 0, @"incorrect people properties: %@", p);
}

- (void)testMixpanelDelegate
{
    self.mixpanel.delegate = self;
    [self.mixpanel identify:@"d1"];
    [self.mixpanel track:@"e1"];
    [self.mixpanel.people set:@"p1" to:@"a"];
    [self.mixpanel flush];
    [self waitForSerialQueue];
    STAssertTrue(self.mixpanel.eventsQueue.count == 1, @"delegate should have stopped flush");
    STAssertTrue(self.mixpanel.peopleQueue.count == 1, @"delegate should have stopped flush");
}

- (void)testPeopleAssertPropertyTypes
{
    NSURL *d = [NSData data];
    NSDictionary *p = [NSDictionary dictionaryWithObject:d forKey:@"URL"];
    STAssertThrows([self.mixpanel.people set:p], @"unsupported property allowed");
    STAssertThrows([self.mixpanel.people set:@"p1" to:d], @"unsupported property allowed");
    p = [NSDictionary dictionaryWithObject:@"a" forKey:@"p1"]; // increment should require a number
    STAssertThrows([self.mixpanel.people increment:p], @"unsupported property allowed");
}

- (void)testNilArguments
{
    [self.mixpanel identify:nil];
    STAssertNil(self.mixpanel.people.distinctId, @"identify nil should make distinct id nil");
    [self.mixpanel track:nil];
    [self.mixpanel track:nil properties:nil];
    [self.mixpanel registerSuperProperties:nil];
    [self.mixpanel registerSuperPropertiesOnce:nil];
    [self.mixpanel registerSuperPropertiesOnce:nil defaultValue:nil];
    [self waitForSerialQueue];
    // legacy behavior
    STAssertTrue(self.mixpanel.eventsQueue.count == 2, @"track with nil should create mp_event event");
    STAssertEqualObjects([self.mixpanel.eventsQueue.lastObject objectForKey:@"event"], @"mp_event", @"track with nil should create mp_event event");
    STAssertNotNil([self.mixpanel currentSuperProperties], @"setting super properties to nil should have no effect");
    STAssertTrue([[self.mixpanel currentSuperProperties] count] == 0, @"setting super properties to nil should have no effect");
    [self.mixpanel identify:nil];
    STAssertNil(self.mixpanel.people.distinctId, @"identify nil should make people distinct id nil");
    STAssertThrows([self.mixpanel.people set:nil], @"should not take nil argument");
    STAssertThrows([self.mixpanel.people set:nil to:@"a"], @"should not take nil argument");
    STAssertThrows([self.mixpanel.people set:@"p1" to:nil], @"should not take nil argument");
    STAssertThrows([self.mixpanel.people set:nil to:nil], @"should not take nil argument");
    STAssertThrows([self.mixpanel.people increment:nil], @"should not take nil argument");
    STAssertThrows([self.mixpanel.people increment:nil by:[NSNumber numberWithInt:3]], @"should not take nil argument");
    STAssertThrows([self.mixpanel.people increment:@"p1" by:nil], @"should not take nil argument");
    STAssertThrows([self.mixpanel.people increment:nil by:nil], @"should not take nil argument");
}

- (void)testPeopleTrackCharge
{
    [self.mixpanel identify:@"d1"];
    [self.mixpanel.people trackCharge:@25];
    [self waitForSerialQueue];
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects(r[@"$append"][@"$transactions"][@"$amount"], @25, nil);
    STAssertNotNil(r[@"$append"][@"$transactions"][@"$time"], nil);
    [self.mixpanel.peopleQueue removeAllObjects];
    [self.mixpanel.people trackCharge:@25.34];
    [self waitForSerialQueue];
    r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects(r[@"$append"][@"$transactions"][@"$amount"], @25.34, nil);
    STAssertNotNil(r[@"$append"][@"$transactions"][@"$time"], nil);
    [self.mixpanel.peopleQueue removeAllObjects];
    // require a number
    STAssertThrows([self.mixpanel.people trackCharge:nil], nil);
    STAssertTrue(self.mixpanel.peopleQueue.count == 0, nil);
    // but allow 0
    [self.mixpanel.people trackCharge:@0];
    [self waitForSerialQueue];
    r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects(r[@"$append"][@"$transactions"][@"$amount"], @0, nil);
    STAssertNotNil(r[@"$append"][@"$transactions"][@"$time"], nil);
    [self.mixpanel.peopleQueue removeAllObjects];
    // allow $time override
    NSDictionary *p = [self allPropertyTypes];
    [self.mixpanel.people trackCharge:@25 withProperties:@{@"$time": p[@"date"]}];
    [self waitForSerialQueue];
    r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects(r[@"$append"][@"$transactions"][@"$amount"], @25, nil);
    STAssertEqualObjects(r[@"$append"][@"$transactions"][@"$time"], p[@"date"], nil);
    [self.mixpanel.peopleQueue removeAllObjects];
    // allow arbitrary charge properties
    [self.mixpanel.people trackCharge:@25 withProperties:@{@"p1": @"a"}];
    [self waitForSerialQueue];
    r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects(r[@"$append"][@"$transactions"][@"$amount"], @25, nil);
    STAssertEqualObjects(r[@"$append"][@"$transactions"][@"p1"], @"a", nil);
}

- (void)testPeopleClearCharges
{
    [self.mixpanel identify:@"d1"];
    [self.mixpanel.people clearCharges];
    [self waitForSerialQueue];
    NSDictionary *r = self.mixpanel.peopleQueue.lastObject;
    STAssertEqualObjects(r[@"$set"][@"$transactions"], @[], nil);
}

- (void)testDropEvents
{
    for (int i = 0; i < 505; i++) {
        [self.mixpanel track:@"rapid_event" properties:@{@"i": @(i)}];
    }
    [self waitForSerialQueue];
    STAssertTrue([self.mixpanel.eventsQueue count] == 500, nil);
    NSDictionary *e = [self.mixpanel.eventsQueue objectAtIndex:0];
    STAssertEqualObjects(e[@"properties"][@"i"], @(5), nil);
    e = [self.mixpanel.eventsQueue lastObject];
    STAssertEqualObjects(e[@"properties"][@"i"], @(504), nil);
}

- (void)testDropUnidentifiedPeopleRecords
{
    for (int i = 0; i < 505; i++) {
        [self.mixpanel.people set:@"i" to:@(i)];
    }
    [self waitForSerialQueue];
    STAssertTrue([self.mixpanel.people.unidentifiedQueue count] == 500, nil);
    NSDictionary *r = [self.mixpanel.people.unidentifiedQueue objectAtIndex:0];
    STAssertEqualObjects(r[@"$set"][@"i"], @(5), nil);
    r = [self.mixpanel.people.unidentifiedQueue lastObject];
    STAssertEqualObjects(r[@"$set"][@"i"], @(504), nil);
}

- (void)testDropPeopleRecords
{
    [self.mixpanel identify:@"d1"];
    for (int i = 0; i < 505; i++) {
        [self.mixpanel.people set:@"i" to:@(i)];
    }
    [self waitForSerialQueue];
    STAssertTrue([self.mixpanel.peopleQueue count] == 500, nil);
    NSDictionary *r = [self.mixpanel.peopleQueue objectAtIndex:0];
    STAssertEqualObjects(r[@"$set"][@"i"], @(5), nil);
    r = [self.mixpanel.peopleQueue lastObject];
    STAssertEqualObjects(r[@"$set"][@"i"], @(504), nil);
}

- (void)testParseSurvey
{
    // invalid (no name)
    NSDictionary *invalid = @{@"id": @3,
                        @"collections": @[@{@"id": @9}],
                        @"questions": @[@{
                                            @"id": @12,
                                            @"type": @"text",
                                            @"prompt": @"Anything else?",
                                            @"extra_data": @{}}]};
    STAssertNil([MPSurvey surveyWithJSONObject:invalid], nil);

    // valid
    NSDictionary *o = @{@"id": @3,
                        @"name": @"survey",
                        @"collections": @[@{@"id": @9, @"name": @"collection"}],
                        @"questions": @[@{
                                            @"id": @12,
                                            @"type": @"text",
                                            @"prompt": @"Anything else?",
                                            @"extra_data": @{}}]};
    STAssertNotNil([MPSurvey surveyWithJSONObject:o], nil);

    // nil
    STAssertNil([MPSurvey surveyWithJSONObject:nil], nil);

    // empty
    STAssertNil([MPSurvey surveyWithJSONObject:@{}], nil);

    // garbage keys
    STAssertNil([MPSurvey surveyWithJSONObject:@{@"blah": @"foo"}], nil);

    NSMutableDictionary *m;

    // invalid id
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"id"] = @NO;
    STAssertNil([MPSurvey surveyWithJSONObject:m], nil);

    // invalid collections
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"collections"] = @NO;
    STAssertNil([MPSurvey surveyWithJSONObject:m], nil);

    // empty collections
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"collections"] = @[];
    STAssertNil([MPSurvey surveyWithJSONObject:m], nil);

    // invalid collections item
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"collections"] = @[@NO];
    STAssertNil([MPSurvey surveyWithJSONObject:m], nil);

    // collections item with no id
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"collections"] = @[@{@"bo": @"knows"}];
    STAssertNil([MPSurvey surveyWithJSONObject:m], nil);

    // no questions
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"questions"] = @[];
    STAssertNil([MPSurvey surveyWithJSONObject:m], nil);

    // 1 invalid question
    NSArray *q = @[@{
                       @"id": @NO,
                       @"type": @"text",
                       @"prompt": @"Anything else?",
                       @"extra_data": @{}}];
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"questions"] = q;
    STAssertNil([MPSurvey surveyWithJSONObject:m], nil);

    // 1 invalid question, 1 good question
    q = @[@{
              @"id": @NO,
              @"type": @"text",
              @"prompt": @"Anything else?",
              @"extra_data": @{}},
          @{
              @"id": @3,
              @"type": @"text",
              @"prompt": @"Anything else?",
              @"extra_data": @{}}];
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"questions"] = q;
    MPSurvey *s = [MPSurvey surveyWithJSONObject:m];
    STAssertNotNil(s, nil);
    STAssertEquals([s.questions count], (NSUInteger)1, nil);
}

- (void)testParseSurveyQuestion
{
    // valid
    NSDictionary *o = @{
                        @"id": @12,
                        @"type": @"text",
                        @"prompt": @"Anything else?",
                        @"extra_data": @{}};
    STAssertNotNil([MPSurveyQuestion questionWithJSONObject:o], nil);

    // nil
    STAssertNil([MPSurveyQuestion questionWithJSONObject:nil], nil);

    // empty
    STAssertNil([MPSurveyQuestion questionWithJSONObject:@{}], nil);

    // garbage keys
    STAssertNil([MPSurveyQuestion questionWithJSONObject:@{@"blah": @"foo"}], nil);

    NSMutableDictionary *m;

    // invalid id
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"id"] = @NO;
    STAssertNil([MPSurveyQuestion questionWithJSONObject:m], nil);

    // invalid question type
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"type"] = @"not_supported";
    STAssertNil([MPSurveyQuestion questionWithJSONObject:m], nil);

    // empty prompt
    m = [NSMutableDictionary dictionaryWithDictionary:o];
    m[@"prompt"] = @"";
    STAssertNil([MPSurveyQuestion questionWithJSONObject:m], nil);
}

@end
