//
//  SPGhost.h
//  Simperium
//
//  Created by Michael Johnston on 11-03-08.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SPGhost : NSObject

@property (copy,   nonatomic) NSString              *key;
@property (copy,   nonatomic) NSMutableDictionary   *memberData;
@property (copy,   nonatomic) NSString              *version;
@property (assign, nonatomic) BOOL                  needsSave;

- (id)initFromDictionary:(NSDictionary *)dict;
- (id)initWithKey:(NSString *)k memberData:(NSMutableDictionary *)data;
- (NSDictionary *)dictionary;

@end
