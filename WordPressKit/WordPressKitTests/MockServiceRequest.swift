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
