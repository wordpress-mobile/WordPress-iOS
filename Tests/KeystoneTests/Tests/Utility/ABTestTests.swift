import AutomatticTracks
import BuildSettingsKit
import Testing

@testable import WordPress

@Suite("ABTest")
struct ABTestTests {

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
