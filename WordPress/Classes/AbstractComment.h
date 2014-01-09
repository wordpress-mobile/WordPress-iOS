//
//  AbstractComment.h
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WPContentViewProvider.h"

@interface AbstractComment : NSManagedObject<WPContentViewProvider>

@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * author_email;
@property (nonatomic, strong) NSString * author_ip;
@property (nonatomic, strong) NSString * author_url;
@property (nonatomic, strong) NSNumber * commentID;
@property (nonatomic, strong) NSString * content;
@property (nonatomic, strong) NSDate * dateCreated;
@property (nonatomic, strong) NSString * link;
@property (nonatomic, strong) NSNumber * parentID;
@property (nonatomic, strong) NSNumber * postID;
@property (nonatomic, strong) NSString * postTitle;
@property (nonatomic, strong) NSString * status;
@property (nonatomic, strong) NSString * type;

@end
