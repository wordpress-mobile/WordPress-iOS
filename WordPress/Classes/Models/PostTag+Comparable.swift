//
//  PostTag+Comparable.swift
//  WordPress
//
//  Created by Cesar Tardaguila Moro on 2017-11-30.
//  Copyright © 2017 WordPress. All rights reserved.
//


extension PostTag: Comparable {
    public static func <(lhs: PostTag, rhs: PostTag) -> Bool {
        guard let lhsName = lhs.name, let rhsName = rhs.name else {
            return false
        }
        
        return lhsName < rhsName
    }
}
