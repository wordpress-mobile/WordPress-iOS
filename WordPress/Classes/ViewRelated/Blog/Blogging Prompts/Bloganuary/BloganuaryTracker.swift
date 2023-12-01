struct BloganuaryTracker {

    enum ModalAction: String {
        case turnPromptsOn = "turn_prompts_on"
        case dismiss
    }

    static func trackCardLearnMoreTapped(promptsEnabled: Bool) {
        WPAnalytics.track(.bloganuaryNudgeCardLearnMoreTapped, properties: ["prompts_enabled": promptsEnabled])
    }

    static func trackModalShown(promptsEnabled: Bool) {
        WPAnalytics.track(.bloganuaryNudgeModalShown, properties: ["prompts_enabled": promptsEnabled])
    }

    static func trackModalDismissed() {
        WPAnalytics.track(.bloganuaryNudgeModalDismissed)
    }

    static func trackModalActionTapped(_ action: ModalAction) {
        WPAnalytics.track(.bloganuaryNudgeModalActionTapped, properties: ["action": action.rawValue])
    }
}
