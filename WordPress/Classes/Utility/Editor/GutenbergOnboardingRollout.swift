/// This structs helps encapsulate logic related to Gutenberg editor onboarding rollout phases.
///
struct GutenbergOnboardingRollout {
    private let phasePercentage = 0

    func isUserIdInPhaseRolloutPercentage(_ userId: Int) -> Bool {
        return userId % 100 >= (100 - phasePercentage) || BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
    }
}
