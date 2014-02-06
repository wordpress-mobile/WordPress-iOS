//
//  SPMemberBinary.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMember.h"

@class SPBinaryManager;

@interface SPMemberBinary : SPMember {
    SPBinaryManager *binaryManager;
}

@property (nonatomic, strong) SPBinaryManager *binaryManager;

@end
