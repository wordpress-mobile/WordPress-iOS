import Foundation

final class PageMenuViewModel: AbstractPostMenuViewModel {

    private let page: Page
    private let homepageType: HomepageType?
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

    init(
        page: Page,
        homepageType: HomepageType?,
        isJetpackFeaturesEnabled: Bool = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
        isBlazeFlagEnabled: Bool = BlazeHelper.isBlazeFlagEnabled()
    ) {
        self.page = page
        self.homepageType = homepageType
        self.isJetpackFeaturesEnabled = isJetpackFeaturesEnabled
        self.isBlazeFlagEnabled = isBlazeFlagEnabled
    }

    private func createPrimarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if !page.isFailed {
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

        buttons.append(.setParent)

        if let homepageType, homepageType == .page {
            if !page.isSiteHomepage {
                buttons.append(.setHomepage)
            }
            if !page.isSitePostsPage {
                buttons.append(.setPostsPage)
            }
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createTrashSection() -> AbstractPostButtonSection {
        return AbstractPostButtonSection(buttons: [.trash])
    }
}
