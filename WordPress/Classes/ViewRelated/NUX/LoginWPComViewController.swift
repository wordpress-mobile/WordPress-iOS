//
//  LoginWPComViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

class LoginWPComViewController: SigninWPComViewController {
    override func dismiss() {
        self.performSegue(withIdentifier: "showEpilogue", sender: self)
    }

    override func needsMultifactorCode() {
        configureStatusLabel("")
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        self.performSegue(withIdentifier: "show2FA", sender: self)
    }
}
