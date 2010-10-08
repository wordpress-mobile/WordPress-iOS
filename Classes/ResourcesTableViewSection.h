//
//  ResourcesTableViewSection.h
//  WordPress
//
//  Created by Josh Bassett on 29/07/09.
//

#import <Foundation/Foundation.h>

@interface ResourcesTableViewSection : NSObject {
@private
    int numberOfRows;
    NSString *title;
    NSMutableArray *resources;
}

@property int numberOfRows;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *resources;

- (id)initWithTitle:(NSString *)aTitle;

@end
