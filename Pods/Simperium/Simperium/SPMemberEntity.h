//
//  SPMemberEntity.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMember.h"

@interface SPMemberEntity : SPMember {
    NSString *entityName;
}

@property (nonatomic, copy) NSString *entityName;

@end
