import Foundation

enum ReaderSaveForLaterOrigin {
    case savedStream
    case otherStream
    case postDetail
    case readerMenu

    fileprivate var saveActionValue: String {
        switch self {
        case .savedStream:
            return "saved_post_list"
        case .otherStream:
            return "other_post_list"
        case .postDetail:
            return "post_details"
        case .readerMenu:
            return ""
        }
    }
}


private let readerSaveForLaterSourceKey = "source"

extension ReaderSaveForLaterAction {
    func trackSaveAction(for post: ReaderPost, origin: ReaderSaveForLaterOrigin) {
        let willSave = (post.isSavedForLater == false)

        let properties = [ readerSaveForLaterSourceKey: origin.saveActionValue ]

        if willSave {
            WPAppAnalytics.track(.readerPostSaved, withProperties: properties)
        } else {
            WPAppAnalytics.track(.readerPostUnsaved, withProperties: properties)
        }
    }
}
