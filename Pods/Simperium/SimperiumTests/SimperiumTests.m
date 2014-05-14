//
//  SimperiumTests.m
//  SimperiumTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "SPGhost.h"
#import "JSONKit+Simperium.h"
#import "NSString+Simperium.h"
#import "Config.h"
#import "Farm.h"
#import "SPBucket.h"
#import "STKeychain.h"
#import "SPAuthenticator.h"
#import "SPHttpRequest.h"
#import "SPHttpRequestQueue.h"


@implementation SimperiumTests

- (void)waitFor:(NSTimeInterval)seconds {
    NSDate	*timeoutDate = [NSDate dateWithTimeIntervalSinceNow:seconds];
    NSLog(@"Waiting for %f seconds...", seconds);
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
		if ([timeoutDate timeIntervalSinceNow] < 0.0)
			break;
        
	} while (YES);
    
	return;
}

- (BOOL)farmsDone:(NSArray *)farmArray {
    for (Farm *farm in farmArray) {
        if (![farm isDone]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs farmArray:(NSArray *)farmArray {
    // Don't wait if everything is done already
    if ([self farmsDone:farmArray]) {
        return YES;
	}
    
	NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    self.done = NO;
    
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
		if ([timeoutDate timeIntervalSinceNow] < 0.0) {
			break;
		}
        
        // We're done when all the farms are done
        self.done = [self farmsDone: farmArray];

	} while (!self.done);
    
    // If it timed out, try to log why
    if ([timeoutDate timeIntervalSinceNow] < 0.0) {
        for (Farm *farm in farmArray) {
            [farm logUnfulfilledExpectations];
        }
    }
    
    // Wait an extra little tick so things like GET long polling have a chance to reestablish
    [self waitFor:0.1];
    
	return self.done;
}

- (BOOL)waitForCompletion {
    return [self waitForCompletion:3.0+NUM_FARMS*3 farmArray:self.farms];
}

- (Farm *)createFarm:(NSString *)label {
    if (!self.farms) {
        self.farms = [NSMutableArray arrayWithCapacity:NUM_FARMS];
    }
	
    Farm *farm = [[Farm alloc] initWithToken:self.token label:label];
    [self.farms addObject:farm];
    return farm;
}

- (void)createFarms {
    // Use a different bucket for each test so it's always starting fresh
    // (We should periodically Delete All Data in the test app to clean stuff up)
    
    for (int i = 0; i < NUM_FARMS; i++) {
        NSString *label = [NSString stringWithFormat:@"client %@", [NSString sp_makeUUID]];
        [self createFarm: label];
    }
}

- (void)startFarms {
    for (int i = 0; i < NUM_FARMS; i++) {
        Farm *farm = self.farms[i];
        [farm start];
    }
}

- (void)createAndStartFarms {
    [self createFarms];
    [self startFarms];
}

- (void)setUp {
    [super setUp];
	
	// prepare the URL Request
    NSURL *tokenURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/%@/authorize/", SERVER, APP_ID]];
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:tokenURL];
	request.HTTPMethod = @"POST";
	
    NSDictionary *authDict = @{
		@"username" : USERNAME,
		@"password" : PASSWORD,
		@"api_key"	: API_KEY
	};
		
	request.HTTPBody = [[authDict sp_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
	
	// Send the request: let's use SYNC API
	NSError* error = nil;
	NSURLResponse* response = nil;
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	// Parse the response
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	XCTAssertTrue([httpResponse isKindOfClass:[NSHTTPURLResponse class]], @"Please check NSURLConnection's API");
	
	NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	
    int code = httpResponse.statusCode;
    XCTAssertTrue(code == 200, @"bad response code %d for request %@, response: %@", code, tokenURL, responseString);
    if (code != 200) {
		NSLog(@"Auth Response: %@", responseString);
        return;
	}
    
	// Initialize!
    NSDictionary *userDict = [responseString sp_objectFromJSONString];
    
    self.token = userDict[@"access_token"];
    XCTAssertTrue(self.token.length > 0, @"invalid token from request: %@", tokenURL);
    
    [[NSUserDefaults standardUserDefaults] setObject:USERNAME forKey:@"SPUsername"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [STKeychain storeUsername:@"SPUsername" andPassword:self.token forServiceName:APP_ID updateExisting:YES error:nil];

    NSLog(@"auth token is %@", self.token);
}

- (void)tearDown {
    [super tearDown];
    
    for (Farm *farm in self.farms) {
        [farm stop];
    }
}

//- (void)ensureConfigsAreEqualTo:(Farm *)leader
//{
//    for (Farm *farm in farms) {
//        if (farm == leader)
//            continue;
//        farm.config = (Config *)[farm.simperium objectForKey:@"config" entityName:@"Config"];
//        STAssertTrue([farm.config isEqualToConfig:leader.config], @"config %@ != leader %@", farm.config, leader.config);
//    }
//}


- (void)ensureFarmsEqual: (NSArray *)farmArray entityName:(NSString *)entityName {
    // Assume all leader configs are the same since they're set manually
    Farm *leader = [farmArray objectAtIndex:0];
    NSArray *leaderObjects = [[leader.simperium bucketForName:entityName] allObjects] ;
    XCTAssertTrue([leaderObjects count] > 0, @"");
    
    //Config *leaderConfig = [leaderConfigs objectAtIndex:0];
    if ([leaderObjects count] == 0)
        return;
    
    for (Farm *farm in farmArray) {
        if (farm == leader) {
            continue;
		}
        
        NSArray *objects = [[farm.simperium bucketForName:entityName] allObjects];
        XCTAssertEqual([leaderObjects count], [objects count], @"");

        // Make sure each key was synced
        NSMutableDictionary *objectDict = [NSMutableDictionary dictionaryWithCapacity:[leaderObjects count]];
        for (TestObject *object in objects) {
            [objectDict setObject:object forKey:object.simperiumKey];
        }
        
        // Make sure each synced object is equal to the leader's objects
        for (TestObject *leaderObject in leaderObjects) {
            TestObject *object = [objectDict objectForKey:leaderObject.simperiumKey];
            //STAssertTrue([object.ghost.version isEqualToString: leaderObject.ghost.version],
            //             @"version %@ != leader version %@", object.ghost.version, leaderObject.ghost.version );
            XCTAssertTrue([object isEqualToObject:leaderObject], @"follower %@ != leader %@", object, leaderObject);
            
            // Removed ghostData check since JSONKit doesn't necessarily parse in the same order, so strings will differ
            //STAssertTrue([[object.ghostData isEqualToString:leaderObject.ghostData],
            //             @"\n\follower.ghostData %@ != \n\tleader.ghostData %@", object.ghostData, leaderObject.ghostData);
        }
    }
}

- (void)connectFarms {
    for (Farm *farm in self.farms) {
        [farm connect];
	}
}

- (void)disconnectFarms {
    for (Farm *farm in self.farms) {
        [farm disconnect];
	}
}

// Tell farms what to expect so it's possible to wait for async networking to complete
- (void)expectAdditions:(int)additions deletions:(int)deletions changes:(int)changes fromLeader:(Farm *)leader expectAcks:(BOOL)expectAcks {
    if (expectAcks) {
        int acknowledgements = additions + deletions + changes;
        leader.expectedAcknowledgments += acknowledgements;
    } else {
        leader.expectedAcknowledgments = 0;
	}
    
    for (Farm *farm in self.farms) {
        if (farm == leader) {
            continue;
		}
        farm.expectedAcknowledgments = 0;
        farm.expectedAdditions += additions;
        farm.expectedDeletions += deletions;
        farm.expectedChanges += changes;
    }
}

- (void)resetExpectations:(NSArray *)farmArray {
    for (Farm *farm in farmArray) {
        [farm resetExpectations];
    }
}

@end