//
//  SiteTagCell.swift
//  WordPress
//
//  Created by Cesar Tardaguila Moro on 2017-12-04.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

final class SiteTagCell: WPTableViewCell {
    @IBOutlet weak var tagName: UILabel!
    @IBOutlet weak var tagCount: UILabel!

    var name: String? {
        didSet {
            tagName.text = name
        }
    }

    var count: Int = 0 {
        didSet {
            if count > 0 {
                tagCount.text = String(count)
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
        tagName.font = WPStyleGuide.tableviewTextFont()
    }

    private func customizeTagCount() {
        tagCount.font = WPStyleGuide.tableviewTextFont()
        tagCount.textColor = WPStyleGuide.grey()
        tagCount.textAlignment = .right
        tagCount.text = ""
    }

    override func prepareForReuse() {
        tagName.text = ""
        tagCount.text = ""
    }    
}
