import Foundation
import GutenbergKit
import Testing
import UIKit

@testable import WordPress
@testable import WordPressData

/// Keeps every editor these tests build alive for the lifetime of the process.
///
/// `viewDidLoad` starts the editor's load on a `Task` that reaches
/// `startUploadServer()` after the test method returns, where GutenbergKit
/// asserts an assigned `mediaUploadDelegate` is still alive. Tripping that
/// precondition crashes the test host, killing every concurrently running suite
/// — so the damage is not contained to this file.
///
/// Only a test can reach that state. `PostGBKEditorViewController` holds the
/// editor and its `GBKMediaUploadProcessor` as strong `let`s on one object, so
/// in the app they always die together and the load's `[weak self]` is already
/// nil. Here a window is the controller's only owner, so releasing it mid-load
/// leaves the editor reachable with a dead delegate.
///
/// Retention must outlive the *suite instance*: Swift Testing builds a fresh
/// one per test, so an instance property dies at the very deadline being
/// missed. The race is timing-dependent, so a green run does not prove the
/// hazard is gone.
@MainActor
private enum RetainedEditors {
    static var windows: [UIWindow] = []
}

@MainActor
@Suite(.serialized)
struct PostGBKEditorViewControllerTests {

    /// Builds an editor, retaining it for the process's lifetime so the load it
    /// starts cannot outlive its delegate. See ``RetainedEditors``.
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
        RetainedEditors.windows.append(window)
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
