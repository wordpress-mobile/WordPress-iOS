import Foundation

extension AbstractPost {

    var canBlaze: Bool {
        return blog.canBlaze && status == .publish && password == nil
    }
}
