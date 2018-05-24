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

    fileprivate var viewAllPostsValue: String {
        switch self {
        case .savedStream:
            return "post_list_saved_post_notice"
        case .otherStream:
            return "post_list_saved_post_notice"
        case .postDetail:
            return "post_details_saved_post_notice"
        case .readerMenu:
            return "reader_filter"
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

    func trackViewAllSavedPostsAction(origin: ReaderSaveForLaterOrigin) {
        let properties = [ readerSaveForLaterSourceKey: origin.viewAllPostsValue ]

        WPAppAnalytics.track(.readerSavedListViewed, withProperties: properties)
    }
}

extension ReaderMenuViewController {
    func trackSavedPostsNavigation() {
        WPAppAnalytics.track(.readerSavedListViewed, withProperties: [ readerSaveForLaterSourceKey: ReaderSaveForLaterOrigin.readerMenu.viewAllPostsValue ])
    }
}
