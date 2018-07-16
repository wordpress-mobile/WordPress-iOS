
class ActivityCommentRange: ActivityRange {
    let commentID: Int
    let postID: Int
    let siteID: Int

    init(range: NSRange, siteID: Int, postID: Int, commentID: Int, url: URL) {
        self.commentID = commentID
        self.postID = postID
        self.siteID = siteID
        super.init(kind: .comment, range: range, url: url)
    }
}
