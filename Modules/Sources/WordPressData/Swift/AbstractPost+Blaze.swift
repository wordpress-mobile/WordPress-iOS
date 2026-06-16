import Foundation

public extension AbstractPost {

    var canBlaze: Bool {
        return blog.canBlaze && status == .publish && password == nil
    }
}
