//
//  LoginLinkMailViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

class LoginLinkMailViewController: SigninLinkMailViewController {
    @IBAction override func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }
}
