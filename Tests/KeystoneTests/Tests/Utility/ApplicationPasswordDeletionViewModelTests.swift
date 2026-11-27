import Foundation
import Testing
@testable import WordPress

@MainActor
struct ApplicationPasswordDeletionViewModelTests {
    @Test func successfulDeletionRemovesOnlySelectedUUID() async throws {
        let fixture = Fixture()
        await fixture.model.fetchTokens()
        #expect(try await fixture.model.deleteToken(fixture.other))
        #expect(fixture.provider.deleted == [fixture.other.uuid])
        #expect(fixture.model.applicationTokens.map(\.uuid) == [fixture.current.uuid])
        #expect(fixture.model.deletingTokenID == nil)
    }

    @Test func failureKeepsRowAndAllowsRetry() async throws {
        let fixture = Fixture()
        await fixture.model.fetchTokens()
        fixture.provider.deleteError = URLError(.notConnectedToInternet)
        await #expect(throws: (any Error).self) { try await fixture.model.deleteToken(fixture.other) }
        #expect(fixture.model.applicationTokens.count == 2)
        #expect(fixture.model.deletingTokenID == nil)
        fixture.provider.deleteError = nil
        #expect(try await fixture.model.deleteToken(fixture.other))
    }

    @Test func currentAndUnknownPasswordsNeverReachProvider() async {
        let fixture = Fixture()
        await fixture.model.fetchTokens()
        await #expect(throws: (any Error).self) { try await fixture.model.deleteToken(fixture.current) }
        fixture.model.invalidateCurrentPassword()
        await #expect(throws: (any Error).self) { try await fixture.model.deleteToken(fixture.other) }
        #expect(fixture.provider.deleted.isEmpty)
        #expect(fixture.model.applicationTokens.allSatisfy { !$0.canDelete && !$0.isCurrent })
        #expect(fixture.model.credentialRevision == 1)
    }

    @Test func duplicateDeletionSendsOneRequest() async throws {
        let fixture = Fixture()
        await fixture.model.fetchTokens()
        fixture.provider.suspendDelete = true
        let first = Task { try await fixture.model.deleteToken(fixture.other) }
        await fixture.provider.waitForDelete()
        #expect(fixture.model.deletingTokenID == fixture.other.uuid)
        #expect(try await fixture.model.deleteToken(fixture.other) == false)
        fixture.provider.finishDelete()
        #expect(try await first.value)
        #expect(fixture.provider.deleted.count == 1)
    }

    @Test func staleFetchCannotRestoreDeletedRow() async throws {
        let fixture = Fixture()
        await fixture.model.fetchTokens()
        fixture.provider.suspendLoad = true
        let fetch = Task { await fixture.model.fetchTokens() }
        await fixture.provider.waitForLoad()
        #expect(try await fixture.model.deleteToken(fixture.other))
        fixture.provider.finishLoad()
        await fetch.value
        #expect(fixture.model.applicationTokens.map(\.uuid) == [fixture.current.uuid])
        #expect(!fixture.model.isLoadingData)
    }

    @Test func credentialChangeDiscardsOldFetchAndProtectsRows() async {
        let fixture = Fixture()
        await fixture.model.fetchTokens()
        fixture.provider.suspendLoad = true
        let fetch = Task { await fixture.model.fetchTokens() }
        await fixture.provider.waitForLoad()
        fixture.model.invalidateCurrentPassword()
        fixture.provider.finishLoad()
        await fetch.value
        #expect(fixture.model.applicationTokens.allSatisfy { !$0.canDelete })
    }

    @Test func retryClearsLoadErrorAndRestoresCurrentFirst() async {
        let fixture = Fixture()
        fixture.provider.loadError = URLError(.timedOut)
        await fixture.model.fetchTokens()
        #expect(fixture.model.errorMessage != nil)
        fixture.provider.loadError = nil
        await fixture.model.fetchTokens()
        #expect(fixture.model.errorMessage == nil)
        #expect(fixture.model.applicationTokens.first?.uuid == fixture.current.uuid)
    }
}

@MainActor
private struct Fixture {
    let current: ApplicationTokenItem
    let other: ApplicationTokenItem
    let provider: DeletionProvider
    let model: ApplicationTokenListViewModel

    init() {
        var current = ApplicationTokenItem(
            name: "Same name",
            uuid: UUID(),
            appId: "same-app",
            createdAt: .distantPast,
            lastUsed: nil,
            lastIpAddress: nil
        )
        current.isCurrent = true
        var other = ApplicationTokenItem(
            name: "Same name",
            uuid: UUID(),
            appId: "same-app",
            createdAt: .now,
            lastUsed: .now,
            lastIpAddress: nil
        )
        other.canDelete = true
        self.current = current
        self.other = other
        provider = DeletionProvider(tokens: [other, current])
        model = ApplicationTokenListViewModel(dataProvider: provider)
    }
}

@MainActor
private final class DeletionProvider: ApplicationTokenListDataProvider {
    let tokens: [ApplicationTokenItem]
    var deleted: [UUID] = []
    var deleteError: Error?
    var loadError: Error?
    var suspendDelete = false
    var suspendLoad = false
    private var deleteContinuation: CheckedContinuation<Void, Never>?
    private var loadContinuation: CheckedContinuation<Void, Never>?
    private var deleteStarted: CheckedContinuation<Void, Never>?
    private var loadStarted: CheckedContinuation<Void, Never>?

    init(tokens: [ApplicationTokenItem]) { self.tokens = tokens }

    func loadApplicationTokens() async throws -> [ApplicationTokenItem] {
        if let loadError { throw loadError }
        if suspendLoad {
            await withCheckedContinuation {
                loadContinuation = $0; loadStarted?.resume(); loadStarted = nil
            }
        }
        return tokens
    }

    func deleteApplicationToken(uuid: UUID) async throws {
        deleted.append(uuid)
        if let deleteError { throw deleteError }
        if suspendDelete {
            await withCheckedContinuation {
                deleteContinuation = $0; deleteStarted?.resume(); deleteStarted = nil
            }
        }
    }

    func waitForDelete() async {
        if deleteContinuation == nil { await withCheckedContinuation { deleteStarted = $0 } }
    }
    func waitForLoad() async {
        if loadContinuation == nil { await withCheckedContinuation { loadStarted = $0 } }
    }
    func finishDelete() { deleteContinuation?.resume(); deleteContinuation = nil }
    func finishLoad() { loadContinuation?.resume(); loadContinuation = nil }
}
