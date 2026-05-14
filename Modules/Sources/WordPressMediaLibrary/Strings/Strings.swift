import Foundation

enum Strings {
    static let title = NSLocalizedString(
        "mediaLibrary.screen.title",
        value: "Media",
        comment: "Title for the Media Library V2 screen"
    )

    static let empty = NSLocalizedString(
        "mediaLibrary.empty.message",
        value: "No media yet",
        comment: "Message shown when the Media Library has no items"
    )

    static let errorRetry = NSLocalizedString(
        "mediaLibrary.error.retry",
        value: "Try again",
        comment: "Button label to retry loading after an error"
    )

    static let untitled = NSLocalizedString(
        "mediaLibrary.row.untitled",
        value: "(no title)",
        comment: "Placeholder shown for media items with no title"
    )

    static let searchPrompt = NSLocalizedString(
        "mediaLibrary.search.prompt",
        value: "Search media",
        comment: "Prompt for the Media Library search field"
    )

    static let filterAll = NSLocalizedString(
        "mediaLibrary.filter.all",
        value: "All",
        comment: "Title of the no-filter option in the Media Library filter menu"
    )

    static let filterImages = NSLocalizedString(
        "mediaLibrary.filter.images",
        value: "Images",
        comment: "Title of the images filter option in the Media Library filter menu"
    )

    static let filterVideos = NSLocalizedString(
        "mediaLibrary.filter.videos",
        value: "Videos",
        comment: "Title of the videos filter option in the Media Library filter menu"
    )

    static let filterDocuments = NSLocalizedString(
        "mediaLibrary.filter.documents",
        value: "Documents",
        comment: "Title of the documents filter option in the Media Library filter menu"
    )

    static let filterAudio = NSLocalizedString(
        "mediaLibrary.filter.audio",
        value: "Audio",
        comment: "Title of the audio filter option in the Media Library filter menu"
    )

    static let aspectRatioGrid = NSLocalizedString(
        "mediaLibrary.gridMode.aspectRatio",
        value: "Aspect Ratio Grid",
        comment: "Menu option to switch the grid into aspect-ratio mode"
    )

    static let squareGrid = NSLocalizedString(
        "mediaLibrary.gridMode.square",
        value: "Square Grid",
        comment: "Menu option to switch the grid into square (default) mode"
    )

    static let emptyFiltered = NSLocalizedString(
        "mediaLibrary.empty.filtered",
        value: "No media for this filter",
        comment: "Message shown when the Media Library has items but none match the active filter"
    )

    // MARK: - Accessibility labels (V1 parity)

    static let accessibilityLabelImage = NSLocalizedString(
        "mediaLibrary.accessibility.image",
        value: "Image, %1$@",
        comment: "Accessibility label for an image cell. %1$@ is the creation date."
    )

    static let accessibilityLabelVideo = NSLocalizedString(
        "mediaLibrary.accessibility.video",
        value: "Video, %1$@",
        comment: "Accessibility label for a video cell. %1$@ is the creation date."
    )

    static let accessibilityLabelAudio = NSLocalizedString(
        "mediaLibrary.accessibility.audio",
        value: "Audio, %1$@",
        comment: "Accessibility label for an audio cell. %1$@ is the creation date."
    )

    static let accessibilityLabelDocument = NSLocalizedString(
        "mediaLibrary.accessibility.document",
        value: "Document, %1$@",
        comment:
            "Accessibility label for a document cell. %1$@ is the filename, or the creation date if filename can't be derived."
    )

    static let accessibilityLoadingMedia = NSLocalizedString(
        "mediaLibrary.accessibility.loading",
        value: "Loading media",
        comment: "Accessibility label for a cell that is still loading its data"
    )

    static let accessibilityErrorMedia = NSLocalizedString(
        "mediaLibrary.accessibility.error",
        value: "Media failed to load",
        comment: "Accessibility label for a cell whose underlying media couldn't be loaded"
    )
}
