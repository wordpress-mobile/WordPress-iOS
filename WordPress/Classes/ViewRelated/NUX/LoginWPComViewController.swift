//
//  LoginWPComViewController.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

class LoginWPComViewController: SigninWPComViewController {

//    override func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
//        self.performSegue(withIdentifier: "showEpilogue", sender: self)
//    }
    
    override func dismiss() {
        self.performSegue(withIdentifier: "showEpilogue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? LoginEpilogueViewController,
              let source = segue.source as? LoginWPComViewController else {
            return
        }
        destination.dismissBlock = source.dismissBlock
        destination.originalPresentingVC = navigationController?.presentingViewController
    }
}
