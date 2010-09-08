//
//  WPXMLReader.h
//  WordPress
//
//  Created by JanakiRam on 22/01/09.
//

#import <Foundation/Foundation.h>

@interface WPXMLReader : NSObject {
    NSString *hostUrl;
}

@property (nonatomic, retain) NSString *hostUrl;

- (void)parseXMLData:(NSData *)data parseError:(NSError * *)error;

@end
