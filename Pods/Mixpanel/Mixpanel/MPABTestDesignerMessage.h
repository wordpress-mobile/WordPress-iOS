//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>

@class MPABTestDesignerConnection;

@protocol MPABTestDesignerMessage <NSObject>

@property (nonatomic, copy, readonly) NSString *type;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;

- (NSData *)JSONData;

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection;

@end
