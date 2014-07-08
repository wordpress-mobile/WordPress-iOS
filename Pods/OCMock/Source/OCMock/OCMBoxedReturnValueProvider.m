/*
 *  Copyright (c) 2009-2014 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import "OCMBoxedReturnValueProvider.h"
#import <objc/runtime.h>

@implementation OCMBoxedReturnValueProvider

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	const char *returnType = [[anInvocation methodSignature] methodReturnType];
	const char *valueType = [(NSValue *)returnValue objCType];
    if(![self isMethodReturnType:returnType compatibleWithValueType:valueType])
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Return value does not match method signature; signature declares '%s' but value is '%s'.", returnType, valueType];
    }

    void *buffer = malloc([[anInvocation methodSignature] methodReturnLength]);
	[returnValue getValue:buffer];
	[anInvocation setReturnValue:buffer];
	free(buffer);
}


- (BOOL)isMethodReturnType:(const char *)returnType compatibleWithValueType:(const char *)valueType
{
      /* Allow void* for methods that return id, mainly to be able to handle nil */
    if(strcmp(returnType, @encode(id)) == 0 && strcmp(valueType, @encode(void *)) == 0)
        return YES;

     /* ARM64 uses 'B' for BOOLs in method signatures but 'c' in NSValue; that case should match */
    if(returnType[0] == 'B' && valueType[0] == 'c')
        return YES;

    /* Same types are obviously compatible */
    if(strcmp(returnType, valueType) == 0)
        return YES;

    return NO;
}

@end
