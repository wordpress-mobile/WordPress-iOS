//
//  MockServiceRequest.swift
//  WordPressKitTests
//
//  Created by Daniele Bogo on 17/04/2018.
//  Copyright © 2018 Automattic Inc. All rights reserved.
//

import Foundation
@testable import WordPressKit


struct MockServiceRequest: ServiceRequest {
    var path: String {
        return "localhost/path/"
    }
    
    var apiVersion: ServiceRemoteWordPressComRESTApiVersion {
        return ._1_2
    }
}
