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

    override func signinToSelfHostedSite() {
        performSegue(withIdentifier: "showSelfHostedLogin", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? LoginEpilogueViewController,
            let source = segue.source as? NUXAbstractViewController else {
                return
        }
        destination.dismissBlock = source.dismissBlock
        destination.originalPresentingVC = navigationController?.presentingViewController
    }
}
