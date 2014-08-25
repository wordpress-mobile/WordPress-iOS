//
//  ModalPanelViewController.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/24/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>

// This VC demontrates preventing of closing of panel
@interface ModalPanelViewController : UIViewController

// linked to the switch
@property (nonatomic, assign) BOOL allowClosing;

@end
