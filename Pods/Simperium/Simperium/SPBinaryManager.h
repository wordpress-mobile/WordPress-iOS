//
//  SPBinaryManager.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-22.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPBinaryTransportDelegate.h"

#define BIN_KEY @"SPPathKey"
#define BIN_BUCKET @"SPPathBucket"
#define BIN_ATTRIBUTE @"SPPathAttribute"

@class Simperium;
@class SPUser;
@class SPManagedObject;

@interface SPBinaryManager : NSObject <SPBinaryTransportDelegate> {
    NSMutableDictionary *pendingBinaryDownloads;
    NSMutableDictionary *pendingBinaryUploads;
    NSMutableDictionary *transmissionProgress;
    Simperium *simperium;
    NSMutableSet *delegates;
    NSString *binaryAuthURL;
    NSString *directory;
    NSString *keyPrefix;
}

@property (nonatomic, copy) NSString *binaryAuthURL;
@property (nonatomic, copy) NSString *directory;
@property (nonatomic, copy) NSString *keyPrefix;
@property(nonatomic, strong, readonly) NSMutableDictionary *pendingBinaryDownloads;
@property(nonatomic, strong, readonly) NSMutableDictionary *pendingBinaryUploads;
@property(nonatomic, strong, readonly) NSMutableDictionary *transmissionProgress;

@property (nonatomic, readonly, strong) NSMutableSet *delegates;

-(id)initWithSimperium:(Simperium *)aSimperium;
-(void)setupAuth:(SPUser *)user;
-(BOOL)checkOrGetBinaryAuthentication;

-(BOOL)binaryExists:(NSString *)filename;
-(void)addPendingReferenceToFile:(NSString *)filename fromKey:(NSString *)fromKey bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName;
-(void)resolvePendingReferencesToFile:(NSString *)filename;

-(void)addBinaryWithFilename:(NSString *)filename toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName;
-(NSString *)addBinary:(NSData *)binaryData toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName;
-(NSData *)dataForFilename:(NSString *)filename;
-(NSString *)pathForFilename:(NSString *)filename;

-(void)startDownloading:(NSString *)filename;
-(void)startUploading:(NSString *)filename;

-(void)finishedDownloading:(NSString *)filename;
-(void)finishedUploading:(NSString *)filename;

-(int)sizeOfLocalFile:(NSString *)filename;
-(int)sizeOfRemoteFile:(NSString *)filename;

-(BOOL)createLocalDirectoryForPrefix: (NSString *)prefixString;
-(NSString *)prefixFilename:(NSString *)filename;

-(int)sizeRemainingToTransmit:(NSString *)filename;

-(void)addDelegate:(id)delegate;
-(void)removeDelegate:(id)delegate;

@end
