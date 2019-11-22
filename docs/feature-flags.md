# Feature Flags

In WordPress for iOS, we use [feature flags](https://martinfowler.com/articles/feature-toggles.html) to allow us to merge in-progress features into `develop`, while still allowing us to safely deliver builds for testing and production. It's mostly useful for features that require multiple PRs to ship, and may take some time to complete.

We currently do this through [`BuildConfiguration`](https://github.com/wordpress-mobile/WordPress-iOS/blob/develop/WordPress/Classes/Utility/BuildInformation/BuildConfiguration.swift) and [`FeatureFlag`](https://github.com/wordpress-mobile/WordPress-iOS/blob/develop/WordPress/Classes/Utility/BuildInformation/FeatureFlag.swift). 

### BuildConfiguration

`BuildConfiguration` is an enum which reflects the type of build that is currently running:

```swift
case localDeveloper // debug

/// Continuous integration builds for Automattic employees to test branches & PRs
case a8cBranchTest // alpha

/// Beta released internally for Automattic employees
case a8cPrereleaseTesting. // internal - hockey / TestFlight

/// Production build released in the app store
case appStore // release
```

### FeatureFlag

The `FeatureFlag` enum contains a case for any in-progress features that are currently feature flagged. It contains a single computed `var`: `enabled`. This determines whether the feature should currently be enabled. This is typically determined based on the current `BuildConfiguration`. Here are a couple of examples:

```swift
enum FeatureFlag: Int {
    case exampleFeature
    case newMediaPicker
    case replaceAllImagesWithRaccoons

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .exampleFeature:
            return true
        case .newMediaPicker:
            return BuildConfiguration.current == .localDeveloper
        case .replaceAllImagesWithRaccoons:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest, .a8cPrereleaseTesting]
        }
    }
}
```

Here, we have three features which will be active in the following circumstances:

* `exampleFeature` will always be enabled
* `newMediaPicker` will only be enabled for local / debug builds
* `replaceAllImagesWithRaccoons` will be enabled for debug, alpha, and internal builds

### Putting it all together

The final step is to check the current status of a feature flag to selectively enable the feature within the app. For example, this might be displaying a button in the UI if a feature is enabled, or perhaps switching to a different code path in a service:

```swift
if FeatureFlag.replaceAllImagesWithRaccoons.enabled {
    avatarImageView.image = UIImage.randomRaccoonImage()
} else {
    avatarImageView.image = account.userAvatarImage
}
```

Once a feature is ready for release, you can remove the feature flag and the old code path.
