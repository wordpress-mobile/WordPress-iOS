//
//  CXMLNamespaceNode.h
//  TouchXML
//

#import <Foundation/Foundation.h>
#import "CXMLNode.h"
#import "CXMLElement.h"

@interface CXMLNamespaceNode : CXMLNode {

	NSString *_prefix;
	NSString *_uri;
	CXMLElement *_parent;
}

- (id) initWithPrefix:(NSString *)prefix URI:(NSString *)uri parentElement:(CXMLElement *)parent;

@end
