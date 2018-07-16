
class ActivityPostRange: ActivityRange {
    let postID: Int
    let siteID: Int

    init(range: NSRange, siteID: Int, postID: Int) {
        self.postID = postID
        self.siteID = siteID

        let url = ActivityPostRange.urlWith(siteID: siteID, postID: postID)
        super.init(kind: .post, range: range, url: url)
    }

    private static func urlWith(siteID: Int, postID: Int) -> URL? {
        let urlString = "https://wordpress.com/read/blogs/\(siteID)/posts/\(postID)"
        return URL(string: urlString)
    }
}
