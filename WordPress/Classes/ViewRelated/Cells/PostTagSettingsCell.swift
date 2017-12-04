//
//  PostTagSettingsCell.swift
//  WordPress
//
//  Created by Cesar Tardaguila Moro on 2017-12-04.
//  Copyright © 2017 WordPress. All rights reserved.
//

import Foundation
final class PostTagSettingsCell: WPTableViewCellDefault {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value2, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc var badgeCount: Int = 0 {
        didSet {
            if badgeCount > 0 {
////                badgeLabel.text = String(badgeCount)
//                accessoryView = UILabel(badgeText: String(badgeCount))
//                accessoryType = .disclosureIndicator
                badgeLabel.label.text = String(badgeCount)
                badgeLabel.sizeToFit()
                accessoryView = badgeLabel
                accessoryType = .disclosureIndicator
            } else {
                accessoryView = nil
                accessoryType = .disclosureIndicator
            }
        }
    }

    private lazy var badgeLabel: PaddedLabel = {
        //let label = PaddedLabel(rect: CGSize(width: 50, height: 30))
        let label = PaddedLabel(frame: CGRect(origin: .zero, size: PostTagSettingsCell.badgeSize))
        label.padding = (10, 0)
        label.layer.borderColor = WPStyleGuide.newKidOnTheBlockBlue().cgColor
        label.layer.borderWidth = 2
        label.layer.cornerRadius = type(of: self).badgeCornerRadius
//        label.layer.borderColor = WPStyleGuide.newKidOnTheBlockBlue().cgColor
//        label.layer.borderWidth = 2
//        label.clipsToBounds = true
//        label.textColor = .red
//
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.addConstraint(NSLayoutConstraint(item: label, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: label, attribute: .height, multiplier: 1, constant: 0))

        return label
    }()

//    fileprivate lazy var badgeLabel: UILabel = {
//        let label = BadgeLabel(frame: CGRect(origin: .zero, size: PostTagSettingsCell.badgeSize))
//        label.borderColor = WPStyleGuide.newKidOnTheBlockBlue()
//        label.borderWidth = 2
//        label.textColor = WPStyleGuide.newKidOnTheBlockBlue()
//        label.backgroundColor = .white
//        label.textAlignment = .right
//        label.cornerRadius = type(of: self).badgeCornerRadius
//        //label.horizontalPadding = 40
////        label.layer.masksToBounds = true
////        label.layer.cornerRadius = PostTagSettingsCell.badgeCornerRadius
////        label.textAlignment = .center
////        label.backgroundColor = WPStyleGuide.newKidOnTheBlockBlue()
////        label.textColor = UIColor.white
//        //label.sizeToFit())
//        return label
//    }()

    fileprivate static let badgeSize = CGSize(width: 50, height: 30)
    fileprivate static var badgeCornerRadius: CGFloat {
        return badgeSize.height / 2
    }
}

extension UILabel {
    convenience init(badgeText: String, color: UIColor = .red, fontSize: CGFloat = UIFont.smallSystemFontSize) {
        self.init()
        text = " \(badgeText) "
        textColor = .blue
        backgroundColor = color

        font = UIFont.systemFont(ofSize: fontSize)
        layer.cornerRadius = fontSize * CGFloat(0.6)
        clipsToBounds = true

        translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
}
