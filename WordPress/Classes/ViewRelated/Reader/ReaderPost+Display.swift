
extension ReaderPost {

    var isCommentsEnabled: Bool {
        let usesWPComAPI = isWPCom() || isJetpack()
        let commentCount = commentCount()?.intValue ?? 0
        let hasComments = commentCount > 0

        return usesWPComAPI && (commentsOpen() || hasComments)
    }

    func isLikesEnabled(isLoggedIn: Bool) -> Bool {
        let likeCount = likeCount()?.intValue ?? 0
        return !isExternal() && (likeCount > 0 || isLoggedIn)
    }

    func shortDateForDisplay() -> String? {
        let isRTL = UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft
        guard let date = dateForDisplay()?.toShortString() else {
            return nil
        }
        let postDateFormat = isRTL ? "%@ •" : "• %@"
        return blogNameForDisplay() != nil ? String(format: postDateFormat, date) : date
    }

    func summaryForDisplay(isPad: Bool = false) -> String? {
        if isPad {
            let content = contentForDisplay()?
                .stringByDecodingXMLCharacters()
                .replacingOccurrences(of: "<br>", with: "\n")
                .strippingHTML()
                .replacingOccurrences(of: "^\n+", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\n{2,}", with: "\n\n", options: .regularExpression)
                .trim()
            if let content {
                let maxContentLength = 3000
                return String(content.prefix(maxContentLength))
            }
        }
        return contentPreviewForDisplay()
    }

}
