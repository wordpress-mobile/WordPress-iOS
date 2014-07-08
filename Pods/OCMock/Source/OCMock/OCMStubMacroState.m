/*
 *  Copyright (c) 2014 Erik Doernenburg and contributors
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

#import "OCMStubMacroState.h"
#import "OCMockObject.h"
#import "OCMockRecorder.h"

@implementation OCMStubMacroState

- (void)setShouldRecordExpectation:(BOOL)flag
{
    shouldRecordExpectation = flag;
}

- (OCMockRecorder *)recorder
{
    return recorder;
}

- (void)switchToClassMethod
{
    shouldRecordAsClassMethod = YES;
}

- (BOOL)hasSwitchedToClassMethod
{
    return shouldRecordAsClassMethod;
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    OCMockObject *mock = [anInvocation target];
    recorder = shouldRecordExpectation ? [mock expect] : [mock stub];
    if(shouldRecordAsClassMethod)
        [recorder classMethod];
    [recorder forwardInvocation:anInvocation];
}

@end
