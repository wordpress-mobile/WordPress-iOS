//
//  ZIpArchiveModel.h
//  Zippo
//
//  Created by Stefan Gugarel on 3/15/13.
//  Copyright (c) 2013 Drobnik KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZipArchiveModel : NSObject

- (id)initWithURL:(NSURL *)URL;

@property (nonatomic, readonly) NSString *fileName;

@property (nonatomic, readonly) BOOL unzipped;

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) NSURL *unzippedFolderURL;
@property (nonatomic, readonly) NSURL *unzippedURL;

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSString *unzippedFolderPath;
@property (nonatomic, readonly) NSString *unzippedPath;

@property (nonatomic, assign) float progress;

@end
