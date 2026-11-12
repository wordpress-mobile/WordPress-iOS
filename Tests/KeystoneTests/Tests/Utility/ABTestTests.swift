import AutomatticTracks
import BuildSettingsKit
import Foundation
import Testing

@testable import WordPress

// Serialized: `ABTest.start` keeps the fetch in flight in a static, and the storage tests use
// `UserDefaults.standard` and `ExPlat.shared`.
@Suite("ABTest", .serialized)
@MainActor
struct ABTestTests {

    // MARK: Variation

    @Test("Only the WordPress app runs the Reader experiment")
    func experimentsPerApp() {
        #expect(ABTest.experiments(in: .wordpress) == [.readerInWordPressApp])
        #expect(ABTest.experiments(in: .jetpack).isEmpty)
        #expect(ABTest.experiments(in: .reader).isEmpty)
    }

    @Test("The assigned variation is returned in an app that runs the experiment")
    func assignedVariation() {
        let exPlat = ABTestingStub(variations: [ABTest.readerInWordPressApp.rawValue: .treatment])

        let variation = ABTest.readerInWordPressApp.variation(in: .wordpress, exPlat: exPlat)

        #expect(variation == .treatment)
    }

    @Test("Other apps get control whatever the assignment", arguments: [AppBrand.jetpack, .reader])
    func otherAppsGetControl(app: AppBrand) {
        let exPlat = ABTestingStub(variations: [ABTest.readerInWordPressApp.rawValue: .treatment])

        let variation = ABTest.readerInWordPressApp.variation(in: app, exPlat: exPlat)

        #expect(variation == .control)
    }

    @Test("No assignment means control")
    func noAssignment() {
        #expect(
            ABTest.readerInWordPressApp.variation(in: .wordpress, exPlat: ABTestingStub(variations: [:])) == .control
        )
        #expect(ABTest.readerInWordPressApp.variation(in: .wordpress, exPlat: nil) == .control)
    }

    // MARK: Start

    @Test("A signed-in WordPress.com account registers the app's experiments and fetches them")
    func startFetchesForSignedInAccount() async {
        let exPlat = ExperimentAssignerSpy()
        var didComplete = false

        ABTest.start(app: .wordpress, isDotComAvailable: true, hasOptedOutOfAnalytics: false, exPlat: exPlat) {
            didComplete = true
        }
        #expect(exPlat.registeredNames == [[ABTest.readerInWordPressApp.rawValue]])
        #expect(exPlat.pendingRefreshes.count == 1)
        #expect(!didComplete)

        exPlat.finishRefreshes()
        await drainMainQueue()

        #expect(didComplete)
    }

    @Test(
        "Nothing is requested while signed out, after opting out, in other apps, or without ExPlat",
        arguments: [
            (AppBrand.wordpress, false, false, true),
            (.wordpress, true, true, true),
            (.jetpack, true, false, true),
            (.reader, true, false, true),
            (.wordpress, true, false, false)
        ]
    )
    func startSkipsTheRequest(app: AppBrand, isDotComAvailable: Bool, hasOptedOut: Bool, hasExPlat: Bool) {
        let exPlat = ExperimentAssignerSpy()
        var didComplete = false

        ABTest.start(
            app: app,
            isDotComAvailable: isDotComAvailable,
            hasOptedOutOfAnalytics: hasOptedOut,
            exPlat: hasExPlat ? exPlat : nil
        ) {
            didComplete = true
        }

        #expect(didComplete)
        #expect(exPlat.registeredNames.isEmpty)
        #expect(exPlat.pendingRefreshes.isEmpty)
    }

    @Test("A second start while a fetch is in flight joins it")
    func secondStartJoinsTheFetch() async {
        let exPlat = ExperimentAssignerSpy()
        var completions: [String] = []

        ABTest.start(app: .wordpress, isDotComAvailable: true, hasOptedOutOfAnalytics: false, exPlat: exPlat) {
            completions.append("first")
        }
        ABTest.start(app: .wordpress, isDotComAvailable: true, hasOptedOutOfAnalytics: false, exPlat: exPlat) {
            completions.append("second")
        }
        #expect(exPlat.pendingRefreshes.count == 1)

        exPlat.finishRefreshes()
        await drainMainQueue()

        #expect(completions == ["first", "second"])
    }

    @Test("The ExPlat that started a fetch stays alive until it has stored the answer")
    func startKeepsExPlatAlive() async {
        // Given an ExPlat that, like the real one, drops the answer if it has been released
        var exPlat: WeakSelfAssigner? = WeakSelfAssigner()
        weak var weakExPlat = exPlat
        ABTest.start(app: .wordpress, isDotComAvailable: true, hasOptedOutOfAnalytics: false, exPlat: exPlat)

        // When Tracks replaces it while the request is in flight
        exPlat = nil
        #expect(weakExPlat != nil)
        WeakSelfAssigner.answerPendingRefresh()
        await drainMainQueue()

        // Then the answer is still stored, and the ExPlat is released afterwards
        #expect(WeakSelfAssigner.storedAnswers == 1)
        #expect(weakExPlat == nil)
    }

    @Test("A reset during a fetch clears the answer that arrives afterwards")
    func resetDuringFetchClearsTheLateAnswer() async {
        let userDefaults = UserDefaults(suiteName: #function)!
        defer { userDefaults.removePersistentDomain(forName: #function) }
        let exPlat = ExperimentAssignerSpy(storingAnswersIn: userDefaults)
        var didComplete = false

        // Given a fetch in flight
        ABTest.start(
            app: .wordpress,
            isDotComAvailable: true,
            hasOptedOutOfAnalytics: false,
            exPlat: exPlat,
            userDefaults: userDefaults
        ) {
            didComplete = true
        }

        // When the account signs out, then the answer arrives
        ABTest.reset(exPlat: exPlat, userDefaults: userDefaults)
        exPlat.finishRefreshes()
        await drainMainQueue()

        // Then
        #expect(didComplete)
        for key in ABTest.exPlatStorageKeys {
            #expect(userDefaults.object(forKey: key) == nil)
        }
    }

    @Test("A fetch without a reset keeps its answer")
    func fetchWithoutResetKeepsTheAnswer() async {
        let userDefaults = UserDefaults(suiteName: #function)!
        defer { userDefaults.removePersistentDomain(forName: #function) }
        let exPlat = ExperimentAssignerSpy(storingAnswersIn: userDefaults)

        ABTest.start(
            app: .wordpress,
            isDotComAvailable: true,
            hasOptedOutOfAnalytics: false,
            exPlat: exPlat,
            userDefaults: userDefaults
        )
        exPlat.finishRefreshes()
        await drainMainQueue()

        #expect(userDefaults.object(forKey: "ab-testing-assignments") != nil)
    }

    // MARK: Reset

    @Test("Reset forgets the stored assignments that ExPlat reads")
    func resetForgetsStoredAssignments() throws {
        let savedExPlat = ExPlat.shared
        let savedValues = ABTest.exPlatStorageKeys.map { UserDefaults.standard.object(forKey: $0) }
        defer {
            ExPlat.shared = savedExPlat
            for (key, value) in zip(ABTest.exPlatStorageKeys, savedValues) {
                UserDefaults.standard.set(value, forKey: key)
            }
        }

        // Given an assignment stored where ExPlat keeps it
        ExPlat.configure(platform: "wpios", oAuthToken: nil, userAgent: nil, anonId: nil)
        let exPlat = try #require(ExPlat.shared)
        UserDefaults.standard.set(
            [ABTest.readerInWordPressApp.rawValue: "treatment"],
            forKey: "ab-testing-assignments"
        )
        #expect(ABTest.readerInWordPressApp.variation(in: .wordpress, exPlat: exPlat) == .treatment)

        // When
        ABTest.reset(exPlat: exPlat)

        // Then
        #expect(ABTest.readerInWordPressApp.variation(in: .wordpress, exPlat: exPlat) == .control)
        for key in ABTest.exPlatStorageKeys {
            #expect(UserDefaults.standard.object(forKey: key) == nil)
        }
    }

    @Test("Reset unregisters the experiments, so ExPlat stops requesting them")
    func resetUnregistersExperiments() {
        let exPlat = ExperimentAssignerSpy()
        let userDefaults = UserDefaults(suiteName: #function)!
        defer { userDefaults.removePersistentDomain(forName: #function) }

        ABTest.reset(exPlat: exPlat, userDefaults: userDefaults)

        #expect(exPlat.registeredNames == [[]])
    }

    // MARK: Helpers

    /// Returns once the main queue has run everything queued before this call, which includes the
    /// completions `ABTest.start` queues when a refresh answers.
    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

private struct ABTestingStub: ABTesting {
    let variations: [String: Variation]

    func refresh(completion: (() -> Void)?) {
        completion?()
    }

    func experiment(_ name: String) -> Variation? {
        variations[name]
    }
}

private final class ExperimentAssignerSpy: ExperimentAssigning {
    private(set) var registeredNames: [[String]] = []
    private(set) var pendingRefreshes: [() -> Void] = []
    private let userDefaults: UserDefaults?

    /// - Parameter userDefaults: Where to store an answer before completing, as `ExPlat` does.
    init(storingAnswersIn userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults
    }

    func register(experiments experimentNames: [String]) {
        registeredNames.append(experimentNames)
    }

    func refresh(completion: (() -> Void)?) {
        let userDefaults = self.userDefaults
        pendingRefreshes.append {
            userDefaults?.set([ABTest.readerInWordPressApp.rawValue: "treatment"], forKey: "ab-testing-assignments")
            userDefaults?.set(Date(), forKey: "ab-testing-ttl-date")
            userDefaults?.set([ABTest.readerInWordPressApp.rawValue], forKey: "ab-testing-enrolled-experiments")
            completion?()
        }
    }

    /// Answers every refresh on a background queue, as ExPlat's network callback does.
    func finishRefreshes() {
        let refreshes = pendingRefreshes
        DispatchQueue.global()
            .sync {
                refreshes.forEach { $0() }
            }
    }
}

/// Mimics `ExPlat.refresh`: the network callback holds the `ExPlat` weakly and skips storing the
/// answer if it has been released.
private final class WeakSelfAssigner: ExperimentAssigning {
    private(set) static var storedAnswers = 0
    private static var pendingRefresh: (() -> Void)?

    static func answerPendingRefresh() {
        let refresh = pendingRefresh
        pendingRefresh = nil
        DispatchQueue.global().sync { refresh?() }
    }

    func register(experiments experimentNames: [String]) {}

    func refresh(completion: (() -> Void)?) {
        WeakSelfAssigner.pendingRefresh = { [weak self] in
            if self != nil {
                WeakSelfAssigner.storedAnswers += 1
            }
            completion?()
        }
    }
}
