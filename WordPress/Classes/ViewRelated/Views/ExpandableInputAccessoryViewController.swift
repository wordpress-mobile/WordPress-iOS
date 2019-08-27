//
//  ExpandableInputAccessoryViewController.swift
//  WordPress
//
//  Created by Nathan Glass on 8/25/19.
//  Copyright © 2019 WordPress. All rights reserved.
//

import UIKit

class ExpandableInputAccessoryViewController: UIViewController {
    var customAccessoryView: ExpandableInputAccessoryView? {
        return view as? ExpandableInputAccessoryView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        customAccessoryView?.prepare()
    }
    
    
}
