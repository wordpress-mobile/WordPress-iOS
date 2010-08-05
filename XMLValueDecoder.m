#import "XMLValueDecoder.h"
#import "XMLRPCExtensions.h"
#import "NSString+XMLExtensions.h"

@implementation XMLValueDecoder

- (id)initWithParser:(NSXMLParser *)aParser andParentDecoder:(id)aParent
{
	if( self = [super init] )
	{
		[aParser setDelegate:self];
		parentDecoder = aParent;
		parentParser = aParser;
		curVal = nil;
	}
	return self;
}

+ (id)valueDecoderWithXMLParser:(NSXMLParser *)aParser andParentDecoder:(id)aParent
{
	XMLValueDecoder *aVD = [[XMLValueDecoder alloc] initWithParser:aParser andParentDecoder:aParent];
	return [aVD autorelease];
}


- (id)value
{
	return curVal;
}

- (valueType)valueType
{
	return curValueType;
}

- (void)valueDecoder:(XMLValueDecoder *)aValueDecoder decodedValue:(id)aValue
{
	if( curDecodingType )
	{
		curVal = [aValueDecoder value];
	}
	else
	{
		if (!([aValueDecoder value] == nil)) {
			
			switch (curValueType)
			{
				case structtype:
					if( [aValueDecoder valueType] == structMemberType )
					{
						[curVal setValue:[aValueDecoder value] forKey:[aValueDecoder valueForKey:@"curStructKey"]];
					}
					break;
				case arraytype:
					[curVal addObject:[aValueDecoder value]];
					break;
				default:
					break;
			}
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (qName) 
	{		
        elementName = qName;
    }
	if( curElementName )
	{
		id oldCurVal = curVal;
		switch (curValueType)
		{
			case inttype:
				curVal = [NSNumber numberWithInt: [curVal intValue]];
				[oldCurVal release];
				break;
			case doubletype:
				curVal = [NSNumber numberWithFloat:[curVal floatValue]];
				[oldCurVal release];
				break;
			case stringtype:
			case defaultType:
				if( curVal )
					//Comments --- Resolved the issue in character encoding with & in the Titles  ######
	                //Comments --- Properly Dencoding the special characters with XML 26Aug2008######
					curVal = [NSString decodeXMLCharactersIn:curVal];
					//############
				[oldCurVal release];
				break;
			case booltype:
				curVal = [NSNumber numberWithBool:(BOOL)([curVal isEqualToString: @"1"]?YES:NO)];
				[oldCurVal release];
				break;
			case datatype://base 64
				curVal = [NSData base64DataFromString: curVal];
				[oldCurVal release];
				break;
			case datetype:;
				NSString *dateString = [curVal description];
				NSRange range;
				NSString *year, *month, *day, *hr, *mn, *sec;
				range.location = 0;
				range.length = 4;
				year = [dateString substringWithRange:range];
				
				range.location = 4;
				range.length = 2;
				month = [dateString substringWithRange:range];
				
				range.location = 6;
				range.length = 2;
				day = [dateString substringWithRange:range];
				
				range.location = 9;
				range.length = 2;
				hr = [dateString substringWithRange:range];
				
				range.location = 12;
				range.length = 2;
				mn = [dateString substringWithRange:range];
				
				range.location = 15;
				range.length = 2;
				sec = [dateString substringWithRange:range];
				
				NSDateComponents *comps = [[NSDateComponents alloc] init];
				[comps setYear:[year integerValue]];
				[comps setMonth:[month integerValue]];
				[comps setDay:[day integerValue]];
				[comps setHour:[hr integerValue]];
				[comps setMinute:[mn integerValue]];
				[comps setSecond:[sec	integerValue]];
				
				NSCalendar *gregorian = [[NSCalendar alloc]
																 initWithCalendarIdentifier:NSGregorianCalendar];
				curVal = [gregorian dateFromComponents:comps];
				[comps release];
				[gregorian release];
				[oldCurVal release];
				break;
			case arraytype:
				break;
			case structtype:
				break;
			default:
				break;
		}
	}
	
	if( [curElementName isEqualToString:elementName] )
	{
		curElementName = nil;
	}
	
	
	
	
	if( !curStructKey && [elementName isEqualToString:@"name"] )
	{
		curStructKey = curVal;
		curVal = nil;
		curValueType = structMemberType;
	}
	if( [elementName isEqualToString:@"member"] )
	{
		curValueType = structMemberType;
	}
	if( [elementName isEqualToString:@"value"] || [elementName isEqualToString:@"member"] )
	{
		[parser setDelegate:parentDecoder];
		[parentDecoder valueDecoder:self decodedValue:curVal];
	}
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
        elementName = qName;
    }
	
	curElementName = elementName;
	
	if( [elementName isEqualToString:@"value"] )
	{
		XMLValueDecoder *child = [XMLValueDecoder valueDecoderWithXMLParser:parser andParentDecoder:self];
		//simply do nothing, just to escape from warning.
		//parser delegate will take care of all.
		[[child retain] release];
	}
	else if( [elementName isEqualToString:@"member"])
	{
		XMLValueDecoder *child = [XMLValueDecoder valueDecoderWithXMLParser:parser andParentDecoder:self];
		[child setValue:[NSNumber numberWithInt:1] forKey:@"curDecodingType"];
	}
	else if( [elementName isEqualToString:@"int"] || [elementName isEqualToString:@"i4"])
	{
		curValueType = inttype;
	}
	else if( [elementName isEqualToString:@"boolean"])
	{
		curValueType = booltype;

	}
	else if( [elementName isEqualToString:@"string"])
	{
		curValueType = stringtype;

	}
	else if( [elementName isEqualToString:@"dateTime.iso8601"])
	{
		curValueType = datetype;
		
	}
	else if( [elementName isEqualToString:@"double"])
	{
		curValueType = doubletype;

	}
	else if( [elementName isEqualToString:@"array"])
	{
		curValueType = arraytype;
		curVal = [NSMutableArray array];
	}
	else if( [elementName isEqualToString:@"data"]) //don't do any thing, this is part of array
	{
		
	}
	else if( [elementName isEqualToString:@"struct"])
	{
		curValueType = structtype;
		curVal = [NSMutableDictionary dictionary];
	}
	else if( [elementName isEqualToString:@"base64"])
	{
		curValueType = datatype;

	}
	else if( [elementName isEqualToString:@"base64"])
	{
		curValueType = datatype;
		
	}
	else //default string
	{
		curValueType = defaultType;
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	//TODO: JB did this, take it out later
	//NSLog(@"String from XMLVauueDecoder: parser :: %@", string);
	
	if( !curElementName || !string )
	{
		return;
	}

	switch (curValueType)
	{
		case inttype:
		case doubletype:
		case stringtype:
		case defaultType:
		case booltype:
		case datatype://base 64
		case datetype:
			if( curVal == nil )
				curVal = [[NSMutableString alloc] initWithString:string];
			else
				[curVal appendString:string];
			break;
		case arraytype:
			break;
		case structtype:
			break;
		default:
			break;
	}
}

@end