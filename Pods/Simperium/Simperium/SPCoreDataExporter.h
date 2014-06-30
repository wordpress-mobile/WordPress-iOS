//
//  SPCoreDataExporter.h
//  Simperium
//
//  Created by Michael Johnston on 11-06-02.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>



#pragma mark ====================================================================================
#pragma mark SPCoreDataExporter
#pragma mark ====================================================================================

@interface SPCoreDataExporter : NSObject

- (NSDictionary *)exportModel:(NSManagedObjectModel *)model classMappings:(NSMutableDictionary *)classMappings;

@end
