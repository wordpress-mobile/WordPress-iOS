import CoreData
import Testing

@testable import WordPressData

/// Covers the three `performQuery` overloads after moving the background
/// overloads onto `CoreDataStackSwift` and implementing all three on
/// `ContextManager`.
@Suite struct PerformQueryTests {

    private struct SampleError: Error, Equatable {
        let value = UUID()
    }

    // MARK: - Context selection

    @Test func nonthrowingQueryReadsMainContextIncludingUnsavedChanges() {
        let manager = ContextManager.forTesting()
        manager.mainContext.performAndWait {
            _ = WPAccount.fixture(context: manager.mainContext, userID: 7, username: "Unsaved")
        }

        // A nonthrowing closure selects the synchronous `mainContext` overload.
        let username: String? = manager.performQuery { context in
            (try? WPAccount.lookup(withUserID: 7, in: context))?.username
        }

        #expect(username == "Unsaved")
    }

    // A synchronous test so a throwing closure selects the synchronous
    // background overload; an async context would prefer the async overload.
    @Test func throwingSyncQueryReadsSavedStoreAndIgnoresUnsavedMainContext() throws {
        let manager = ContextManager.forTesting()
        manager.performAndSave { context in
            _ = WPAccount.fixture(context: context, userID: 1, username: "Saved")
        }
        // An unsaved change that only exists in the main context.
        manager.mainContext.performAndWait {
            _ = WPAccount.fixture(context: manager.mainContext, userID: 2, username: "UnsavedOnly")
        }

        // A throwing closure selects the background overload, which reads a fresh context.
        let usernames: [String] = try manager.performQuery { context in
            try WPAccount.lookupAllAccounts(in: context).map(\.username)
        }

        #expect(usernames.contains("Saved"))
        #expect(!usernames.contains("UnsavedOnly"))
    }

    @Test func asyncQueryReadsSavedStore() async throws {
        let manager = ContextManager.forTesting()
        try await manager.performAndSave { context in
            _ = WPAccount.fixture(context: context, userID: 1, username: "Saved")
        }

        let count = try await manager.performQuery { context in
            try WPAccount.lookupNumberOfAccounts(in: context)
        }

        #expect(count == 1)
    }

    // MARK: - No automatic saves

    @Test func syncBackgroundQueryDoesNotPersistMutations() throws {
        let manager = ContextManager.forTesting()

        // A successful closure inserts into its fresh context but never saves.
        let visibleWithinClosure = try manager.performQuery { context -> Int in
            _ = WPAccount.fixture(context: context, userID: 1, username: "Ephemeral")
            return try WPAccount.lookupNumberOfAccounts(in: context)
        }
        #expect(visibleWithinClosure == 1)

        // A throwing closure's mutations are likewise discarded.
        let thrown = SampleError()
        #expect(throws: SampleError.self) {
            try manager.performQuery { context -> Int in
                _ = WPAccount.fixture(context: context, userID: 2, username: "Discarded")
                throw thrown
            }
        }

        // A separate query sees an empty store: neither insert leaked or persisted.
        let persisted = try manager.performQuery { context in
            try WPAccount.lookupNumberOfAccounts(in: context)
        }
        #expect(persisted == 0)
    }

    @Test func asyncBackgroundQueryDoesNotPersistMutations() async throws {
        let manager = ContextManager.forTesting()

        _ = try await manager.performQuery { context -> Int in
            _ = WPAccount.fixture(context: context, userID: 1, username: "Ephemeral")
            return try WPAccount.lookupNumberOfAccounts(in: context)
        }

        let persisted = try await manager.performQuery { context in
            try WPAccount.lookupNumberOfAccounts(in: context)
        }
        #expect(persisted == 0)
    }

    // MARK: - Return values and error propagation

    @Test func syncBackgroundQueryReturnsValueAndRethrowsOriginalError() throws {
        let manager = ContextManager.forTesting()

        let value = try manager.performQuery { context -> Int in
            _ = try WPAccount.lookupNumberOfAccounts(in: context)
            return 42
        }
        #expect(value == 42)

        let thrown = SampleError()
        do {
            _ = try manager.performQuery { _ -> Int in throw thrown }
            Issue.record("performQuery should rethrow the closure's error")
        } catch let error as SampleError {
            #expect(error == thrown)
        }
    }

    @Test func asyncBackgroundQueryReturnsValueAndRethrowsOriginalError() async throws {
        let manager = ContextManager.forTesting()

        let value = try await manager.performQuery { context -> Int in
            _ = try WPAccount.lookupNumberOfAccounts(in: context)
            return 42
        }
        #expect(value == 42)

        let thrown = SampleError()
        do {
            _ = try await manager.performQuery { _ -> Int in throw thrown }
            Issue.record("performQuery should rethrow the closure's error")
        } catch let error as SampleError {
            #expect(error == thrown)
        }
    }

    // MARK: - rethrows

    @Test func asyncQueryAcceptsNonthrowingClosureWithoutTry() async {
        let manager = ContextManager.forTesting()
        // No `try`: a nonthrowing closure keeps the `async rethrows` call nonthrowing.
        let value = await manager.performQuery { _ in 7 }
        #expect(value == 7)
    }

    // MARK: - Dispatch consistency

    @Test func nonthrowingQueryIsConsistentAcrossReceiverTypes() {
        let manager = ContextManager.forTesting()
        manager.mainContext.performAndWait {
            _ = WPAccount.fixture(context: manager.mainContext, userID: 5, username: "Main")
        }

        let concrete = manager.performQuery { $0.countObjects(ofType: WPAccount.self) }
        let swiftTyped: CoreDataStackSwift = manager
        let viaSwift = swiftTyped.performQuery { $0.countObjects(ofType: WPAccount.self) }
        // The base protocol retains the synchronous nonthrowing convenience.
        let base: CoreDataStack = manager
        let viaBase = base.performQuery { $0.countObjects(ofType: WPAccount.self) }

        #expect(concrete == 1)
        #expect(viaSwift == 1)
        #expect(viaBase == 1)
    }

    @Test func backgroundQueryIsConsistentForConcreteAndProtocolReceivers() async throws {
        let manager = ContextManager.forTesting()
        try await manager.performAndSave { context in
            _ = WPAccount.fixture(context: context, userID: 1, username: "Saved")
        }
        let swiftTyped: CoreDataStackSwift = manager

        let viaConcrete = try await manager.performQuery { context in
            try WPAccount.lookupNumberOfAccounts(in: context)
        }
        let viaProtocol = try await swiftTyped.performQuery { context in
            try WPAccount.lookupNumberOfAccounts(in: context)
        }

        #expect(viaConcrete == 1)
        #expect(viaProtocol == 1)
    }
}
