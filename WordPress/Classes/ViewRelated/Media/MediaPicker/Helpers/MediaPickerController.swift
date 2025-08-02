import UIKit
import GutenbergKit
import WordPressData
import WordPressShared

/// A adapter for GutenbergKit that manages media picker sources the editor.
final class MediaPickerController: GutenbergKit.MediaPickerController {
    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
    }

    func getActions(for parameters: MediaPickerParameters) -> [MediaPickerActionGroup] {
        let menu = MediaPickerMenu(
            filter: convertFilter(parameters.filter),
            isMultipleSelectionEnabled: parameters.isMultipleSelectionEnabled
        )

        // Create a temporary controller just to extract action metadata
        let tempController = MediaPickerMenuController()

        // Define media sources with their identifiers
        let sources: [(source: MediaPickerSource, id: MediaPickerID)] = [
            (.siteMedia(blog: blog), .siteMedia),
            (.freePhotos(blog: blog), .freePhotos),
            (.freeGIFs(blog: blog), .freeGIFs)
        ]

        // Create actions from enabled sources
        let actions = sources.compactMap { source, id -> MediaPickerAction? in
            guard source.isEnabled else { return nil }

            let uiAction = createUIAction(for: source, menu: menu, controller: tempController)
            guard let uiAction else { return nil }

            return MediaPickerAction(
                id: id.rawValue,
                title: uiAction.title,
                image: uiAction.image ?? UIImage()
            )
        }

        return [MediaPickerActionGroup(id: "primary", actions: actions)]
            .filter { !$0.actions.isEmpty }
    }

    func perform(_ action: MediaPickerAction, parameters: MediaPickerParameters, from presentingViewController: UIViewController) async -> [MediaInfo] {
        // Find the source for this action
        guard let pickerID = MediaPickerID(rawValue: action.id) else {
            return []
        }

        let source = getSource(for: pickerID)
        guard source.isEnabled else {
            return []
        }

        // Create menu and controller
        let menu = MediaPickerMenu(
            filter: convertFilter(parameters.filter),
            isMultipleSelectionEnabled: parameters.isMultipleSelectionEnabled
        )

        let controller = MediaPickerMenuController()

        // Use continuation to wait for the selection
        return await withCheckedContinuation { continuation in
            controller.onSelection = { [weak self] selection in
                guard let self else {
                    continuation.resume(returning: [])
                    return
                }
                let mediaInfos = self.convertSelectionToMediaInfo(selection)
                continuation.resume(returning: mediaInfos)
            }

            // Create and perform the UIAction
            if let uiAction = createUIAction(for: source, menu: menu, controller: controller) {
                MainActor.assumeIsolated {
                    uiAction.performWithSender(nil, target: nil)
                }
            } else {
                continuation.resume(returning: [])
            }
        }
    }

    // MARK: - Private Methods

    private func getSource(for id: MediaPickerID) -> MediaPickerSource {
        switch id {
        case .imagePlayground: .playground
        case .siteMedia: .siteMedia(blog: blog)
        case .applePhotos: .photos
        case .freePhotos: .freePhotos(blog: blog)
        case .freeGIFs: .freeGIFs(blog: blog)
        default: fatalError("Unsupported: \(id)")
        }
    }

    private func convertFilter(_ filter: MediaPickerParameters.MediaFilter?) -> MediaPickerMenu.MediaFilter? {
        guard let filter else { return nil }
        switch filter {
        case .images: return .images
        case .videos: return .videos
        case .all: return nil
        }
    }

    private func createUIAction(for source: MediaPickerSource, menu: MediaPickerMenu, controller: MediaPickerMenuController) -> UIAction? {
        switch source {
        case .playground: menu.makeImagePlaygroundAction(delegate: controller)
        case .siteMedia: menu.makeSiteMediaAction(blog: blog, delegate: controller)
        case .photos: menu.makePhotosAction(delegate: controller)
        case .freePhotos: menu.makeStockPhotos(blog: blog, delegate: controller)
        case .freeGIFs: menu.makeFreeGIFAction(blog: blog, delegate: controller)
        default: nil
        }
    }

    private func convertSelectionToMediaInfo(_ selection: MediaPickerSelection) -> [MediaInfo] {
        var output: [MediaInfo] = []

        for item in selection.items {
            switch item {
            case .media(let media):
                var metadata: [String: String] = [:]
                if let videopressGUID = media.videopressGUID {
                    metadata["videopressGUID"] = videopressGUID
                }
                let mediaInfo = MediaInfo(
                    id: media.mediaID?.int32Value,
                    url: media.remoteURL,
                    type: media.mimeType,
                    caption: media.caption,
                    title: media.filename,
                    alt: media.alt,
                    metadata: metadata
                )
                output.append(mediaInfo)

            case .external(let asset):
                let mediaInfo = MediaInfo(
                    id: nil,
                    url: asset.largeURL.absoluteString,
                    type: asset.largeURL.preferredMimeType,
                    caption: asset.caption,
                    title: asset.name,
                    alt: nil,
                    metadata: [:]
                )
                output.append(mediaInfo)

            case .image, .pickerResult:
                wpAssertionFailure("unused case")
                break
            }
        }

        return output
    }
}

private extension URL {
    var preferredMimeType: String {
        if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }
}
