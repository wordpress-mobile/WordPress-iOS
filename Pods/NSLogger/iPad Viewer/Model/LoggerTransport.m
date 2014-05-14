/*
 *
 * Modified BSD license.
 *
 * Based on source code copyright (c) 2010-2012 Florent Pillet,
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights
 * Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Any redistribution is done solely for personal benefit and not for any
 *    commercial purpose or for monetary gain
 *
 * 4. No binary form of source code is submitted to App Store℠ of Apple Inc.
 *
 * 5. Neither the name of the Sung-Taek, Kim nor the names of its contributors
 *    may be used to endorse or promote products derived from  this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER AND AND CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "LoggerTransport.h"

@implementation LoggerTransport
@synthesize connections;
@synthesize secure, active, ready, failed, failureReason;
@synthesize tag;

- (id)init
{
	if ((self = [super init]) != nil)
	{
		connections = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[failureReason release];
	[connections release];
	[super dealloc];
}

- (void)addConnection:(LoggerConnection *)aConnection
{
	[connections addObject:aConnection];
}

- (void)removeConnection:(LoggerConnection *)aConnection
{
	if ([connections containsObject:aConnection])
	{
		[[LoggerTransportManager sharedTransportManager] transport:self removeConnection:aConnection];
		
		[aConnection shutdown];

		[self.connections removeObject:aConnection];
	}
}

- (void)reportStatusToManager:(NSDictionary *)aStatusDict
{
	[[LoggerTransportManager sharedTransportManager] presentTransportStatus:aStatusDict];
}

- (void)reportErrorToManager:(NSDictionary *)anErrorDict
{
	[[LoggerTransportManager sharedTransportManager] presentTransportError:anErrorDict];
}

- (void)startup
{
	//  subclasses should implement this
	assert(false);
}

- (void)shutdown
{
	// subclasses should implement this
	assert(false);
}

- (void)restart
{
	// subclasses should implement this
	assert(false);
}

- (NSString *)transportInfoString
{
	// subclasses should implement this
	assert(false);
	return nil;
}

- (NSString *)transportStatusString
{
	// subclasses should implement this
	assert(false);
	return nil;
}

- (NSDictionary *)status
{
	// subclasses should implement this
	assert(false);
	return nil;
}

//------------------------------------------------------------------------------
#pragma mark - logger connection delegate
//------------------------------------------------------------------------------
- (void)connection:(LoggerConnection *)theConnection
didEstablishWithMessage:(LoggerMessage *)theMessage
{
	[[LoggerTransportManager sharedTransportManager]
	 transport:self
	 didEstablishConnection:theConnection
	 clientInfo:theMessage];
}

// method that may not be called on main thread
- (void)connection:(LoggerConnection *)theConnection
didReceiveMessages:(NSArray *)theMessages
			 range:(NSRange)rangeInMessagesList
{
	[[LoggerTransportManager sharedTransportManager]
	 transport:self
	 connection:theConnection
	 didReceiveMessages:theMessages
	 range:rangeInMessagesList];
}

-(void)connection:(LoggerConnection *)theConnection
didDisconnectWithMessage:(LoggerMessage *)theMessage
{
	[[LoggerTransportManager sharedTransportManager]
	 transport:self
	 didDisconnectRemote:theConnection
	 lastMessage:theMessage];
}
@end
