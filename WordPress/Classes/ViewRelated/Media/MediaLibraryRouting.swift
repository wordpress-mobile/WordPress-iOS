import SwiftUI
import UIKit
import WordPressCore
import WordPressData
import WordPressMediaLibrary

/// Single source of truth for routing into the V2 Media Library. Both V1
/// entry points (BlogDetailsViewController.showMediaLibrary and
/// DashboardQuickActionsCardCell .media case) call this helper. Returns nil
/// when either the FeatureFlag is off or the site can't construct a
/// WordPressSite, so the caller's V1 fall-through is a one-liner.
@MainActor
enum MediaLibraryRouting {
    static func makeViewController(
        for blog: Blog,
        baseAnalyticsProperties: [String: Any]
    ) -> UIViewController? {
        guard FeatureFlag.mediaLibraryV2.enabled,
            let site = try? WordPressSite(blog: blog)
        else {
            return nil
        }
        let client = WordPressClientFactory.shared.instance(for: site)

        // Explicit two-step instead of `.merging(...)`. Reason:
        // `baseAnalyticsProperties` is `[String: Any]`; a `["is_v2": "1"]`
        // literal can infer as `[String: String]` and fail to type-check
        // against the merging overload. Explicit form avoids the gamble.
        var properties = baseAnalyticsProperties
        properties["is_v2"] = "1"
        let tracker = MediaTrackerAdapter(blog: blog, baseProperties: properties)

        let uploader: MediaUploader
        do {
            uploader = try MediaUploaderRegistry.shared.uploader(for: blog)
        } catch {
            Loggers.app.error("Failed to vend uploader: \(error)")
            return nil
        }

        return MediaLibraryHostingController.make(
            client: client,
            tracker: tracker,
            uploader: uploader,
            externalPickerOptions: externalPickerOptions(for: blog)
        )
    }

    /// Internal helper so tests can assert the option array without UI introspection.
    /// Mirrors V1's effective gates from MediaPickerMenu+External.swift.
    static func externalPickerOptions(for blog: Blog) -> [ExternalMediaPickerOption] {
        var options: [ExternalMediaPickerOption] = []

        if MediaPickerSource.freePhotos(blog: blog).isEnabled,
            blog.wordPressComRestApi != nil
        {
            // Capture the blog id, not the api instance: WordPressComRestApi
            // freezes its bearer token at init, so an instance captured at
            // screen creation goes stale if the account re-authenticates
            // while the screen is alive. Resolving at presentation time
            // mirrors V1's tap-time lookup (MediaPickerMenu+External.swift).
            let blogID = TaggedManagedObjectID<Blog>(blog)
            options.append(
                .init(
                    id: "stockPhotos",
                    label: Strings.stockPhotos,
                    systemImage: "photo.on.rectangle",
                    sheetContent: { delegate in
                        guard
                            let blog = try? ContextManager.shared.mainContext.existingObject(with: blogID),
                            let api = blog.wordPressComRestApi
                        else {
                            // A nil api posts the fix-auth-token notification
                            // from the getter itself, which triggers the
                            // re-sign-in flow, so this is not a dead end.
                            return AnyView(EmptyView())
                        }
                        return AnyView(StockPhotosPickerSheet(api: api, delegate: delegate))
                    }
                )
            )
        }
        if MediaPickerSource.playground.isEnabled {
            if #available(iOS 18.1, *) {
                options.append(
                    .init(
                        id: "imagePlayground",
                        label: Strings.imagePlayground,
                        systemImage: "apple.image.playground",
                        sheetContent: { delegate in
                            AnyView(ImagePlaygroundPickerSheet(delegate: delegate))
                        }
                    )
                )
            }
        }
        return options
    }
}

private enum Strings {
    static let stockPhotos = NSLocalizedString(
        "mediaLibrary.v2.addMenu.stockPhotos",
        value: "Free Photo Library",
        comment: "Add-menu item that opens the Stock Photos picker"
    )
    static let imagePlayground = NSLocalizedString(
        "mediaLibrary.v2.addMenu.imagePlayground",
        value: "Image Playground",
        comment: "Add-menu item that opens Apple's Image Playground"
    )
}
