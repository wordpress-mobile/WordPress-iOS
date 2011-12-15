//
//  InAppSettingsReader.h
//  InAppSettingsTestApp
//
//  Created by David Keegan on 1/19/10.
//  Copyright 2010 InScopeApps{+}. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InAppSettingsReaderRegisterDefaults : NSObject {
    //keep track of what files we've read to avoid circular references
    NSMutableArray *files;
    NSMutableDictionary *values;
}

@property (nonatomic, retain) NSMutableArray *files;
@property (nonatomic, retain) NSMutableDictionary *values;

@end

@interface InAppSettingsReader : NSObject {
    NSString *file;
    NSMutableArray *headers, *settings;
}

@property (nonatomic, copy) NSString *file;
@property (nonatomic, retain) NSMutableArray *headers, *settings;

- (id)initWithFile:(NSString *)inputFile;

@end
