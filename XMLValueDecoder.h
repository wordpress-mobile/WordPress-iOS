#import <Foundation/Foundation.h>

typedef enum
{
	errType = -1,
	defaultType,	//generally string
	inttype,
	doubletype,
	stringtype,
	datetype,
	booltype,
	arraytype,
	structtype,
	datatype,			//base 64
	structMemberType
} valueType;

@class XMLValueDecoder;
@protocol ValueDecoderProtocol

- (void)valueDecoder:(XMLValueDecoder *)aValueDecoder decodedValue:(id)aValue;

@end


@interface XMLValueDecoder : NSObject <ValueDecoderProtocol>
{
	id parentParser;
	id parentDecoder;

	id curStructKey;
	id curVal;
	
	NSString *curElementName;
	
	int curValueType;
	int curDecodingType;	//will be 0 for value, 1 for memeber;
}

+ (id)valueDecoderWithXMLParser:(NSXMLParser *)aParser andParentDecoder:(id)aParent;
- (id)value;
- (valueType)valueType;


@end
