//
//  DTCustomColoredAccessory.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Constant used by DTCustomColoredAccessory to specify the type of accessory.
 */
typedef NS_ENUM(NSUInteger, DTCustomColoredAccessoryType)
{
	/**
	 An accessoring pointing to the right side
	 */
	DTCustomColoredAccessoryTypeRight = 0,
	
	/**
	 An accessoring pointing to the left side
	 */
	DTCustomColoredAccessoryTypeLeft,
	
	/**
	 An accessoring pointing upwards
	 */
	DTCustomColoredAccessoryTypeUp,
	
	/**
	 An accessoring pointing downwards
	 */
	DTCustomColoredAccessoryTypeDown
};

/**
 An accessory control that can be used instead of the standard disclosure indicator in a `UITableView`. See the DTCustomColoredAccessoryType for supported styles.
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
 @param type The DTCustomColoredAccessoryType to use
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
 The DTCustomColoredAccessoryType of the accessory.
 */
@property (nonatomic, assign)  DTCustomColoredAccessoryType type;

@end
