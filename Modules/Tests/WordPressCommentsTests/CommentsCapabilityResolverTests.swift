import Testing
@testable import WordPressComments

@MainActor
struct CommentsCapabilityResolverTests {
    @Test func resolveCachesASuccessfulLookup() async {
        let capabilities = FakeCommentsCapabilities()
        capabilities.canModerate = false
        let resolver = CommentsCapabilityResolver(capabilities: capabilities)
        #expect(resolver.canModerate == nil)

        #expect(await resolver.resolve() == false)
        #expect(await resolver.resolve() == false)

        #expect(resolver.canModerate == false)
        #expect(capabilities.invocations == 1)
    }

    @Test func concurrentResolvesShareOneLookup() async {
        let capabilities = FakeCommentsCapabilities()
        let resolver = CommentsCapabilityResolver(capabilities: capabilities)

        async let first = resolver.resolve()
        async let second = resolver.resolve()
        let results = await [first, second]

        #expect(results == [true, true])
        #expect(capabilities.invocations == 1)
    }

    @Test func prefetchStartsOneLookupThatResolveAwaits() async {
        let capabilities = FakeCommentsCapabilities()
        let resolver = CommentsCapabilityResolver(capabilities: capabilities)

        resolver.prefetch()
        resolver.prefetch()
        #expect(await resolver.resolve() == true)

        #expect(capabilities.invocations == 1)
        // Known: a later prefetch is a no-op.
        resolver.prefetch()
        #expect(capabilities.invocations == 1)
    }

    @Test func failedLookupIsNotCachedAndRetries() async {
        let capabilities = FakeCommentsCapabilities()
        capabilities.error = FakeServiceError()
        let resolver = CommentsCapabilityResolver(capabilities: capabilities)

        #expect(await resolver.resolve() == nil)
        #expect(resolver.canModerate == nil)

        capabilities.error = nil
        #expect(await resolver.resolve() == true)
        #expect(capabilities.invocations == 2)
    }
}
