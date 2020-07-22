//
//  AddPostCategoryButton.swift
//  BeauVoyage
//
//  Created by Lukasz Koszentka on 7/17/20.
//  Copyright © 2020 BeauVoyage. All rights reserved.
//

import UIKit

@objc final class AddPostCategoryButton: UIButton {

    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? UIColor(named: "Blue60") : UIColor(named: "Blue20")
        }
    }

}
