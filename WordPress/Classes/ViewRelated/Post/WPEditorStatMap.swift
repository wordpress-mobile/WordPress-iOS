import WordPressEditor
import WordPressShared

class WPEditorStatMap: NSObject {
    class func map(_ stat: WPEditorStat) -> WPAnalyticsStat {
        switch stat {
        case .tappedBlockquote:
            return .editorTappedBlockquote
        case .tappedBold:
            return .editorTappedBold
        case .tappedHTML:
            return .editorTappedHTML
        case .tappedImage:
            return .editorTappedImage
        case .tappedItalic:
            return .editorTappedItalic
        case .tappedLink:
            return .editorTappedLink
        case .tappedMore:
            return .editorTappedMore
        case .tappedOrderedList:
            return .editorTappedOrderedList
        case .tappedStrikethrough:
            return .editorTappedStrikethrough
        case .tappedUnderline:
            return .editorTappedUnderline
        case .tappedUnlink:
            return .editorTappedUnlink
        case .tappedUnorderedList:
            return .editorTappedUnorderedList
        }
    }
}
