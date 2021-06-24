import CryptoKit

/// This structs helps encapsulate logic related to Gutenberg editor onboarding rollout phases.
///
struct GutenbergOnboardingRollout {
    private let phasePercentage = 50

    func isUserIdInPhaseRolloutPercentage(_ userId: Int) -> Bool {
        return convertUserIdToRank(userId: String(userId)) >= (100 - phasePercentage) || BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
    }

    func convertUserIdToRank(userId: String) -> Int {
        let inputString = userId + "can_view_editor_onboarding"
        let inputData = Data(inputString.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashRank = abs(hashed.hashValue) % 100
        return hashRank
    }
}
