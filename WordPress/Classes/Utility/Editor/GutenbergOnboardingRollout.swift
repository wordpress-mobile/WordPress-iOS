/// This structs helps encapsulate logic related to Gutenberg editor onboarding rollout phases.
///
struct GutenbergOnboardingRollout {
    private let phasePercentage = 50

    func isUserIdInPhaseRolloutPercentage(_ userId: Int) -> Bool {
        return convertUserIdToRank(userId: String(userId)) >= (100 - phasePercentage) || BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
    }

    func convertUserIdToRank(userId: String) -> Int {
        let key = userId + "can_view_editor_onboarding"
        let inputString = key.replacingOccurrences(of: "-", with: "")
        return abs(inputString.djb2hash) % 100
    }
}

extension String {
    // Ref: http://www.cse.yorku.ca/~oz/hash.html
    // hash(0) = 5381
    // hash(i) = hash(i - 1) * 33 ^ str[i];
    var djb2hash: Int {
        unicodeScalars.map { $0.value }.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
}
