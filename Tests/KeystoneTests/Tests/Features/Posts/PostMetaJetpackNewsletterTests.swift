import Testing
import Foundation
import WordPressAPIInternal
import WordPressData

@testable import WordPress

struct PostMetaJetpackNewsletterTests {

    // MARK: - Access Level

    @Test("addingJetpackNewsletterAccess round-trips through jetpackNewsletterAccess")
    func accessLevelRoundTrip() {
        let meta = PostMeta().addingJetpackNewsletterAccess(.subscribers)
        #expect(meta.jetpackNewsletterAccess == .subscribers)
    }

    @Test("addingJetpackNewsletterAccess supports paid_subscribers")
    func accessLevelPaidSubscribers() {
        let meta = PostMeta().addingJetpackNewsletterAccess(.paidSubscribers)
        #expect(meta.jetpackNewsletterAccess == .paidSubscribers)
    }

    @Test("addingJetpackNewsletterAccess with nil clears the value")
    func accessLevelClear() {
        let meta = PostMeta()
            .addingJetpackNewsletterAccess(.subscribers)
            .addingJetpackNewsletterAccess(nil)
        #expect(meta.jetpackNewsletterAccess == nil)
    }

    @Test("jetpackNewsletterAccess returns nil when key is absent")
    func accessLevelAbsent() {
        #expect(PostMeta().jetpackNewsletterAccess == nil)
    }

    @Test("jetpackNewsletterAccess returns nil for unknown raw values")
    func accessLevelUnknownRawValue() {
        let meta = PostMeta().withValue(key: "_jetpack_newsletter_access", value: .string("not_a_level"))
        #expect(meta.jetpackNewsletterAccess == nil)
    }

    // MARK: - Email Disabled

    @Test("addingJetpackNewsletterEmailDisabled true round-trips")
    func emailDisabledTrueRoundTrip() {
        let meta = PostMeta().addingJetpackNewsletterEmailDisabled(true)
        #expect(meta.isJetpackNewsletterEmailDisabled)
    }

    @Test("addingJetpackNewsletterEmailDisabled false round-trips")
    func emailDisabledFalseRoundTrip() {
        let meta = PostMeta().addingJetpackNewsletterEmailDisabled(false)
        #expect(!meta.isJetpackNewsletterEmailDisabled)
    }

    @Test("isJetpackNewsletterEmailDisabled returns false when key is absent")
    func emailDisabledAbsent() {
        #expect(!PostMeta().isJetpackNewsletterEmailDisabled)
    }
}
