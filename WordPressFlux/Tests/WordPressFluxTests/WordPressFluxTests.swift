import XCTest
import WordPressFlux

class WordPressFluxTests: XCTestCase {
    func testStoreReceivesActions() {
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
        XCTAssertEqual(store.receivedActions.count, 0, "Store shouldn't have received any actions yet")
        ActionDispatcher.dispatch(TestAction(), dispatcher: dispatcher)
        XCTAssertEqual(store.receivedActions.count, 1, "Store shouldn't have received one action")
    }

    func testStoreEmitsChanges() {
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
        XCTAssertNotNil(receipt, "We should have a receipt now")
        store.test()
        XCTAssertEqual(changeCount, 1, "Store should have emitted one change event")
        store.test()
        XCTAssertEqual(changeCount, 2, "Store should have emitted two change events")
        receipt = nil
        store.test()
        XCTAssertEqual(changeCount, 2, "We should not receive any more events after releasing the receipt")
    }

    func testStatefulStoreEmitsChanges() {
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
        receipts.append(store.onStateChange({ (old, new) in
            XCTAssertEqual(new, old * 2, "New state should be double than old")
            stateChangeCount += 1
        }))

        XCTAssertEqual(store.state, 1, "Initial state should be 1")
        store.test()
        XCTAssertEqual(store.state, 2, "Second state should be 2")
        XCTAssertEqual(changeCount, 1, "Store should have emitted one change event")
        XCTAssertEqual(stateChangeCount, 1, "Store should have emitted one state change event")
    }

    func testStatefulStoreWithoutTransaction() {
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
        receipts.append(store.onStateChange({ (old, new) in
            XCTAssertEqual(new, old * 2, "New state should be double than old")
            stateChangeCount += 1
        }))

        XCTAssertEqual(store.state, 1, "Initial state should be 1")
        store.test()
        XCTAssertEqual(store.state, 4, "Second state should be 4")
        XCTAssertEqual(changeCount, 2, "Store should have emitted one change event")
        XCTAssertEqual(stateChangeCount, 2, "Store should have emitted one state change event")
    }

    func testStatefulStoreWithTransaction() {
        class TestStore: StatefulStore<Int> {
            init() {
                super.init(initialState: 1)
            }

            func test() {
                transaction { (state) in
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
        receipts.append(store.onStateChange({ (old, new) in
            XCTAssertEqual(new, old * 4, "New state should be 4x the old one")
            stateChangeCount += 1
        }))

        XCTAssertEqual(store.state, 1, "Initial state should be 1")
        store.test()
        XCTAssertEqual(store.state, 4, "Second state should be 4")
        XCTAssertEqual(changeCount, 1, "Store should have emitted one change event")
        XCTAssertEqual(stateChangeCount, 1, "Store should have emitted one state change event")
    }

    func testQueryStore() {
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
        XCTAssertEqual(store.activeQueries.count, 1, "Store should have one active query")
        XCTAssertEqual(store.queriesChangedCount, 1, "Store should have processed one queriesChanged event")
    }
}
