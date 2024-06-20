import Foundation
@testable import WordPressKit

struct MockServiceRequest: ServiceRequest {
    var path: String {
        return "localhost/path/"
    }

    var apiVersion: WordPressComRESTAPIVersion {
        return ._1_2
    }
}
