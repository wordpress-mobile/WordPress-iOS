//
//  SPIndexProcessor.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-16.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPProcessorConstants.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

typedef void(^SPVersionHandlerBlockType)(NSString *key, NSString *version);
typedef void(^SPChangeHandlerBlockType)(NSString *key);


#pragma mark ====================================================================================
#pragma mark SPIndexProcessor
#pragma mark ====================================================================================

@interface SPIndexProcessor : NSObject
- (void)processIndex:(NSArray *)indexArray bucket:(SPBucket *)bucket versionHandler:(SPVersionHandlerBlockType)versionHandler;
- (void)processVersions:(NSArray *)versions bucket:(SPBucket *)bucket changeHandler:(SPChangeHandlerBlockType)changeHandler;
- (NSArray*)exportIndexStatus:(SPBucket *)bucket;
@end
