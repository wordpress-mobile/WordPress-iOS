import Foundation

final class PageMenuViewModel: AbstractPostMenuViewModel {

    private let page: Page
    private let isSiteHomepage: Bool
    private let isSitePostsPage: Bool
    private let isJetpackFeaturesEnabled: Bool
    private let isBlazeFlagEnabled: Bool

    var buttonSections: [AbstractPostButtonSection] {
        [
            createPrimarySection(),
            createSetPageAttributesSection(),
            createNavigationSection(),
            createTrashSection(),
            createUploadStatusSection()
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
        isBlazeFlagEnabled: Bool = BlazeHelper.isBlazeFlagEnabled()
    ) {
        self.page = page
        self.isSiteHomepage = isSiteHomepage
        self.isSitePostsPage = isSitePostsPage
        self.isJetpackFeaturesEnabled = isJetpackFeaturesEnabled
        self.isBlazeFlagEnabled = isBlazeFlagEnabled
    }

    private func createPrimarySection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if page.status != .trash {
            buttons.append(.view)
        }

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

        return AbstractPostButtonSection(buttons: buttons)
    }

    private var canPublish: Bool {
        let userCanPublish = page.blog.capabilities != nil ? page.blog.isPublishingPostsAllowed() : true
        return page.isStatus(in: [.draft, .pending]) && userCanPublish
    }

    private func createSetPageAttributesSection() -> AbstractPostButtonSection {
        var buttons = [AbstractPostButton]()

        if isBlazeFlagEnabled && page.canBlaze {
            BlazeEventsTracker.trackEntryPointDisplayed(for: .pagesList)
            buttons.append(.blaze)
        }

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

    private func createUploadStatusSection() -> AbstractPostButtonSection {
        guard let error = PostCoordinator.shared.syncError(for: page.original()) else {
            return AbstractPostButtonSection(buttons: [])
        }
        return AbstractPostButtonSection(title: error.localizedDescription, buttons: [.retry])
    }
}
