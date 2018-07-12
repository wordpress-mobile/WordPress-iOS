
class ActivityPostRange: ActivityRange {
    init(range: NSRange, siteID: Int, postID: Int) {
        let url = ActivityPostRange.urlWith(siteID: siteID, postID: postID)
        super.init(kind: .post, range: range, url: url)
    }

    private static func urlWith(siteID: Int, postID: Int) -> URL? {
        let urlString = "https://wordpress.com/read/blogs/\(siteID)/posts/\(postID)"
        return URL(string: urlString)
    }
}
