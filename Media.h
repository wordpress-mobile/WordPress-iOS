//
//  Media.h
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  
//

#import <CoreData/CoreData.h>


@interface Media :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, retain) NSString * remoteURL;
@property (nonatomic, retain) NSNumber * ID;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSNumber * postID;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * localURL;
@property (nonatomic, retain) NSDate * creationDate;

@end



