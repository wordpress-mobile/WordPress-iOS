//
//  SharePostBarButtonItem.swift
//  WordPress
//
//  Created by Nate Heagy on 2016-06-07.
//  Copyright © 2016 WordPress. All rights reserved.
//

import UIKit

class SharePostBarButtonItem: UIBarButtonItem {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override init()
    {
        super.init()
        /*
        let image = Gridicon.iconOfType(GridiconTypeShareIOS)
        WPButtonForNavigationBar *button = [self buttonForBarWithImage:image
            frame:[WPStyleGuide navigationBarButtonRect]
            target:self
            selector:@selector(sharePost)];
        
        button.removeDefaultRightSpacing = YES;
        button.rightSpacing = [WPStyleGuide spacingBetweeenNavbarButtons] / 2.0f;
        button.removeDefaultLeftSpacing = YES;
        button.leftSpacing = [WPStyleGuide spacingBetweeenNavbarButtons] / 2.0f;
        NSString *title = NSLocalizedString(@"Share", @"Title of the share button in the Post Editor.");
        button.accessibilityLabel = title;
        button.accessibilityIdentifier = @"Share";
        _shareBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
 */
    }
}
