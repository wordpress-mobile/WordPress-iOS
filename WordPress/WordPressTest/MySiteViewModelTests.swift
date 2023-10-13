import Nimble
@testable import WordPress
import XCTest

class MySiteViewModelTests: CoreDataTestCase {

    /// When the given blog is not accessible via WordPress.com,
    /// the section is always .siteMenu, regardless of the other inputs
    func testGetSection_notAccessibleViaWPCom_alwaysSiteMenu() {
        let viewModel = MySiteViewModel(coreDataStack: contextManager)
        let blogNotAccessibleThroughWPCom = BlogBuilder(contextManager.mainContext).build()
        // Make sure the default blog is not accessible via WordPress.com
        expect(blogNotAccessibleThroughWPCom.isAccessibleThroughWPCom()) == false

        // If the blog is not accessible via WordPress.com, then section is always .siteMenu
        TruthTable.threeValues.forEach {
            let section = viewModel.getSection(
                for: blogNotAccessibleThroughWPCom,
                jetpackFeaturesEnabled: $0,
                splitViewControllerIsHorizontallyCompact: $1,
                isSplitViewEnabled: $2
            )
            expect(section).to(equal(.siteMenu), description: "Expected .siteMenu, got \(section). Jetpack features \($0), split VC \($1), split view \($2)")
        }
    }

    /// When the given blog is accessible via WordPress.com,
    /// but Jetpack features are disabled,
    /// the section is always .siteMenu, regardless of the other inputs
    func testGetSection_accessibleViaWPCom_noJetpack() {
        let viewModel = MySiteViewModel(coreDataStack: contextManager)
        let blog = makeBlogAccessibleThroughWPCom()

        TruthTable.twoValues.forEach {
            let section = viewModel.getSection(
                for: blog,
                jetpackFeaturesEnabled: false,
                splitViewControllerIsHorizontallyCompact: $0,
                isSplitViewEnabled: $1
            )
            expect(section).to(equal(.siteMenu), description: "Expected .siteMenu, got \(section). split VC \($0), split view \($1)")
        }
    }

    /// When the given blog is accessible via WordPress.com,
    /// and Jetpack features are enabled,
    /// and split view controller is horizontally compact
    /// the section is dashboard regardless of the split view enabled value
    func testGetSection_accessibleViaWPCom_horizontallyCompact() {
        let viewModel = MySiteViewModel(coreDataStack: contextManager)
        let blog = makeBlogAccessibleThroughWPCom()

        expect(
            viewModel.getSection(
                for: blog,
                jetpackFeaturesEnabled: true,
                splitViewControllerIsHorizontallyCompact: true,
                isSplitViewEnabled: true
            )
        ) == .dashboard
        expect(
            viewModel.getSection(
                for: blog,
                jetpackFeaturesEnabled: true,
                splitViewControllerIsHorizontallyCompact: true,
                isSplitViewEnabled: false
            )
        ) == .dashboard
    }

    /// When the given blog is accessible via WordPress.com,
    /// and Jetpack features are enabled,
    /// and split view controller is not horizontally compact
    /// the section is dashboard if split view enabled
    func testGetSection_accessibleViaWPCom_splitViewEnabled() {
        let viewModel = MySiteViewModel(coreDataStack: contextManager)
        let blog = makeBlogAccessibleThroughWPCom()

        expect(
            viewModel.getSection(
                for: blog,
                jetpackFeaturesEnabled: true,
                splitViewControllerIsHorizontallyCompact: false,
                isSplitViewEnabled: true
            )
        ) == .siteMenu

        expect(
            viewModel.getSection(
                for: blog,
                jetpackFeaturesEnabled: true,
                splitViewControllerIsHorizontallyCompact: false,
                isSplitViewEnabled: false
            )
        ) == .dashboard
    }

    func makeBlogAccessibleThroughWPCom(file: StaticString = #file, line: UInt = #line) -> Blog {
        let blog = BlogBuilder(contextManager.mainContext).build()
        let account = AccountBuilder(contextManager)
            // username needs to be set for the token to be registered
            .with(username: "username")
            .with(authToken: "token")
            .with(blogs: [blog])
            .build()

        expect(file: file, line: line, account.wordPressComRestApi).toNot(beNil())
        expect(file: file, line: line, blog.isAccessibleThroughWPCom()) == true

        return blog
    }
}
