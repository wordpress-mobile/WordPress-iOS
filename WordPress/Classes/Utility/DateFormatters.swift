//
//  DateFormatters.swift
//  WordPress
//
//  Created by Brandon Titus on 12/16/19.
//  Copyright © 2019 WordPress. All rights reserved.
//

import Foundation

struct SiteDateFormatters {

    static func dateFormatter(for timeZone: TimeZone, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.timeZone = timeZone
        return formatter
    }

    static func dateFormatter(for blog: Blog, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, managedObjectContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) -> DateFormatter {
        let blogService = BlogService(managedObjectContext: managedObjectContext)
        let timeZone = blogService.timeZone(for: blog)

        return dateFormatter(for: timeZone, dateStyle: dateStyle, timeStyle: timeStyle)
    }
}
