//
//  PostTagSettingsCell.swift
//  WordPress
//
//  Created by Cesar Tardaguila Moro on 2017-12-04.
//  Copyright © 2017 WordPress. All rights reserved.
//

import Foundation
final class PostTagSettingsCell: WPTableViewCellBadge {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value2, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.accessoryType = .disclosureIndicator
    }
}
