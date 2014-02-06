//
//  BinaryTransportDelegate.h
//  Simperium
//
//  Created by John Carter on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Simperium.h"

@protocol SPBinaryTransportDelegate <SimperiumDelegate>
@optional
-(void)binaryUploadStarted: (NSString *)filename;
-(void)binaryDownloadStarted: (NSString *)filename;
-(void)binaryUploadSuccessful: (NSString *)filename;
-(void)binaryDownloadSuccessful: (NSString *)filename;
-(void)binaryUploadFailed: (NSString *)filename withError: (NSError *)error;
-(void)binaryDownloadFailed: (NSString *)filename withError: (NSError *)error;
-(void)binaryUploadTransmittedBytes: (long) byteCount forFilename: (NSString *)filename;
-(void)binaryDownloadReceivedBytes: (long) byteCount forFilename: (NSString *)filename;

-(void)binaryUploadPercent: (float) percentage object: (NSManagedObject *)object;
-(void)binaryDownloadPercent: (float) percentage object: (NSManagedObject *)object;


@end
