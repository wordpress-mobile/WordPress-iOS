//
//  CustomActionSheet.h
//  WordPress
//
//  Created by Danilo Ercoli on 26.12.10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CustomActionSheet : UIActionSheet {
    id customObj;
}

@property(nonatomic, retain) id customObj;

@end