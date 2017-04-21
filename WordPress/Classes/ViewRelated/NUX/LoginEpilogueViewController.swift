//
//  PostLoginViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-12.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit
class LoginEpilogueViewController: UIViewController {
    var originalPresentingVC: UIViewController?
    var dismissBlock: ((_ cancelled: Bool) -> Void)?

    // @IBAction to allow to set the selector for target in the storyboard
    @IBAction func unwindOut(segue: UIStoryboardSegue) {
        dismissBlock?(false)
    }
}
