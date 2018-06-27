//
//  SubjectContentGroup.swift
//  WordPress
//
//  Created by Eduardo Toledo on 6/27/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import Foundation

class SubjectContentGroup: FormattableContentGroup {
    class func createGroup(from subject: [[String: AnyObject]], parent: FormattableContentParent) -> FormattableContentGroup {
        let blocks = FormattableContent.blocksFromArray(subject, parent: parent)
        return FormattableContentGroup(blocks: blocks)
    }
}
