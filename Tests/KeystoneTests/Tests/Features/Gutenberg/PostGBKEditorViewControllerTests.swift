import Foundation
import GutenbergKit
import Testing
import UIKit

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite(.serialized)
final class PostGBKEditorViewControllerTests {

    /// Keeps every editor built here alive for the whole suite.
    ///
    /// `viewDidLoad` starts `prepareEditor()` asynchronously, and that work
    /// reaches `startUploadServer()` after the test method has returned. The
    /// editor holds `mediaUploadDelegate` weakly, so if the controller — the
    /// only owner of `PostGBKEditorViewController.mediaUploadProcessor` — is
    /// released at scope exit, the delegate is gone by the time the load
    /// arrives and GutenbergKit trips its "released before the editor loaded"
    /// precondition, crashing the test host and taking every concurrently
    /// running suite with it.
    ///
    /// Production ownership is correct: the controller outlives its own load.
    /// Only the test's scope was shorter than the async work it kicked off.
    private var retainedWindows: [UIWindow] = []

    /// Builds an editor and retains it (via its window) for the suite's lifetime.
    private func makeEditor(blog: Blog) -> PostGBKEditorViewController {
        let viewController = PostGBKEditorViewController(
            postId: nil,
            postType: .post,
            title: "",
            content: "",
            status: "draft",
            blog: blog
        )
        let window = UIWindow()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.loadViewIfNeeded()
        retainedWindows.append(window)
        return viewController
    }

    @Test("presents the site media library for GutenbergKit requests")
    func presentsSiteMediaLibrary() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let viewController = makeEditor(blog: blog)

        let data = Data(
            #"{"allowedTypes":["image"],"multiple":true,"value":[],"contextId":"test"}"#.utf8
        )
        let action = try JSONDecoder().decode(OpenMediaLibraryAction.self, from: data)

        viewController.editor(
            viewController.editorViewController,
            didRequestMediaFromSiteMediaLibrary: action
        )

        let navigation = try #require(viewController.presentedViewController as? UINavigationController)
        #expect(navigation.viewControllers.first is SiteMediaPickerViewController)
    }

    @Test("does not report a selection when the media picker is cancelled")
    func cancellingReportsEmptySelection() throws {
        // `mapMediaIdsToMedia` fetches from `ContextManager.shared.mainContext`, so
        // the blog has to live there for the picker to preselect anything. Without
        // the override the lookup would return nothing and this would assert that an
        // empty selection stays empty, which passes even against the pre-fix code.
        let contextManager = ContextManager.forTesting()
        let original = ContextManager.overrideInstance
        ContextManager.overrideInstance = contextManager
        defer {
            contextManager.mainContext.reset()
            if ContextManager.overrideInstance === contextManager {
                ContextManager.overrideInstance = original
            }
        }

        let context = contextManager.mainContext
        let blog = BlogBuilder(context).build()
        let media = MediaBuilder(context).build()
        media.mediaID = 321
        media.blog = blog

        let picker = try presentSiteMediaPicker(for: blog, requesting: [321])
        picker.loadViewIfNeeded()

        // The picker preselects the gallery's existing media, so this is the
        // state a cancel has to leave alone.
        #expect(try selectedMedia(in: picker).map(\.mediaID) == [321])

        var reported: [Media]?
        let helper = try #require(picker.delegate as? GutenbergMediaPickerHelper)
        helper.didPickMediaCallback = { assets in
            reported = assets as? [Media]
        }

        // Tap the real Cancel button rather than calling the delegate directly,
        // so the assertion covers what `buttonCancelTapped` actually reports.
        let buttonCancel = try #require(picker.navigationItem.leftBarButtonItem)
        let action = try #require(buttonCancel.primaryAction)
        action.performWithSender(nil, target: nil)

        // Cancelling must report an empty selection. Reporting `initialSelection`
        // is indistinguishable from a confirmed selection, and the editor writes
        // whatever it receives back to the block, so any gallery media missing
        // from the local cache would be dropped.
        #expect(reported?.isEmpty == true)
    }

    /// Returns the media the picker has actually preselected.
    ///
    /// Read from the embedded collection view controller, which the picker adds as
    /// a child, so the assertion sees the selection the user would see.
    private func selectedMedia(
        in picker: SiteMediaPickerViewController
    ) throws -> [Media] {
        picker.loadViewIfNeeded()
        let collectionViewController = try #require(
            picker.children.compactMap { $0 as? SiteMediaCollectionViewController }.first
        )
        return collectionViewController.selectedMedia
    }

    /// Drives the GutenbergKit media-library request and returns the picker it presents.
    private func presentSiteMediaPicker(
        for blog: Blog,
        requesting mediaIds: [Int]
    ) throws -> SiteMediaPickerViewController {
        let viewController = makeEditor(blog: blog)

        let value = mediaIds.map(String.init).joined(separator: ",")
        let data = Data(
            #"{"allowedTypes":["image"],"multiple":true,"value":[\#(value)],"contextId":"test"}"#.utf8
        )
        let action = try JSONDecoder().decode(OpenMediaLibraryAction.self, from: data)

        viewController.editor(
            viewController.editorViewController,
            didRequestMediaFromSiteMediaLibrary: action
        )

        let navigation = try #require(viewController.presentedViewController as? UINavigationController)
        return try #require(navigation.viewControllers.first as? SiteMediaPickerViewController)
    }
}
