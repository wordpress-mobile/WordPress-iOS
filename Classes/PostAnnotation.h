//
//  PostAnnotation.h
//  WordPress
//
//  Created by Christopher Boyd on 3/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface PostAnnotation : NSObject<MKAnnotation> {
	NSString *title;
	CLLocationCoordinate2D coordinate;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end
