import Foundation

final class PageMenuViewModel: AbstractPostMenuViewModel {

    private let page: Page
    private let isSiteHomepage: Bool
    private let isSitePostsPage: Bool
    private let isJetpackFeaturesEnabled: Bool
    private let isBlazeFlagEnabled: Bool
    private let isSyncPublishingEnabled: Bool

    var buttonSections: [AbstractPostButtonSection] {
        [
            createPrimarySection(),
            createSecondarySection(),
            createBlazeSection(),
            createSetPageAttributesSection(),
            createNavigationSection(),
            createTrashSection()
        ]
    }

    convenience init(page: Page) {
        self.init(page: page, isSiteHomepage: page.isSiteHomepage, isSitePostsPage: page.isSitePostsPage)
    }

    init(
        page: Page,
        isSiteHomepage: Bool,
        isSitePostsPage: Bool,
        isJetpackFeaturesEnabled: Bool = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
        isBlazeFlagEnabled: Bool = BlazeHelper.isBlazeFlagEnabled(),
        isSyncPublishingEnabled: Bool = FeatureFlag.syncPublishing.enabled
    ) {
        self.page = page
        self.isSiteHomepage = isSiteHomepage
        self.isSitePostsPage = isSitePostsPage
        self.isJetpackFeaturesEnabled = isJetpackFeaturesEnabled
        self.isBlazeFlagEnabled = isBlazeFlagEnabled
        self.isSyncPublishingEnabled = isSyncPublishingEnabled
    }

    private func createPrimarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isSyncPublishingEnabled {
            if page.status != .trash {
                buttons.append(.view)
            }
        } else {
            if !page.isFailed && page.status != .trash {
                buttons.append(.view)
            }
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createSecondarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if canPublish {
            buttons.append(.publish)
        }

        if page.status != .draft && !isSiteHomepage {
            buttons.append(.moveToDraft)
        }

        if page.status == .publish || page.status == .draft {
            buttons.append(.duplicate)
        }

        if page.status == .publish && page.hasRemote() {
            buttons.append(.share)
        }

        if !isSyncPublishingEnabled {
            if page.status != .trash && page.isFailed {
                buttons.append(.retry)
            }
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private var canPublish: Bool {
        guard isSyncPublishingEnabled else {
            return !page.isFailed && page.status != .publish && page.status != .trash
        }
        let userCanPublish = page.blog.capabilities != nil ? page.blog.isPublishingPostsAllowed() : true
        return page.isStatus(in: [.draft, .pending]) && userCanPublish
    }

    private func createBlazeSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isBlazeFlagEnabled && page.canBlaze {
            BlazeEventsTracker.trackEntryPointDisplayed(for: .pagesList)
            buttons.append(.blaze)
        }

        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createSetPageAttributesSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        guard page.status != .trash else {
            return AbstractPostButtonSection(buttons: buttons)
        }

        guard page.status == .publish else {
            return AbstractPostButtonSection(buttons: buttons)
        }

        if !isSiteHomepage {
            buttons.append(.setHomepage)
        }

        if !isSitePostsPage {
            buttons.append(.setPostsPage)
        } else {
            buttons.append(.setRegularPage)
        }
        return AbstractPostButtonSection(buttons: buttons, submenuButton: .pageAttributes)
    }

    private func createNavigationSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()
        if isJetpackFeaturesEnabled, page.status == .publish && page.hasRemote() {
            buttons.append(.stats)
        }
        if page.status != .trash {
            buttons.append(.settings)
        }
        return AbstractPostButtonSection(buttons: buttons)
    }

    private func createTrashSection() -> AbstractPostButtonSection {
        guard !isSiteHomepage else {
            return AbstractPostButtonSection(buttons: [])
        }

        let action: AbstractPostButton = page.original().status == .trash ? .delete : .trash
        return AbstractPostButtonSection(buttons: [action])
    }
}
