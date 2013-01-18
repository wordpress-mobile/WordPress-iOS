#import "XMLRPCResponse.h"
#import "XMLRPCEventBasedParser.h"
#import "XMLRPCDataCleaner.h"

@implementation XMLRPCResponse

- (id)initWithData: (NSData *)data {
    if (!data) {
        return nil;
    }

    self = [super init];
    if (self) {
        XMLRPCEventBasedParser *parser = [[XMLRPCEventBasedParser alloc] initWithData: data];
        
        if (!parser) {
            [self release];
            
            return nil;
        }

        myBody = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        myObject = [[parser parse] retain];
        if (myObject == nil) {
            XMLRPCDataCleaner *cleaner = [[XMLRPCDataCleaner alloc] initWithData: data];
            NSData *cleanData = [cleaner cleanData];
            [cleaner release];
            [parser release];
            parser = [[XMLRPCEventBasedParser alloc] initWithData: cleanData];
            myBody = [[NSString alloc] initWithData: cleanData encoding: NSUTF8StringEncoding];
            myObject = [[parser parse] retain];
        }
        
        isFault = [parser isFault];
        
        [parser release];
    }
    
    return self;
}

#pragma mark -

- (BOOL)isFault {
    return isFault;
}

- (NSNumber *)faultCode {
    if (isFault) {
        return [myObject objectForKey: @"faultCode"];
    }
    
    return nil;
}

- (NSString *)faultString {
    if (isFault) {
        return [myObject objectForKey: @"faultString"];
    }
    
    return nil;
}

#pragma mark -

- (id)object {
    return myObject;
}

#pragma mark -

- (NSString *)body {
    return myBody;
}

#pragma mark -

- (void)dealloc {
    [myBody release];
    [myObject release];
    
    [super dealloc];
}

@end
