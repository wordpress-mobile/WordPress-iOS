//
//  ViewController.h
//  AirDrops
//
//  Created by Stefan Gugarel on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *pressMeBarButton;

@property (strong, nonatomic) IBOutlet UILabel *buttonPressedLabel;

- (IBAction)buttonPressed:(UIBarButtonItem *)sender;

@end