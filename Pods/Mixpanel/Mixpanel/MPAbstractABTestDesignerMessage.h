//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>
#import "MPABTestDesignerMessage.h"

@interface MPAbstractABTestDesignerMessage : NSObject <MPABTestDesignerMessage>

@property (nonatomic, copy, readonly) NSString *type;

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload;

- (id)initWithType:(NSString *)type;
- (id)initWithType:(NSString *)type payload:(NSDictionary *)payload;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;
- (NSDictionary *)payload;

- (NSData *)JSONData;

@end
