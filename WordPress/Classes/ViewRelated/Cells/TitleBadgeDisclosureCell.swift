//
//  SiteTagCell.swift
//  WordPress
//
//  Created by Cesar Tardaguila Moro on 2017-12-04.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

final class TitleBadgeDisclosureCell: WPTableViewCell {
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellBadge: BadgeLabel!

    var name: String? {
        didSet {
            cellTitle.text = name
        }
    }

    var count: Int = 0 {
        didSet {
            if count > 0 {
                cellBadge.text = String(count)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryType = .disclosureIndicator
        accessoryView = nil

        customizeTagName()
        customizeTagCount()
    }

    private func customizeTagName() {
        cellTitle.font = WPStyleGuide.tableviewTextFont()
    }

    private func customizeTagCount() {
        cellBadge.font = WPStyleGuide.tableviewTextFont()
        cellBadge.textColor = WPStyleGuide.grey()
        cellBadge.textAlignment = .right
        cellBadge.text = ""
        cellBadge.horizontalPadding = 4
        cellBadge.borderColor = WPStyleGuide.wordPressBlue()
        cellBadge.borderWidth = 1
    }

    override func prepareForReuse() {
        cellTitle.text = ""
        cellBadge.text = ""
    }
}
