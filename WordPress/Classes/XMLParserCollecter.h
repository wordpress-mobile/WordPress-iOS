//
//  XMLParserCollecter.h
//  WordPress
//
//  Created by Jorge Leandro Perez on 2/14/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLParserCollecter : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableString *result;
@end
