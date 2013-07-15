//
//  DTCustomColoredAccessory.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum
{
	DTCustomColoredAccessoryTypeRight = 0,
	DTCustomColoredAccessoryTypeLeft,
	DTCustomColoredAccessoryTypeUp,
	DTCustomColoredAccessoryTypeDown
} DTCustomColoredAccessoryType;

/**
 An accessory control that can be used instead of the standard disclosure indicator in a `UITableView`. These styles are supported: 
 
 - DTCustomColoredAccessoryTypeRight
 - DTCustomColoredAccessoryTypeLeft
 - DTCustomColoredAccessoryTypeUp
 - DTCustomColoredAccessoryTypeDown
 */

@interface DTCustomColoredAccessory : UIControl

/**-------------------------------------------------------------------------------------
 @name Creating A Custom-Colored Accessory
 ---------------------------------------------------------------------------------------
 */

/**
 Creates a custom-colored right disclosure indicator accessory with a given color
 @param color The color to use
 */
+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color;

/**
 Creates a custom-colored accessory with a given color and type
 @param color The color to use
 @param type The type to use
 @see type
 */
+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color type:(DTCustomColoredAccessoryType)type;

/**-------------------------------------------------------------------------------------
 @name Properties
 ---------------------------------------------------------------------------------------
 */

/**
 The color to draw the accessory in
 */
@property (nonatomic, retain) UIColor *accessoryColor;

/**
 The color to draw the accessory in while highlighted
 */
@property (nonatomic, retain) UIColor *highlightedColor;

/**
 The type of the accessory:
 
 - DTCustomColoredAccessoryTypeRight
 - DTCustomColoredAccessoryTypeLeft
 - DTCustomColoredAccessoryTypeUp
 - DTCustomColoredAccessoryTypeDown
 */
@property (nonatomic, assign)  DTCustomColoredAccessoryType type;

@end
