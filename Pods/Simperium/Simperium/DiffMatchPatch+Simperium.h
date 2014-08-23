//
//  DiffMatchPatch+Simperium.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 6/16/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "DiffMatchPatch.h"


@interface DiffMatchPatch (Simperium)

- (NSArray *)patch_apply:(NSArray *)sourcePatches toString:(NSString *)text error:(NSError **)error;

@end
