//
//  DTUtils.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 7/18/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "DTUtils.h"

CGSize sizeThatFitsKeepingAspectRatio(CGSize originalSize, CGSize sizeToFit)
{
	CGFloat necessaryZoomWidth = sizeToFit.width / originalSize.width;
	CGFloat necessaryZoomHeight = sizeToFit.height / originalSize.height;
	
	CGFloat smallerZoom = MIN(necessaryZoomWidth, necessaryZoomHeight);
	
	return CGSizeMake(roundf(originalSize.width*smallerZoom), roundf(originalSize.height*smallerZoom));
}

CGSize sizeThatFillsKeepingAspectRatio(CGSize originalSize, CGSize sizeToFit)
{
	CGFloat necessaryZoomWidth = sizeToFit.width / originalSize.width;
	CGFloat necessaryZoomHeight = sizeToFit.height / originalSize.height;
	
	CGFloat largerZoom = MAX(necessaryZoomWidth, necessaryZoomHeight);
	
	return CGSizeMake(roundf(originalSize.width*largerZoom), roundf(originalSize.height*largerZoom));
}

BOOL DTCGSizeMakeWithDictionaryRepresentation(NSDictionary *dict, CGSize *size)
{
	NSNumber *widthNumber = [dict objectForKey:@"Width"];
	NSNumber *heightNumber = [dict objectForKey:@"Height"];
	
	if (!widthNumber || !heightNumber)
	{
		return NO;
	}
	
	if (size)
	{
		size->width = [widthNumber floatValue];
		size->height = [heightNumber floatValue];
	}
	
	return YES;
}

NSDictionary *DTCGSizeCreateDictionaryRepresentation(CGSize size)
{
	NSNumber *widthNumber = [NSNumber numberWithFloat:size.width];
	NSNumber *heightNumber = [NSNumber numberWithFloat:size.height];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:widthNumber, @"Width", heightNumber, @"Height", nil];
}


BOOL DTCGRectMakeWithDictionaryRepresentation(NSDictionary *dict, CGRect *rect)
{
	NSNumber *widthNumber = [dict objectForKey:@"Width"];
	NSNumber *heightNumber = [dict objectForKey:@"Height"];
	NSNumber *xNumber = [dict objectForKey:@"X"];
	NSNumber *yNumber = [dict objectForKey:@"Y"];
	
	if (!widthNumber || !heightNumber || !xNumber || !yNumber)
	{
		return NO;
	}
	
	if (rect)
	{
		rect->origin.x = [xNumber floatValue];
		rect->origin.y = [yNumber floatValue];
		rect->size.width = [widthNumber floatValue];
		rect->size.height = [heightNumber floatValue];
	}
	
	return YES;
}

NSDictionary *DTCGRectCreateDictionaryRepresentation(CGRect rect)
{
	NSNumber *widthNumber = [NSNumber numberWithFloat:rect.size.width];
	NSNumber *heightNumber = [NSNumber numberWithFloat:rect.size.height];
	NSNumber *xNumber = [NSNumber numberWithFloat:rect.origin.x];
	NSNumber *yNumber = [NSNumber numberWithFloat:rect.origin.y];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:widthNumber, @"Width", heightNumber, @"Height", xNumber, @"X", yNumber, @"Y", nil];
}

CGPoint CGRectCenter(CGRect rect)
{
	return (CGPoint){ CGRectGetMidX(rect), CGRectGetMidY(rect) };
}