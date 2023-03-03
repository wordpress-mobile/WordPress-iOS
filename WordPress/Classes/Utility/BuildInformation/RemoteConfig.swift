import Foundation

/// A struct that holds all remote config parameters.
/// This is where all remote config parameters should be defined.
struct RemoteConfig {

    // MARK: Private Variables

    private var store: RemoteConfigStore

    // MARK: Initializer

    init(store: RemoteConfigStore = RemoteConfigStore()) {
        self.store = store
    }

    // MARK: Remote Config Parameters

    var jetpackDeadline: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "jp_deadline", defaultValue: nil, store: store)
    }

    var phaseTwoBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase_two_blog_post", defaultValue: nil, store: store)
    }

    var phaseThreeBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase_three_blog_post", defaultValue: nil, store: store)
    }

    var phaseFourBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase_four_blog_post", defaultValue: nil, store: store)
    }

    var phaseNewUsersBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase_new_users_blog_post", defaultValue: nil, store: store)
    }

    var phaseSelfHostedBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase_self_hosted_blog_post", defaultValue: nil, store: store)
    }

    var blazeNonDismissibleStep: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "blaze_non_dismissable_hash", defaultValue: "step-4", store: store)
    }

    var blazeFlowCompletedStep: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "blaze_completed_step_hash", defaultValue: "step-5", store: store)
    }
}
