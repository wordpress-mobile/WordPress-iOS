//
//  ZIpArchiveModel.m
//  Zippo
//
//  Created by Stefan Gugarel on 3/15/13.
//  Copyright (c) 2013 Drobnik KG. All rights reserved.
//

#import "ZipArchiveModel.h"

@implementation ZipArchiveModel

- (id)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self)
    {
        
        NSString *path = [URL absoluteString];
        NSString *fileName = [path lastPathComponent];
        
        _fileName = fileName;
        
        _URL = URL;
        
        _unzippedURL = [_URL URLByDeletingPathExtension];
        
        _unzippedFolderURL = [_URL URLByDeletingLastPathComponent];
    }
    return self;
}

- (BOOL)unzipped
{
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.unzippedPath isDirectory:&isDirectory] && isDirectory)
    {
        return YES;
    }
    
    return NO;
}

- (NSString *)path
{
    return [_URL path];
}

- (NSString *)unzippedPath
{
    return [_unzippedURL path];
}

- (NSString *)unzippedFolderPath
{
    return [_unzippedFolderURL path];
}


@end
