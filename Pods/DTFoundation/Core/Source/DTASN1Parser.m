//
//  DTASN1Parser.m
//  ssltest
//
//  Created by Oliver Drobnik on 19.02.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "DTASN1Parser.h"
#import "DTASN1BitString.h"

@implementation DTASN1Parser
{
	NSData *_data;
	NSUInteger _dataLength;
	NSUInteger _parseLevel;
	
	NSError *_parserError;
	BOOL _abortParsing;
	
	NSDateFormatter *_UTCFormatter;
	
	// lookup bitmask what delegate methods are implemented
	struct
	{
		unsigned int delegateSupportsDocumentStart:1;
		unsigned int delegateSupportsDocumentEnd:1;
		unsigned int delegateSupportsContainerStart:1;
		unsigned int delegateSupportsContainerEnd:1;
		unsigned int delegateSupportsContextStart:1;
		unsigned int delegateSupportsContextEnd:1;
		unsigned int delegateSupportsString:1;
		unsigned int delegateSupportsInteger:1;
		unsigned int delegateSupportsData:1;
		unsigned int delegateSupportsBitString:1;
		unsigned int delegateSupportsNumber:1;
		unsigned int delegateSupportsNull:1;
		unsigned int delegateSupportsError:1;
		unsigned int delegateSupportsDate:1;
		unsigned int delegateSupportsObjectIdentifier:1;
		
	} _delegateFlags;
	
	DT_WEAK_VARIABLE id <DTASN1ParserDelegate> _delegate;
}

- (id)initWithData:(NSData *)data
{
	self = [super init];
	
	if (self)
	{
		_data = data;
		_dataLength = [data length];
		
		// has to end with Z
		_UTCFormatter = [[NSDateFormatter alloc] init];
		_UTCFormatter.dateFormat = @"yyMMddHHmmss'Z'";
		_UTCFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
		
		if (!_dataLength)
		{
			return nil;
		}
	}
	
	return self;
}

#pragma mark Parsing
- (void)_parseErrorEncountered:(NSString *)errorMsg
{
	_abortParsing = YES;
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
	_parserError = [NSError errorWithDomain:@"DTASN1ParserDomain" code:1 userInfo:userInfo];
	
	if (_delegateFlags.delegateSupportsError)
	{
		[_delegate parser:self parseErrorOccurred:_parserError];
	}
}

- (NSUInteger)_parseLengthAtLocation:(NSUInteger)location lengthOfLength:(NSUInteger *)lengthOfLength
{
	NSUInteger retValue = 0;
	NSUInteger currentLocation = location;
	
	unsigned char buffer;
	[_data getBytes:&buffer range:NSMakeRange(location, 1)];
	currentLocation++;
	
	if (buffer<0x80)
	{
		retValue = (NSUInteger)buffer;
	}
	else if (buffer>0x80)
	{
		// next n bytes describe the length length
		NSUInteger lengthLength = buffer-0x80;
		NSRange lengthRange = NSMakeRange(currentLocation,lengthLength);
		
		// get the length bytes
		unsigned char *lengthBytes = malloc(lengthLength);
		[_data getBytes:lengthBytes range:lengthRange];
		currentLocation += lengthLength;
		
		for (int i=0; i<lengthLength;i++)
		{
			// shift previous
			retValue <<= 8;
			
			// add the new byte
			retValue += lengthBytes[i];
		}
		
		free(lengthBytes);
	}
	else
	{
		// length 0x80 means "indefinite"
		[self _parseErrorEncountered:@"Indefinite Length form encounted, not implemented"];
	}
	
	if (lengthOfLength)
	{
		*lengthOfLength = currentLocation - location;
	}
	
	return retValue;
}

- (BOOL)_parseValueWithTag:(NSUInteger)tag dataRange:(NSRange)dataRange
{
	if (!dataRange.length && tag != DTASN1TypeNull)
	{
		NSLog(@"Encountered zero length data for tag %ld", (unsigned long)tag);
		
		// only NULL can have zero length
		return NO;
	}
	
	switch (tag)
	{
		case DTASN1TypeBoolean:
		{
			if (dataRange.length!=1)
			{
				[self _parseErrorEncountered:@"Illegal length of Boolean value"];
				return NO;
			}
			
			if (_delegateFlags.delegateSupportsNumber)
			{
				unsigned char boolByte;
				[_data getBytes:&boolByte range:NSMakeRange(dataRange.location, 1)];
				
				BOOL b = boolByte!=0;
				
				NSNumber *number = [NSNumber numberWithBool:b];
				[_delegate parser:self foundNumber:number];
			}
			break;
		}
			
		case DTASN1TypeInteger:
		{
			BOOL sendAsData = NO;
			
			if (dataRange.length<=4)
			{
				char *buffer = malloc(dataRange.length);
				[_data getBytes:buffer range:dataRange];
				
				if (_delegateFlags.delegateSupportsNumber)
				{
					NSUInteger value = 0;
					
					for (int i=0; i<dataRange.length; i++)
					{
						value <<=8;
						value += buffer[i];
					}
					
					NSNumber *number = [NSNumber numberWithUnsignedInteger:value];
					
					[_delegate parser:self foundNumber:number];
				}
				else
				{
					// send number as data if supported, too long for 32 bit
					sendAsData = YES;
				}
				
				free(buffer);
			}
			else
			{
				// send number as data if supported, delegate does not want numbers
				sendAsData = YES;
			}
			
			if (sendAsData && _delegateFlags.delegateSupportsData)
			{
				char *buffer = malloc(dataRange.length);
				[_data getBytes:buffer range:dataRange];
				NSData *data = [NSData dataWithBytesNoCopy:buffer length:dataRange.length freeWhenDone:YES];
				
				[_delegate parser:self foundData:data];
			}
			
			break;
		}
			
		case DTASN1TypeBitString:
		{
			if (_delegateFlags.delegateSupportsBitString)
			{
				char *buffer = malloc(dataRange.length);
				[_data getBytes:buffer range:dataRange];
				
				// primitive encoding
				NSUInteger unusedBits = buffer[0];
				
				NSData *data = [NSData dataWithBytes:buffer+1 length:dataRange.length-1];
				DTASN1BitString *bitstring = [[DTASN1BitString alloc] initWithData:data unusedBits:unusedBits];
				
				[_delegate parser:self foundBitString:bitstring];
				
				free(buffer);
			}
			
			break;
		}
			
		case DTASN1TypeOctetString:
		{
			if (_delegateFlags.delegateSupportsData)
			{
				char *buffer = malloc(dataRange.length);
				[_data getBytes:buffer range:dataRange];
				NSData *data = [NSData dataWithBytesNoCopy:buffer length:dataRange.length freeWhenDone:YES];
				
				[_delegate parser:self foundData:data];
			}
			
			break;
		}
			
		case DTASN1TypeNull:
		{
			if (_delegateFlags.delegateSupportsNull)
			{
				[_delegate parserFoundNull:self];
			}
			
			break;
		}
			
		case DTASN1TypeObjectIdentifier:
		{
			if (_delegateFlags.delegateSupportsObjectIdentifier)
			{
				NSMutableArray *indexes = [NSMutableArray array];
				
				unsigned char *buffer = malloc(dataRange.length);
				[_data getBytes:buffer range:dataRange];
				
				// first byte is different
				[indexes addObject:[NSNumber numberWithUnsignedInteger:buffer[0]/40]];
				[indexes addObject:[NSNumber numberWithUnsignedInteger:buffer[0]%40]];
				
				for (int i=1; i<dataRange.length; i++)
				{
					NSUInteger value=0;
					
					BOOL more = NO;
					do
					{
						unsigned char b = buffer[i];
						value = value * 128;
						value += (b & 0x7f);
						
						more = ((b & 0x80) == 0x80);
						
						if (more)
						{
							i++;
						}
						
						if (i==dataRange.length && more)
						{
							[self _parseErrorEncountered:@"Invalid object identifier with more bit set on last octed"];
							free(buffer);
							
							return NO;
						}
					} while (more);
					
					[indexes addObject:[NSNumber numberWithUnsignedInteger:value]];
				}
				
				NSString *joinedComponents = [indexes componentsJoinedByString:@"."];
				[_delegate parser:self foundObjectIdentifier:joinedComponents];
				
				free(buffer);
			}
			
			break;
		}
			
		case DTASN1TypeTeletexString:
		case DTASN1TypeGraphicString:
		case DTASN1TypePrintableString:
        case DTASN1TypeUTF8String:
        case DTASN1TypeIA5String:
		{
			if (_delegateFlags.delegateSupportsString)
			{
				char *buffer = malloc(dataRange.length);
				[_data getBytes:buffer range:dataRange];
				
				NSString *string = [[NSString alloc] initWithBytesNoCopy:buffer length:dataRange.length encoding:NSUTF8StringEncoding freeWhenDone:YES];
				
				[_delegate parser:self foundString:string];
			}
			break;
		}
            
		case DTASN1TypeUTCTime:
		case DTASN1TypeGeneralizedTime:
		{
			if (_delegateFlags.delegateSupportsDate)
			{
				char *buffer = malloc(dataRange.length);
				[_data getBytes:buffer range:dataRange];
				
				NSString *string = [[NSString alloc] initWithBytesNoCopy:buffer length:dataRange.length encoding:NSASCIIStringEncoding freeWhenDone:YES];
				
				NSDate *parsedDate = [_UTCFormatter dateFromString:string];
				
				if (parsedDate)
				{
					[_delegate parser:self foundDate:parsedDate];
				}
				else
				{
					NSString *msg = [NSString stringWithFormat:@"Cannot parse date '%@'", string];
					[self _parseErrorEncountered:msg];
					return NO;
				}
			}
			
			break;
		}
			
		default:
		{
			NSString *msg = [NSString stringWithFormat:@"Tag of type %ld not implemented", (unsigned long)tag];
			[self _parseErrorEncountered:msg];
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)_parseRange:(NSRange)range
{
	_parseLevel++;
	
	NSUInteger location = range.location;
	
	do
	{
		if (_abortParsing)
		{
			return NO;
		}
		
		// get type
		unsigned char tagByte;
		[_data getBytes:&tagByte range:NSMakeRange(location, 1)];
		location++;
		
		NSUInteger tagClass = tagByte >> 6;
		DTASN1Type tagType = tagByte & 31;
		BOOL tagConstructed = (tagByte >> 5) & 1;
		
		if (tagType == DTASN1TypeUsesLongForm)
		{
			[self _parseErrorEncountered:@"Long form not implemented"];
			return NO;
		}
		
		// get length
		NSUInteger lengthOfLength;
		NSUInteger length = [self _parseLengthAtLocation:location lengthOfLength:&lengthOfLength];
		
		// abort if there was a problem with the length
		if (_parserError)
		{
			return NO;
		}
		
		location += lengthOfLength;
		
		// make range
		NSRange subRange = NSMakeRange(location, length);
		
		if (NSMaxRange(subRange) > NSMaxRange(range))
		{
			return NO;
		}
		
		if (tagClass == 2)
		{
			if (_delegateFlags.delegateSupportsContextStart)
			{
				[_delegate parser:self didStartContextWithTag:tagType];
			}
			
			if (!tagConstructed)
			{
				tagType = DTASN1TypeOctetString;
			}
		}
		
		if (tagConstructed)
		{
			if (_delegateFlags.delegateSupportsContainerStart)
			{
				[_delegate parser:self didStartContainerWithType:tagType];
			}
			
			// allow for sequence without content
			if (subRange.length > 0)
			{
				if (![self _parseRange:subRange])
				{
					_abortParsing = YES;
				}
			}
			
			if (_delegateFlags.delegateSupportsContainerEnd)
			{
				[_delegate parser:self didEndContainerWithType:tagType];
			}
		}
		else
		{
			// primitive
			if (![self _parseValueWithTag:tagType dataRange:subRange])
			{
				_abortParsing = YES;
			}
		}
		
		if (tagClass == 2)
		{
			if (_delegateFlags.delegateSupportsContextStart)
			{
				[_delegate parser:self didEndContextWithTag:tagType];
			}
		}
		
		// advance
		location += length;
		
	} while (location < NSMaxRange(range));
	
	// check that previous length matches up with where we ended up
	if (location != NSMaxRange(range))
	{
		[self _parseErrorEncountered:@"Location not matching up with end of range"];
		return NO;
	}
	
	_parseLevel--;
	
	return YES;
}

- (BOOL)parse
{
	@autoreleasepool
	{
		if (_delegateFlags.delegateSupportsDocumentStart)
		{
			[_delegate parserDidStartDocument:self];
		}
		
		BOOL result = [self _parseRange:NSMakeRange(0, _dataLength)];
		
		if (result && _delegateFlags.delegateSupportsDocumentEnd)
		{
			[_delegate parserDidEndDocument:self];
		}
		
		return result;
	}
}

- (void)abortParsing
{
	_abortParsing = YES;
}

#pragma mark Properties

- (id <DTASN1ParserDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate:(id <DTASN1ParserDelegate>)delegate;
{
	_delegate = delegate;
	
	if ([_delegate respondsToSelector:@selector(parserDidStartDocument:)])
	{
		_delegateFlags.delegateSupportsDocumentStart = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parserDidEndDocument:)])
	{
		_delegateFlags.delegateSupportsDocumentEnd = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:didStartContainerWithType:)])
	{
		_delegateFlags.delegateSupportsContainerStart = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:didEndContainerWithType:)])
	{
		_delegateFlags.delegateSupportsContainerEnd= YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:didStartContextWithTag:)])
	{
		_delegateFlags.delegateSupportsContextStart = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:didEndContextWithTag:)])
	{
		_delegateFlags.delegateSupportsContextEnd = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:parseErrorOccurred:)])
	{
		_delegateFlags.delegateSupportsError = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:foundString:)])
	{
		_delegateFlags.delegateSupportsString = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parserFoundNull:)])
	{
		_delegateFlags.delegateSupportsNull = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:foundDate:)])
	{
		_delegateFlags.delegateSupportsDate = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:foundData:)])
	{
		_delegateFlags.delegateSupportsData = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:foundBitString:)])
	{
		_delegateFlags.delegateSupportsBitString = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:foundNumber:)])
	{
		_delegateFlags.delegateSupportsNumber = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(parser:foundObjectIdentifier:)])
	{
		_delegateFlags.delegateSupportsObjectIdentifier = YES;
	}
}

@synthesize parserError = _parserError;

@end
