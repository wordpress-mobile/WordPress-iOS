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

    // MARK: - Upload fallback display names

    static let uploadFallbackPhotoName = NSLocalizedString(
        "mediaLibrary.upload.fallback.photo",
        value: "Photo",
        comment: "Display name used when a picked photo has no source filename."
    )
    static let uploadFallbackCameraImageName = NSLocalizedString(
        "mediaLibrary.upload.fallback.cameraImage",
        value: "Camera photo",
        comment: "Display name used for camera-captured photos in the Uploads queue."
    )
    static let uploadFallbackCameraVideoName = NSLocalizedString(
        "mediaLibrary.upload.fallback.cameraVideo",
        value: "Camera video",
        comment: "Display name used for camera-captured videos in the Uploads queue."
    )
    static let defaultExternalMediaStem = NSLocalizedString(
        "mediaLibrary.externalMedia.defaultStem",
        value: "External Media",
        comment:
            "Fallback filename stem for external media when the picker provides no usable name"
    )

    // MARK: - Upload banner and uploads screen

    static let uploadBannerUploadingOnlySingle = NSLocalizedString(
        "mediaLibrary.upload.banner.uploadingOnly.single",
        value: "Uploading %1$d item",
        comment: "Banner shown above the grid while a single upload is in flight. %1$d is the count (1)."
    )
    static let uploadBannerUploadingOnly = NSLocalizedString(
        "mediaLibrary.upload.banner.uploadingOnly",
        value: "Uploading %1$d items",
        comment: "Banner shown above the grid while uploads are in flight. %1$d is the count."
    )
    static let uploadBannerMixed = NSLocalizedString(
        "mediaLibrary.upload.banner.mixed",
        value: "Uploading %1$d · %2$d failed",
        comment: "Banner shown when both pending and failed uploads exist. %1$d pending, %2$d failed."
    )
    static let uploadBannerFailedOnlySingle = NSLocalizedString(
        "mediaLibrary.upload.banner.failedOnly.single",
        value: "%1$d upload failed",
        comment: "Banner shown when a single failed upload remains. %1$d is the count (1)."
    )
    static let uploadBannerFailedOnly = NSLocalizedString(
        "mediaLibrary.upload.banner.failedOnly",
        value: "%1$d uploads failed",
        comment: "Banner shown when only failed uploads remain. %1$d is the count."
    )
    static let uploadsScreenTitle = NSLocalizedString(
        "mediaLibrary.uploads.title",
        value: "Uploads",
        comment: "Navigation title for the Uploads queue screen."
    )
    static let uploadsScreenAllDone = NSLocalizedString(
        "mediaLibrary.uploads.allDone",
        value: "All uploaded",
        comment: "Empty-state label shown on the Uploads screen after the last item resolves."
    )
    static let uploadsScreenClose = NSLocalizedString(
        "mediaLibrary.uploads.close",
        value: "Close",
        comment: "Button to dismiss the modally-presented Uploads queue screen."
    )
    static let uploadBulkCancelAllConfirm = NSLocalizedString(
        "mediaLibrary.uploads.bulk.cancelAll.confirm",
        value: "Cancel uploads",
        comment: "Destructive button title in the confirmation alert for canceling every in-flight upload."
    )
    static let uploadBulkCancelAllMessage = NSLocalizedString(
        "mediaLibrary.uploads.bulk.cancelAll.message",
        value: "All in-progress uploads will be cancelled. This can't be undone.",
        comment: "Body of the confirmation alert shown before canceling every in-flight upload."
    )
    static let keepUploading = NSLocalizedString(
        "mediaLibrary.uploads.alert.keepUploading",
        value: "Keep uploading",
        comment: "Cancel-the-alert button on the bulk-cancel confirmation dialog. Keeps uploads running."
    )
    static let uploadActionRetry = NSLocalizedString(
        "mediaLibrary.uploads.retry",
        value: "Retry",
        comment: "Per-row action: retry a failed upload."
    )
    static let uploadActionDismiss = NSLocalizedString(
        "mediaLibrary.uploads.dismiss",
        value: "Dismiss",
        comment: "Per-row action: remove a failed upload from the queue."
    )
    static let uploadBulkRetryAll = NSLocalizedString(
        "mediaLibrary.uploads.bulk.retryAll",
        value: "Retry all failed",
        comment: "Bulk action: retry every failed upload."
    )
    static let uploadBulkDismissAll = NSLocalizedString(
        "mediaLibrary.uploads.bulk.dismissAll",
        value: "Dismiss all failed",
        comment: "Bulk action: dismiss every failed upload."
    )
    static let uploadBulkCancelAll = NSLocalizedString(
        "mediaLibrary.uploads.bulk.cancelAll",
        value: "Cancel all uploading",
        comment: "Bulk action: cancel every in-flight upload."
    )

    // MARK: - Add menu

    static let addMenuTitle = NSLocalizedString(
        "mediaLibrary.addMenu.title",
        value: "Add",
        comment: "Accessibility label for the toolbar + button that opens the Add menu."
    )
    static let addMenuPhotoLibrary = NSLocalizedString(
        "mediaLibrary.addMenu.photoLibrary",
        value: "Photo Library",
        comment: "Add-menu item that opens the system photo library picker."
    )
    static let addMenuTakePhoto = NSLocalizedString(
        "mediaLibrary.addMenu.takePhoto",
        value: "Take Photo",
        comment: "Add-menu item that opens the camera in photo mode."
    )
    static let addMenuTakeVideo = NSLocalizedString(
        "mediaLibrary.addMenu.takeVideo",
        value: "Take Video",
        comment: "Add-menu item that opens the camera in video mode."
    )
    static let addMenuChooseFile = NSLocalizedString(
        "mediaLibrary.addMenu.chooseFile",
        value: "Choose File",
        comment: "Add-menu item that opens the system file picker."
    )
}
