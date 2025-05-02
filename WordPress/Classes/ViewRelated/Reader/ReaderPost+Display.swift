import Foundation
import WordPressData

extension ReaderPost {

    var isCommentsEnabled: Bool {
        let usesWPComAPI = isWPCom || isJetpack
        let commentCount = commentCount?.intValue ?? 0
        let hasComments = commentCount > 0

        return usesWPComAPI && (commentsOpen || hasComments)
    }
}
