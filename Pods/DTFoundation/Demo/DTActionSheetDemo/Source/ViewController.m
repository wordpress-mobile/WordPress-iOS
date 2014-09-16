//
//  ViewController.m
//  AirDrops
//
//  Created by Stefan Gugarel on 01/11/13.
//  Copyright (c) 2013 . All rights reserved.
//

#import "ViewController.h"
#import "DTFoundation.h"

#import "DTActionSheet.h"


@implementation ViewController

- (IBAction)buttonPressed:(UIBarButtonItem *)sender
{
	DTActionSheet *actionSheet = [[DTActionSheet alloc] initWithTitle:@"The Expendables 3"];
	
	NSString *jasonString = @"Jason Statham";
	[actionSheet addButtonWithTitle:jasonString block:^{
		
		_buttonPressedLabel.text = jasonString;
	}];
	
	NSString *dolphString = @"Dolph Lundgren";
	[actionSheet addButtonWithTitle:dolphString block:^{
		
		_buttonPressedLabel.text = dolphString;
	}];
	
	NSString *arnieString = @"Arnold Schwarzenegger";
	[actionSheet addButtonWithTitle:arnieString block:^{
		
		_buttonPressedLabel.text = arnieString;
	}];
	
	NSString *slyString = @"Sylvester Stallone";
	[actionSheet addButtonWithTitle:slyString block:^{
		
		_buttonPressedLabel.text = slyString;
	}];
	
	[actionSheet addCancelButtonWithTitle:@"Cancel" block:^{
		
		_buttonPressedLabel.text = @"Cancel";
	}];
	
	[actionSheet showFromBarButtonItem:_pressMeBarButton animated:YES];
}

@end