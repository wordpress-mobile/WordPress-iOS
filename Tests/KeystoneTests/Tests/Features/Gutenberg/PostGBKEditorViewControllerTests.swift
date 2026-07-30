import Foundation
import GutenbergKit
import Testing
import UIKit

@testable import WordPress
@testable import WordPressData

@MainActor
struct PostGBKEditorViewControllerTests {

    @Test("presents the site media library for GutenbergKit requests")
    func presentsSiteMediaLibrary() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
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
}
