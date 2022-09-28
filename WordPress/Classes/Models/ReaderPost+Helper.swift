import Foundation

extension ReaderPost {

    /// Find cached comment with given ID.
    ///
    /// - Parameter id: The comment id
    /// - Returns: The `Comment` object associated with the given id.
    @objc
    func comment(withID id: NSNumber) -> Comment? {
        comment(withID: id.int32Value)
    }

    /// Find cached comment with given ID.
    ///
    /// - Parameter id: The comment id
    /// - Returns: The `Comment` object associated with the given id.
    func comment(withID id: Int32) -> Comment? {
        return (comments as? Set<Comment>)?.first { $0.commentID == id }
    }

}
