//
//  SPIndexProcessor.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-16.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPProcessorNotificationNames.h"

@class Simperium;
@class SPDiffer;

@interface SPIndexProcessor : NSObject
- (void)processIndex:(NSArray *)indexArray bucket:(SPBucket *)bucket versionHandler:(void(^)(NSString *key, NSString *version))versionHandler;
- (void)processVersions:(NSArray *)versions bucket:(SPBucket *)bucket firstSync:(BOOL)firstSync changeHandler:(void(^)(NSString *key))changeHandler;
- (NSArray*)exportIndexStatus:(SPBucket *)bucket;
@end
