//
//  EpilogueSegue.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-12.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

protocol EpilogueAnimation {
}

extension EpilogueAnimation where Self: UIStoryboardSegue {
    func performEpilogue(completion: @escaping (Void) -> ()) {
        guard let containerView = source.view.superview else {
            return
        }
        let sourceVC = source
        let destinationVC = destination
        let duration = 0.35

        destinationVC.view.frame = sourceVC.view.frame

        containerView.addSubview(destinationVC.view)
        containerView.addSubview(sourceVC.view)

        UIView.animate(withDuration: duration, delay: 0, options:UIViewAnimationOptions.curveEaseInOut, animations: {
            sourceVC.view.center.y += sourceVC.view.frame.size.height
        }) { (finished) in
            completion()
        }
    }
}

class EpilogueSegue: UIStoryboardSegue, EpilogueAnimation {
    let duration = 0.35

    override init(identifier: String?, source: UIViewController, destination: UIViewController) {
        super.init(identifier: identifier, source: source, destination: destination)
    }

    override func perform() {
        performEpilogue() {
            self.destination.view.removeFromSuperview()
            self.source.present(self.destination, animated: false) {}
        }
    }
}

class EpilogueUnwindSegue: UIStoryboardSegue, EpilogueAnimation {
    let duration = 0.35

    override init(identifier: String?, source: UIViewController, destination: UIViewController) {
        super.init(identifier: identifier, source: source, destination: destination)
    }

    override func perform() {
        performEpilogue() {}
    }
}
