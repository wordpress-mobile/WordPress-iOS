//
//  CJSONSerializer.m
//  TouchCode
//
//  Created by Jonathan Wight on 12/07/2005.
//  Copyright 2005 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "MPCJSONSerializer.h"

#import "MPCJSONDataSerializer.h"

@implementation MPCJSONSerializer

+ (id)serializer
{
return([[[self alloc] init] autorelease]);
}

- (id)init
{
if ((self = [super init]) != NULL)
	{
	serializer = [[MPCJSONDataSerializer alloc] init];
	}
return(self);
}

- (void)dealloc
{
[serializer release];
serializer = NULL;
//
[super dealloc];
}

- (NSString *)serializeObject:(id)inObject error:(NSError **)outError
{
NSData *theData = [serializer serializeObject:inObject error:outError];
if (theData == NULL)
	return(NULL);
return([[[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding] autorelease]);
}

- (NSString *)serializeArray:(NSArray *)inArray error:(NSError **)outError
{
NSData *theData = [serializer serializeArray:inArray error:outError];
if (theData == NULL)
	return(NULL);
return([[[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding] autorelease]);
}

- (NSString *)serializeDictionary:(NSDictionary *)inDictionary error:(NSError **)outError
{
NSData *theData = [serializer serializeDictionary:inDictionary error:outError];
if (theData == NULL)
	return(NULL);
return([[[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding] autorelease]);
}
@end
