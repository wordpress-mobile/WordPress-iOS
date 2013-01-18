#import "XMLRPCParserTest.h"
#import "XMLRPCEventBasedParser.h"

@interface XMLRPCParserTest (XMLRPCParserTestPrivate)

- (NSBundle *)unitTestBundle;

#pragma mark -

- (NSDictionary *)testCases;

#pragma mark -

- (BOOL)parsedResult: (id)parsedResult isEqualToTestCaseResult: (id)testCaseResult;

#pragma mark -

- (BOOL)parsedResult: (id)parsedResult isEqualToArray: (NSArray *)array;

- (BOOL)parsedResult: (id)parsedResult isEqualToDictionary: (NSDictionary *)dictionary;

@end

#pragma mark -

@implementation XMLRPCParserTest

- (void)setUp {
    myTestCases = [[self testCases] retain];
}

#pragma mark -

- (void)testEventBasedParser {
    NSEnumerator *testCaseEnumerator = [myTestCases keyEnumerator];
    id testCaseName;
    
    while (testCaseName = [testCaseEnumerator nextObject]) {
        NSString *testCase = [[self unitTestBundle] pathForResource: testCaseName ofType: @"xml"];
        NSData *testCaseData =[[[NSData alloc] initWithContentsOfFile: testCase] autorelease];
        XMLRPCEventBasedParser *parser = [[[XMLRPCEventBasedParser alloc] initWithData: testCaseData] autorelease];
        id testCaseResult = [myTestCases objectForKey: testCaseName];
        id parsedResult = [parser parse];
        
        STAssertTrue([self parsedResult: parsedResult isEqualToTestCaseResult: testCaseResult], @"The test case failed: %@", testCaseName);
    }
}

#pragma mark -

- (void)tearDown {
    [myTestCases release];
}

@end

#pragma mark -

@implementation XMLRPCParserTest (XMLRPCParserTestPrivate)

- (NSBundle *)unitTestBundle {
    return [NSBundle bundleForClass: [XMLRPCParserTest class]];
}

#pragma mark -

- (NSDictionary *)testCases {
    NSString *file = [[self unitTestBundle] pathForResource: @"TestCases" ofType: @"plist"];
    NSDictionary *testCases = [[[NSDictionary alloc] initWithContentsOfFile: file] autorelease];
    
    return testCases;
}

#pragma mark -

- (BOOL)parsedResult: (id)parsedResult isEqualToTestCaseResult: (id)testCaseResult {
    if ([testCaseResult isKindOfClass: [NSArray class]]) {
        return [self parsedResult: parsedResult isEqualToArray: testCaseResult];
    } else if ([testCaseResult isKindOfClass: [NSDictionary class]]) {
        return [self parsedResult: parsedResult isEqualToDictionary: testCaseResult];
    }
    
    if ([testCaseResult isKindOfClass: [NSNumber class]]) {
        return [parsedResult isEqualToNumber: testCaseResult];
    } else if ([testCaseResult isKindOfClass: [NSString class]]) {
        return [parsedResult isEqualToString: testCaseResult];
    } else if ([testCaseResult isKindOfClass: [NSDate class]]) {
        return [parsedResult isEqualToDate: testCaseResult];
    } else if ([testCaseResult isKindOfClass: [NSData class]]) {
        return [parsedResult isEqualToData: testCaseResult];
    }
    
    return YES;
}

#pragma mark -

- (BOOL)parsedResult: (id)parsedResult isEqualToArray: (NSArray *)array {
    NSEnumerator *arrayEnumerator = [array objectEnumerator];
    id arrayElement;
    
    if (![parsedResult isKindOfClass: [NSArray class]]) {
        return NO;
    }
    
    if ([parsedResult count] != [array count]) {
        return NO;
    }
    
    if ([parsedResult isEqualToArray: array]) {
        return YES;
    }
    
    while (arrayElement = [arrayEnumerator nextObject]) {
        NSInteger index = [array indexOfObject: arrayElement];
        
        if (![self parsedResult: [parsedResult objectAtIndex: index] isEqualToTestCaseResult: arrayElement]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)parsedResult: (id)parsedResult isEqualToDictionary: (NSDictionary *)dictionary {
    NSEnumerator *keyEnumerator = [dictionary keyEnumerator];
    id key;
    
    if (![parsedResult isKindOfClass: [NSDictionary class]]) {
        return NO;
    }
    
    if ([parsedResult count] != [dictionary count]) {
        return NO;
    }
    
    if ([parsedResult isEqualToDictionary: dictionary]) {
        return YES;
    }
    
    while (key = [keyEnumerator nextObject]) {
        if (![self parsedResult: [parsedResult objectForKey: key] isEqualToTestCaseResult: [dictionary objectForKey: key]]) {
            return NO;
        }
    }
    
    return YES;
}

@end
