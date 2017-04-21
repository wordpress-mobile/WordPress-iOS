//
//  LoginEmailViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

class LoginEmailViewController: SigninEmailViewController {
    override func requestLink() {
        performSegue(withIdentifier: "startMagicLinkFlow", sender: self)
    }

    override func signinWithUsernamePassword(_ immediateSignin: Bool = false) {
        performSegue(withIdentifier: "showWPComLogin", sender: self)
    }

    override func signinToSelfHostedSite() {
        performSegue(withIdentifier: "showSelfHostedLogin", sender: self)
    }
}
