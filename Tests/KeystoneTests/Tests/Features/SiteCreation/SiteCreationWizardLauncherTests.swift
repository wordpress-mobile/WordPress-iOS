import AutomatticTracks
import Testing

@testable import WordPress

struct SiteCreationWizardLauncherTests {
    @Test func jetpackTreatmentWithFlagGetsShortFlow() {
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: true,
            abTesting: StubABTesting(variation: .treatment),
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .short)
        #expect(launcher.steps == [.address, .plan, .siteAssembly])
    }

    @Test func shortFlowWithoutPlansSkipsPlanStep() {
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: true,
            abTesting: StubABTesting(variation: .treatment),
            isPlansInSiteCreationEnabled: false
        )

        #expect(launcher.flow == .short)
        #expect(launcher.steps == [.address, .siteAssembly])
    }

    @Test func jetpackWithoutFlagGetsCurrentFlow() {
        let abTesting = StubABTesting(variation: .treatment)
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: false,
            abTesting: abTesting,
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .current)
        #expect(launcher.steps == [.intent, .design, .address, .plan, .siteAssembly])
        #expect(abTesting.requestedExperiments.isEmpty)
    }

    @Test func wordPressAppGetsCurrentFlowEvenWithFlag() {
        let abTesting = StubABTesting(variation: .treatment)
        let launcher = SiteCreationWizardLauncher(
            isJetpack: false,
            isShortFlowEnabled: true,
            abTesting: abTesting,
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .current)
        #expect(launcher.steps == [.intent, .design, .address, .siteAssembly])
        #expect(abTesting.requestedExperiments.isEmpty)
    }

    @Test func jetpackControlGetsCurrentFlow() {
        let abTesting = StubABTesting(variation: .control)
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: true,
            abTesting: abTesting,
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .current)
        #expect(abTesting.requestedExperiments == ["jpios_site_creation_short_flow_v1"])
    }

    @Test func jetpackWithoutAssignmentGetsCurrentFlow() {
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: true,
            abTesting: StubABTesting(variation: nil),
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .current)
    }
}

private final class StubABTesting: ABTesting {
    let variation: Variation?
    private(set) var requestedExperiments: [String] = []

    init(variation: Variation?) {
        self.variation = variation
    }

    func refresh(completion: (() -> Void)?) {
        completion?()
    }

    func experiment(_ name: String) -> Variation? {
        requestedExperiments.append(name)
        return variation
    }
}
