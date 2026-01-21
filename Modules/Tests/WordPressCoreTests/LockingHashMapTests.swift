import Foundation
import Testing
@testable import WordPressCore

// MARK: - LockingHashMap Tests

@Suite("LockingHashMap")
struct LockingHashMapTests {

    // MARK: - Initialization

    @Test("initializes with empty dictionary by default")
    func testInitializesEmpty() {
        let map = LockingHashMap<String>()
        #expect(Array(map.values).isEmpty)
    }

    @Test("initializes with provided values")
    func testInitializesWithValues() {
        let map = LockingHashMap<Int>(["a": 1, "b": 2, "c": 3])
        #expect(Array(map.values).sorted() == [1, 2, 3])
    }

    // MARK: - Subscript Operations

    @Test("subscript returns nil for missing key")
    func testSubscriptMissingKey() {
        let map = LockingHashMap<String>()
        #expect(map["nonexistent"] == nil)
    }

    @Test("subscript gets existing value")
    func testSubscriptGet() {
        let map = LockingHashMap<String>(["key": "value"])
        #expect(map["key"] == "value")
    }

    @Test("subscript sets new value")
    func testSubscriptSetNew() {
        let map = LockingHashMap<String>()
        map["key"] = "value"
        #expect(map["key"] == "value")
    }

    @Test("subscript updates existing value")
    func testSubscriptUpdate() {
        let map = LockingHashMap<String>(["key": "old"])
        map["key"] = "new"
        #expect(map["key"] == "new")
    }

    @Test("subscript removes value when set to nil")
    func testSubscriptSetNil() {
        let map = LockingHashMap<String>(["key": "value"])
        map["key"] = nil
        #expect(map["key"] == nil)
    }

    @Test("subscript works with different key types")
    func testSubscriptDifferentKeyTypes() {
        let map = LockingHashMap<String>()
        map["stringKey"] = "string"
        map[42] = "int"
        map[UUID()] = "uuid"

        #expect(map["stringKey"] == "string")
        #expect(map[42] == "int")
        #expect(Array(map.values).count == 3)
    }

    // MARK: - Values Property

    @Test("values returns all stored values")
    func testValuesProperty() {
        let map = LockingHashMap<Int>(["a": 1, "b": 2, "c": 3])
        let values = Array(map.values).sorted()
        #expect(values == [1, 2, 3])
    }

    @Test("values returns empty collection when map is empty")
    func testValuesPropertyEmpty() {
        let map = LockingHashMap<Int>()
        #expect(Array(map.values).isEmpty)
    }

    // MARK: - removeValue(forKey:)

    @Test("removeValue returns and removes existing value")
    func testRemoveValueExisting() {
        let map = LockingHashMap<String>(["key": "value"])
        let removed = map.removeValue(forKey: "key")
        #expect(removed == "value")
        #expect(map["key"] == nil)
    }

    @Test("removeValue returns nil for missing key")
    func testRemoveValueMissing() {
        let map = LockingHashMap<String>()
        let removed = map.removeValue(forKey: "nonexistent")
        #expect(removed == nil)
    }

    @Test("removeValue does not affect other keys")
    func testRemoveValueOtherKeys() {
        let map = LockingHashMap<Int>(["a": 1, "b": 2, "c": 3])
        map.removeValue(forKey: "b")
        #expect(map["a"] == 1)
        #expect(map["b"] == nil)
        #expect(map["c"] == 3)
    }

    // MARK: - removeAll()

    @Test("removeAll clears all values")
    func testRemoveAll() {
        let map = LockingHashMap<Int>(["a": 1, "b": 2, "c": 3])
        map.removeAll()
        #expect(Array(map.values).isEmpty)
    }

    // MARK: - Thread Safety

    @Test("supports concurrent reads")
    func testConcurrentReads() async {
        let map = LockingHashMap<Int>(["key": 42])

        await withTaskGroup(of: Int?.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    map["key"]
                }
            }

            for await value in group {
                #expect(value == 42)
            }
        }
    }

    @Test("supports concurrent writes")
    func testConcurrentWrites() async {
        let map = LockingHashMap<Int>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    map[i] = i
                }
            }
        }

        #expect(Array(map.values).count == 100)
    }

    @Test("supports concurrent reads and writes")
    func testConcurrentReadsAndWrites() async {
        let map = LockingHashMap<Int>()

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<50 {
                group.addTask {
                    map[i] = i
                }
            }

            // Readers
            for i in 0..<50 {
                group.addTask {
                    _ = map[i]
                }
            }
        }

        // All writes should have succeeded
        for i in 0..<50 {
            #expect(map[i] == i)
        }
    }

    @Test("supports concurrent removes")
    func testConcurrentRemoves() async {
        let map = LockingHashMap<Int>()
        for i in 0..<100 {
            map[i] = i
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    map.removeValue(forKey: i)
                }
            }
        }

        #expect(Array(map.values).isEmpty)
    }
}

// MARK: - LockingTaskHashMap Tests

@Suite("LockingTaskHashMap")
struct LockingTaskHashMapTests {

    // MARK: - Basic Operations

    @Test("initializes empty")
    func testInitializesEmpty() {
        let map = LockingTaskHashMap<Int, Never>()
        #expect(Array(map.values).isEmpty)
    }

    @Test("stores and retrieves tasks")
    func testStoreAndRetrieve() async throws {
        let map = LockingTaskHashMap<Int, Never>()
        let task = Task { 42 }
        map["key"] = task

        let retrieved = map["key"]
        #expect(retrieved != nil)

        let result = await retrieved!.value
        #expect(result == 42)
    }

    // MARK: - removeValue(forKey:) Cancellation

    @Test("removeValue cancels the task")
    func testRemoveValueCancelsTask() async throws {
        let map = LockingTaskHashMap<Int, Never>()

        let taskStarted = expectation("task started")
        let taskCancelled = expectation("task cancelled")

        let task = Task {
            taskStarted.fulfill()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(10))
            }
            taskCancelled.fulfill()
            return 0
        }

        map["key"] = task

        await Task.yield()
        await taskStarted.fulfillment(within: .seconds(1))

        let removed = map.removeValue(forKey: "key")
        #expect(removed != nil)

        await taskCancelled.fulfillment(within: .seconds(1))
        #expect(map["key"] == nil)
    }

    @Test("removeValue returns the removed task")
    func testRemoveValueReturnsTask() async {
        let map = LockingTaskHashMap<String, Never>()
        let task = Task { "result" }
        map["key"] = task

        let removed = map.removeValue(forKey: "key")
        #expect(removed != nil)

        let result = await removed!.value
        #expect(result == "result")
    }

    @Test("removeValue returns nil for missing key")
    func testRemoveValueMissingKey() {
        let map = LockingTaskHashMap<Int, Never>()
        let removed = map.removeValue(forKey: "nonexistent")
        #expect(removed == nil)
    }

    // MARK: - removeAll() Cancellation

    @Test("removeAll cancels all tasks")
    func testRemoveAllCancelsTasks() async throws {
        let map = LockingTaskHashMap<Int, Never>()

        let tasksStarted = expectation("tasks started", expectedCount: 3)
        let tasksCancelled = expectation("tasks cancelled", expectedCount: 3)

        for i in 0..<3 {
            let task = Task {
                tasksStarted.fulfill()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(10))
                }
                tasksCancelled.fulfill()
                return i
            }
            map[i] = task
        }

        await Task.yield()
        await tasksStarted.fulfillment(within: .seconds(1))

        map.removeAll()

        await tasksCancelled.fulfillment(within: .seconds(1))
        #expect(Array(map.values).isEmpty)
    }

    // MARK: - Thread Safety

    @Test("supports concurrent task storage")
    func testConcurrentTaskStorage() async {
        let map = LockingTaskHashMap<Int, Never>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let task = Task { i }
                    map[i] = task
                }
            }
        }

        #expect(Array(map.values).count == 50)
    }

    @Test("supports concurrent removes with cancellation")
    func testConcurrentRemovesWithCancellation() async {
        let map = LockingTaskHashMap<Int, Never>()

        // Store tasks
        for i in 0..<50 {
            let task = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                return i
            }
            map[i] = task
        }

        // Concurrently remove all tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    map.removeValue(forKey: i)
                }
            }
        }

        #expect(Array(map.values).isEmpty)
    }

    // MARK: - Error-Throwing Tasks

    @Test("works with throwing tasks")
    func testThrowingTasks() async throws {
        let map = LockingTaskHashMap<Int, any Error>()

        let task: Task<Int, any Error> = Task {
            throw TestError.expected
        }
        map["key"] = task

        let retrieved = try #require(map["key"])

        await #expect(throws: TestError.self) {
            _ = try await retrieved.value
        }
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case expected
}

private func expectation(_ description: String, expectedCount: Int = 1) -> Expectation {
    Expectation(description: description, expectedCount: expectedCount)
}

private final class Expectation: @unchecked Sendable {
    private let lock = NSLock()
    private let description: String
    private let expectedCount: Int
    private var fulfillmentCount = 0
    private var continuation: CheckedContinuation<Void, Never>?

    init(description: String, expectedCount: Int) {
        self.description = description
        self.expectedCount = expectedCount
    }

    func fulfill() {
        lock.withLock {
            fulfillmentCount += 1
            if fulfillmentCount >= expectedCount {
                continuation?.resume()
                continuation = nil
            }
        }
    }

    func fulfillment(within timeout: Duration) async {
        let alreadyFulfilled = lock.withLock {
            fulfillmentCount >= expectedCount
        }

        if alreadyFulfilled {
            return
        }

        await withCheckedContinuation { cont in
            lock.withLock {
                if fulfillmentCount >= expectedCount {
                    cont.resume()
                } else {
                    continuation = cont
                }
            }
        }
    }
}
