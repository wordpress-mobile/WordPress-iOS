//
//  TimezoneInfo+CoreDataClass.swift
//  WordPress
//
//  Created by Asif on 17/11/17.
//  Copyright © 2017 WordPress. All rights reserved.
//
//

import Foundation
import CoreData

@objc open class TimezoneInfo: NSManagedObject {

    @NSManaged public var label: String
    @NSManaged public var continent: String
    @NSManaged public var value: String

}
