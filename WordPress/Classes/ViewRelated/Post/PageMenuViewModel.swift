import Foundation

final class PageMenuViewModel: AbstractPostMenuViewModel {

    private let page: Page
    private let indexPath: IndexPath
    private let isSiteHomepage: Bool
    private let isSitePostsPage: Bool
    private let isJetpackFeaturesEnabled: Bool
    private let isBlazeFlagEnabled: Bool

    var buttonSections: [AbstractPostButtonSection] {
        [
            createPrimarySection(),
            createSecondarySection(),
            createBlazeSection(),
            createSetPageSection(),
            createTrashSection()
        ]
    }

    convenience init(page: Page, indexPath: IndexPath) {
        self.init(page: page, indexPath: indexPath, isSiteHomepage: page.isSiteHomepage, isSitePostsPage: page.isSitePostsPage)
    }

    init(
        page: Page,
        indexPath: IndexPath,
        isSiteHomepage: Bool,
        isSitePostsPage: Bool,
        isJetpackFeaturesEnabled: Bool = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
        isBlazeFlagEnabled: Bool = BlazeHelper.isBlazeFlagEnabled()
    ) {
        self.page = page
        self.indexPath = indexPath
        self.isSiteHomepage = isSiteHomepage
        self.isSitePostsPage = isSitePostsPage
        self.isJetpackFeaturesEnabled = isJetpackFeaturesEnabled
        self.isBlazeFlagEnabled = isBlazeFlagEnabled
    }

    private func createPrimarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if !page.isFailed && page.status != .trash {
            buttons.append(.view)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createSecondarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if page.status != .draft {
            buttons.append(.moveToDraft)
        }

        if page.status == .publish || page.status == .draft {
            buttons.append(.duplicate)
        }

        if page.status != .trash && page.isFailed {
            buttons.append(.retry)
        }

        if !page.isFailed, page.status != .publish && page.status != .trash {
            buttons.append(.publish)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createBlazeSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isBlazeFlagEnabled && page.canBlaze {
            BlazeEventsTracker.trackEntryPointDisplayed(for: .pagesList)
            buttons.append(.blaze)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createSetPageSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        guard page.status != .trash else {
            return AbstractPostButtonSection(buttons: buttons)
        }

        buttons.append(.setParent(indexPath))

        if page.status == .publish, !isSiteHomepage {
            buttons.append(.setHomepage)
        }

        if page.status == .publish, !isSitePostsPage {
            buttons.append(.setPostsPage)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createTrashSection() -> AbstractPostButtonSection {
        return AbstractPostButtonSection(buttons: [.trash])
    }
}
