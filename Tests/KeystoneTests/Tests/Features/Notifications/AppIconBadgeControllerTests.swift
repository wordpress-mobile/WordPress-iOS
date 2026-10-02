import Testing
import Foundation
@testable import WordPress

// Serialized: completions hop through the main queue, so parallel main-actor
// tests would delay each other's hops.
@Suite(.serialized)
@MainActor
struct AppIconBadgeControllerTests {

    /// Records every system write and holds its completion until the test calls it.
    final class FakeSetter {
        private(set) var writes: [Int] = []
        private var completions: [(Error?) -> Void] = []
        var pendingCount: Int { completions.count }

        func set(_ count: Int, _ completion: @escaping (Error?) -> Void) {
            writes.append(count)
            completions.append(completion)
        }

        func complete(_ error: Error? = nil) {
            completions.removeFirst()(error)
        }
    }

    func makeController(_ setter: FakeSetter) -> AppIconBadgeController {
        AppIconBadgeController(retryDelay: 0) { setter.set($0, $1) }
    }

    /// Waits for main-queue hops (completion handling and retries) to land.
    func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<400 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    /// Fails a clear's original write and its three retries, leaving the
    /// request stranded.
    func exhaustRetries(_ setter: FakeSetter) async {
        for _ in 0..<4 {
            await waitUntil { setter.pendingCount == 1 }
            setter.complete(testError())
        }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(setter.writes == [0, 0, 0, 0])
    }

    @Test func writesOneAtATimeAndKeepsOnlyTheLatestRequest() async {
        let setter = FakeSetter()
        let controller = makeController(setter)
        controller.setBadgeCount(3)
        controller.setBadgeCount(5)
        controller.setBadgeCount(7)
        #expect(setter.writes == [3]) // later requests wait for the in-flight write

        setter.complete()
        await waitUntil { setter.writes.count == 2 }
        #expect(setter.writes == [3, 7])
        withExtendedLifetime(controller) {} // completions hold it weakly
    }

    @Test func repeatedClearIsWrittenAgain() async {
        // iOS applies `aps.badge` behind the controller's back, so an explicit
        // clear is never skipped as redundant.
        let setter = FakeSetter()
        let controller = makeController(setter)
        controller.setBadgeCount(0)
        setter.complete()
        controller.setBadgeCount(0)
        await waitUntil { setter.writes.count == 2 }
        #expect(setter.writes == [0, 0])
        withExtendedLifetime(controller) {} // completions hold it weakly
    }

    @Test func failedWriteIsRetriedAFewTimesThenANewRequestIsWritten() async {
        let setter = FakeSetter()
        let controller = makeController(setter)
        controller.setBadgeCount(0)
        await exhaustRetries(setter)

        // A new request gets a fresh budget and is written.
        controller.setBadgeCount(2)
        await waitUntil { setter.writes.count == 5 }
        #expect(setter.writes.last == 2)
        withExtendedLifetime(controller) {} // completions hold it weakly
    }

    @Test func retryPendingWriteResumesAfterRetriesRunOut() async {
        let setter = FakeSetter()
        let controller = makeController(setter)
        controller.setBadgeCount(0)
        await exhaustRetries(setter)

        controller.retryPendingWrite()
        #expect(setter.writes == [0, 0, 0, 0, 0])

        setter.complete()
        try? await Task.sleep(for: .milliseconds(50))
        controller.retryPendingWrite() // Nothing is pending after a success.
        #expect(setter.writes.count == 5)
        withExtendedLifetime(controller) {} // completions hold it weakly
    }
}
