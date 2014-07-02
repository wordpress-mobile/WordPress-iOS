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

#import "OCMMacroState.h"
#import "OCMockRecorder.h"
#import "OCMVerifyMacroState.h"
#import "OCMStubMacroState.h"


@implementation OCMMacroState

OCMMacroState *globalState;


+ (void)beginStubMacro
{
    globalState = [[[OCMStubMacroState alloc] init] autorelease];
}

+ (OCMockRecorder *)endStubMacro
{
    OCMockRecorder *recorder = [((OCMStubMacroState *)globalState) recorder];
    globalState = nil;
    return recorder;
}


+ (void)beginExpectMacro
{
    [self beginStubMacro];
    [(OCMStubMacroState *)globalState setShouldRecordExpectation:YES];
}

+ (OCMockRecorder *)endExpectMacro
{
    return [self endStubMacro];
}


+ (void)beginVerifyMacroAtLocation:(OCMLocation *)aLocation
{
    globalState = [[[OCMVerifyMacroState alloc] initWithLocation:aLocation] autorelease];
}

+ (void)endVerifyMacro
{
    globalState = nil;
}


+ (OCMMacroState *)globalState
{
    return globalState;
}


- (void)dealloc
{
    if(globalState == self)
        globalState = nil;
    [super dealloc];
}

- (void)switchToClassMethod
{

}

- (BOOL)hasSwitchedToClassMethod
{
    return NO;
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    // to be implemented by subclasses
}


@end
