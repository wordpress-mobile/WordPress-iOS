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

        XMLRPCDataCleaner *cleaner = [[XMLRPCDataCleaner alloc] initWithData:data];
        myBody = [[NSString alloc] initWithData: [cleaner cleanData] encoding: NSUTF8StringEncoding];
        myObject = [[parser parse] retain];
        
        isFault = [parser isFault];
        
        [parser release];
        [cleaner release];
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
