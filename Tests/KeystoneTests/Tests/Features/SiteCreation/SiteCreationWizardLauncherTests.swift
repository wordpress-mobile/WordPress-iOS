import Testing

@testable import WordPress

struct SiteCreationWizardLauncherTests {
    @Test func jetpackWithFlagGetsShortFlow() {
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: true,
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .short)
        #expect(launcher.steps == [.address, .plan, .siteAssembly])
    }

    @Test func shortFlowWithoutPlansSkipsPlanStep() {
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: true,
            isPlansInSiteCreationEnabled: false
        )

        #expect(launcher.flow == .short)
        #expect(launcher.steps == [.address, .siteAssembly])
    }

    @Test func jetpackWithoutFlagGetsCurrentFlow() {
        let launcher = SiteCreationWizardLauncher(
            isJetpack: true,
            isShortFlowEnabled: false,
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .current)
        #expect(launcher.steps == [.intent, .design, .address, .plan, .siteAssembly])
    }

    @Test func wordPressAppGetsCurrentFlowEvenWithFlag() {
        let launcher = SiteCreationWizardLauncher(
            isJetpack: false,
            isShortFlowEnabled: true,
            isPlansInSiteCreationEnabled: true
        )

        #expect(launcher.flow == .current)
        #expect(launcher.steps == [.intent, .design, .address, .siteAssembly])
    }
}
