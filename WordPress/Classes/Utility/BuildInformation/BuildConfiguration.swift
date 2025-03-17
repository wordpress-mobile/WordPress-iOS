enum BuildConfiguration: String {
    /// Development build, usually run from Xcode.
    case localDeveloper

    /// Preproduction builds for Automattic employees.
    case alpha

    /// Production build released in the app store.
    case appStore

    static var current: BuildConfiguration {
        #if DEBUG
            return .localDeveloper
        #elseif ALPHA_BUILD
            return .alpha
        #else
            return .appStore
        #endif
    }

    static func ~=(a: BuildConfiguration, b: Set<BuildConfiguration>) -> Bool {
        return b.contains(a)
    }

    var isInternal: Bool {
        self ~= [.localDeveloper, .alpha]
    }
}
