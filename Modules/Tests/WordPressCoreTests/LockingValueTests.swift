import Foundation
import Testing
@testable import WordPressCore

// MARK: - LockingValue Tests

@Suite("LockingValue")
struct LockingValueTests {

    // MARK: - Initialization

    @Test("initializes with provided value")
    func testInitializesWithValue() {
        let lockingValue = LockingValue(42)
        #expect(lockingValue.value == 42)
    }

    @Test("initializes with nil optional")
    func testInitializesWithNil() {
        let lockingValue = LockingValue<Int?>(nil)
        #expect(lockingValue.value == nil)
    }

    @Test("initializes with complex type")
    func testInitializesWithComplexType() {
        struct Person: Equatable {
            let name: String
            let age: Int
        }
        let person = Person(name: "Alice", age: 30)
        let lockingValue = LockingValue(person)
        #expect(lockingValue.value == person)
    }

    // MARK: - Value Access

    @Test("gets value")
    func testGetValue() {
        let lockingValue = LockingValue("hello")
        #expect(lockingValue.value == "hello")
    }

    @Test("sets value")
    func testSetValue() {
        let lockingValue = LockingValue("initial")
        lockingValue.value = "updated"
        #expect(lockingValue.value == "updated")
    }

    @Test("sets nil on optional value")
    func testSetNilOnOptional() {
        let lockingValue = LockingValue<String?>("initial")
        lockingValue.value = nil
        #expect(lockingValue.value == nil)
    }

    // MARK: - withLock

    @Test("withLock reads value")
    func testWithLockReads() {
        let lockingValue = LockingValue(100)
        let result = lockingValue.withLock { $0 }
        #expect(result == 100)
    }

    @Test("withLock modifies value")
    func testWithLockModifies() {
        let lockingValue = LockingValue(10)
        lockingValue.withLock { $0 += 5 }
        #expect(lockingValue.value == 15)
    }

    @Test("withLock returns result")
    func testWithLockReturnsResult() {
        let lockingValue = LockingValue(42)
        let doubled = lockingValue.withLock { value -> Int in
            let result = value * 2
            value = result
            return result
        }
        #expect(doubled == 84)
        #expect(lockingValue.value == 84)
    }

    @Test("withLock performs conditional update")
    func testWithLockConditionalUpdate() {
        let lockingValue = LockingValue<Int?>(nil)
        let wasUpdated = lockingValue.withLock { value -> Bool in
            if value == nil {
                value = 42
                return true
            }
            return false
        }
        #expect(wasUpdated == true)
        #expect(lockingValue.value == 42)
    }

    @Test("withLock performs compare-and-swap")
    func testWithLockCompareAndSwap() {
        let lockingValue = LockingValue(10)

        // First swap should succeed
        let firstSwap = lockingValue.withLock { value -> Bool in
            if value == 10 {
                value = 20
                return true
            }
            return false
        }
        #expect(firstSwap == true)
        #expect(lockingValue.value == 20)

        // Second swap with wrong expected value should fail
        let secondSwap = lockingValue.withLock { value -> Bool in
            if value == 10 {
                value = 30
                return true
            }
            return false
        }
        #expect(secondSwap == false)
        #expect(lockingValue.value == 20)
    }

    // MARK: - Thread Safety

    @Test("supports concurrent reads")
    func testConcurrentReads() async {
        let lockingValue = LockingValue(42)

        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    lockingValue.value
                }
            }

            for await value in group {
                #expect(value == 42)
            }
        }
    }

    @Test("supports concurrent writes")
    func testConcurrentWrites() async {
        let lockingValue = LockingValue(0)

        await withTaskGroup(of: Void.self) { group in
            for i in 1...100 {
                group.addTask {
                    lockingValue.value = i
                }
            }
        }

        // Value should be one of the written values (1-100)
        let finalValue = lockingValue.value
        #expect(finalValue >= 1 && finalValue <= 100)
    }

    @Test("supports concurrent increments with withLock")
    func testConcurrentIncrementsWithLock() async {
        let lockingValue = LockingValue(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    lockingValue.withLock { $0 += 1 }
                }
            }
        }

        #expect(lockingValue.value == 100)
    }

    @Test("supports concurrent reads and writes")
    func testConcurrentReadsAndWrites() async {
        let lockingValue = LockingValue(0)

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 1...50 {
                group.addTask {
                    lockingValue.value = i
                }
            }

            // Readers
            for _ in 0..<50 {
                group.addTask {
                    _ = lockingValue.value
                }
            }
        }

        // Should complete without crashing
        let finalValue = lockingValue.value
        #expect(finalValue >= 0 && finalValue <= 50)
    }

    @Test("atomic flag toggle under contention")
    func testAtomicFlagToggle() async {
        let lockingValue = LockingValue(false)
        let toggleCount = LockingValue(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    lockingValue.withLock { value in
                        value.toggle()
                    }
                    toggleCount.withLock { $0 += 1 }
                }
            }
        }

        // After 100 toggles, value should be back to false
        #expect(lockingValue.value == false)
        #expect(toggleCount.value == 100)
    }
}
