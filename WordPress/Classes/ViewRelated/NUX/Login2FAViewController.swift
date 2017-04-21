//
//  Login2FAViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-20.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

class Login2FAViewController: Signin2FAViewController {
    override func dismiss() {
        self.performSegue(withIdentifier: "showEpilogue", sender: self)
    }
}
