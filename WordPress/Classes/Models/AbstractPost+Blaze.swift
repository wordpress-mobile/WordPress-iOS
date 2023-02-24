import Foundation

extension AbstractPost {

    var canBlaze: Bool {
        return blog.isBlazeApproved && status == .publish && password == nil
    }
}
