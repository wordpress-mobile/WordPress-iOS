import Testing
import WordPressFlux

// WordPressFlux's `Dispatcher` asserts it is only called from the main thread.
// XCTest ran test methods on the main thread; Swift Testing runs them off the
// main thread, so the suite is pinned to `@MainActor`.
@MainActor
struct WordPressFluxTests {
    @Test func testStoreReceivesActions() {
        struct TestAction: Action {}
        class TestStore: Store {
            var receivedActions = [Action]()
            override func onDispatch(_ action: Action) {
                super.onDispatch(action)
                receivedActions.append(action)
            }
        }

        let dispatcher = ActionDispatcher()
        let store = TestStore(dispatcher: dispatcher)
        #expect(store.receivedActions.isEmpty, "Store shouldn't have received any actions yet")
        ActionDispatcher.dispatch(TestAction(), dispatcher: dispatcher)
        #expect(store.receivedActions.count == 1, "Store shouldn't have received one action")
    }

    @Test func testStoreEmitsChanges() {
        class TestStore: Store {
            func test() {
                emitChange()
            }
        }

        let store = TestStore()
        var changeCount = 0
        var receipt: Receipt? = store.onChange {
            changeCount += 1
        }
        #expect(receipt != nil, "We should have a receipt now")
        store.test()
        #expect(changeCount == 1, "Store should have emitted one change event")
        store.test()
        #expect(changeCount == 2, "Store should have emitted two change events")
        receipt = nil
        store.test()
        #expect(changeCount == 2, "We should not receive any more events after releasing the receipt")
    }

    @Test func testStatefulStoreEmitsChanges() {
        class TestStore: StatefulStore<Int> {
            init() {
                super.init(initialState: 1)
            }

            func test() {
                state += state
            }
        }

        let store = TestStore()
        var receipts = [Receipt]()
        var changeCount = 0
        receipts.append(store.onChange({
            changeCount += 1
        }))
        var stateChangeCount = 0
        receipts.append(store.onStateChange({ old, new in
            #expect(new == old * 2, "New state should be double than old")
            stateChangeCount += 1
        }))

        #expect(store.state == 1, "Initial state should be 1")
        store.test()
        #expect(store.state == 2, "Second state should be 2")
        #expect(changeCount == 1, "Store should have emitted one change event")
        #expect(stateChangeCount == 1, "Store should have emitted one state change event")
    }

    @Test func testStatefulStoreWithoutTransaction() {
        class TestStore: StatefulStore<Int> {
            init() {
                super.init(initialState: 1)
            }

            func test() {
                state += state
                state += state
            }
        }

        let store = TestStore()
        var receipts = [Receipt]()
        var changeCount = 0
        receipts.append(store.onChange({
            changeCount += 1
        }))
        var stateChangeCount = 0
        receipts.append(store.onStateChange({ old, new in
            #expect(new == old * 2, "New state should be double than old")
            stateChangeCount += 1
        }))

        #expect(store.state == 1, "Initial state should be 1")
        store.test()
        #expect(store.state == 4, "Second state should be 4")
        #expect(changeCount == 2, "Store should have emitted one change event")
        #expect(stateChangeCount == 2, "Store should have emitted one state change event")
    }

    @Test func testStatefulStoreWithTransaction() {
        class TestStore: StatefulStore<Int> {
            init() {
                super.init(initialState: 1)
            }

            func test() {
                transaction { state in
                    state += state
                    state += state
                }
            }
        }

        let store = TestStore()
        var receipts = [Receipt]()
        var changeCount = 0
        receipts.append(store.onChange({
            changeCount += 1
        }))
        var stateChangeCount = 0
        receipts.append(store.onStateChange({ old, new in
            #expect(new == old * 4, "New state should be 4x the old one")
            stateChangeCount += 1
        }))

        #expect(store.state == 1, "Initial state should be 1")
        store.test()
        #expect(store.state == 4, "Second state should be 4")
        #expect(changeCount == 1, "Store should have emitted one change event")
        #expect(stateChangeCount == 1, "Store should have emitted one state change event")
    }

    @Test func testQueryStore() {
        struct TestQuery {
            let id: Int
        }
        class TestStore: QueryStore<Int, TestQuery> {
            var queriesChangedCount = 0

            init() {
                super.init(initialState: 1)
            }

            override func queriesChanged() {
                super.queriesChanged()
                queriesChangedCount += 1
            }
        }

        let store = TestStore()
        var receipts = [Receipt]()
        receipts.append(store.query(TestQuery(id: 1)))
        #expect(store.activeQueries.count == 1, "Store should have one active query")
        #expect(store.queriesChangedCount == 1, "Store should have processed one queriesChanged event")
    }
}
