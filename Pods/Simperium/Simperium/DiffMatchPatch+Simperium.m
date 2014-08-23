//
//  DiffMatchPatch+Simperium.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 6/16/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "DiffMatchPatch+Simperium.h"
#import "NSError+Simperium.h"



static NSInteger DiffMatchPatchApplyError = -9999;


@implementation DiffMatchPatch (Simperium)

- (NSArray *)patch_apply:(NSArray *)sourcePatches toString:(NSString *)text error:(NSError **)error {
    
    NSArray *patched    = [self patch_apply:sourcePatches toString:text];
    NSArray *results    = [patched lastObject];
    BOOL success        = YES;
    
    for (NSNumber *result in results) {
        if (![result isKindOfClass:[NSNumber class]]) {
            continue;
        }
        if (!result.boolValue) {
            success = NO;
            break;
        }
    }
    
    if (!success && error) {
        *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                     code:DiffMatchPatchApplyError
                              description:@"Error while applying patch"];
    }
    
    return patched;
}

@end
