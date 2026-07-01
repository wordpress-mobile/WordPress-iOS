import Foundation
import JetpackSocial
import Testing
@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("PostSettingsViewModel Tests")
struct PostSettingsViewModelTests {
    @Test("publish settings preserve publishing fields and strip the social draft when no connections service")
    func publishSettingsPreservePublishingFieldsAndStripDraftWithoutConnectionsService() {
        let context = ContextManager.forTesting().mainContext
        // A plain blog has no WP.com account, so it isn't Publicize-eligible and
        // the view model resolves no connections service. The draft is therefore
        // stripped (the strip is driven by the missing service, not the status).
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).drafted().build()
        let viewModel = PostSettingsViewModel(post: post, context: .publishing)
        let publishDate = Date(timeIntervalSince1970: 2_000)

        viewModel.settings.status = .publishPrivate
        viewModel.settings.password = "secret"
        viewModel.settings.publishDate = publishDate
        viewModel.settings.socialSharingDraft = PostSocialSharingDraft(customMessage: "Message")

        let settings = viewModel.getSettingsToPublish(for: viewModel.settings)

        #expect(settings.status == .publishPrivate)
        #expect(settings.password == "secret")
        #expect(settings.publishDate == publishDate)
        #expect(settings.socialSharingDraft == nil)
    }

    @Test("a private post keeps its social draft so disabled connections survive being made public")
    func privateEligiblePostKeepsSocialDraft() {
        let context = ContextManager.forTesting().mainContext
        // Publicize-eligible blog: WP.com-hosted, with an account and publish
        // capability, so the view model resolves a connections service.
        let blog = BlogBuilder(context)
            .isHostedAtWPcom()
            .withAnAccount()
            .with(capabilities: [.publishPosts])
            .build()
        let post = PostBuilder(context, blog: blog).drafted().build()
        let viewModel = PostSettingsViewModel(post: post, context: .publishing)

        let draft = PostSocialSharingDraft(connectionsByID: ["123": .init(id: "123", enabled: false)])
        viewModel.settings.status = .publishPrivate
        viewModel.settings.socialSharingDraft = draft

        // The draft is retained for a private post: private posts aren't publicized,
        // but the disabled connection must survive in case the post is later made public.
        #expect(viewModel.getSettingsToPublish(for: viewModel.settings).socialSharingDraft == draft)
    }
}
