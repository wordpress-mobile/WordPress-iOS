public extension Blog {
    @objc var jetpack: JetpackState? {
        guard let options,
            !options.isEmpty else {
                return nil
        }
        let state = JetpackState()
        state.siteID = getOptionNumeric(name: "jetpack_client_id")
        state.version = getOptionString(name: "jetpack_version")
        state.connectedUsername = account?.username ?? getOptionString(name: "jetpack_user_login")
        state.connectedEmail = getOptionString(name: "jetpack_user_email")
        state.automatedTransfer = getOption(name: "is_automated_transfer") ?? false
        return state
    }

    /// Returns true if the blog has the proper version of Jetpack installed,
    /// otherwise false
    ///
    var hasJetpack: Bool {
        guard let jetpack else {
            return false
        }
        return (jetpack.isConnected && jetpack.isUpdatedToRequiredVersion)
    }

    /// Returns true if the blog has a version of the Jetpack plugin installed,
    /// otherwise false
    ///
    var jetpackIsConnected: Bool {
        guard let jetpack else {
            return false
        }
        return jetpack.isConnected
    }

    // MARK: Jetpack Individual Plugins Support

    var jetpackConnectionActivePlugins: [String]? {
        switch getOptionValue("jetpack_connection_active_plugins") {
        case .some(let values as [NSString]):
            return values.map { String($0) }
        case .some(let values as [String]):
            return values
        default:
            return nil
        }
    }

    /// Returns true if the blog is Jetpack-connected only through individual plugins. Otherwise false.
    ///
    /// If the site is hosted at WP.com, the key `jetpack_connection_active_plugins` will not exist in `options`.
    /// Atomic sites will have the full Jetpack plugin automatically installed.
    /// Example values for Jetpack individual plugins: `jetpack-search`, `jetpack-backup`, etc.
    ///
    /// Note: We can't use `jetpackIsConnected` because it checks the installed Jetpack version.
    ///
    var jetpackIsConnectedWithoutFullPlugin: Bool {
        guard let activeJetpackPlugins = jetpackConnectionActivePlugins else {
            return false
        }

        return !(activeJetpackPlugins.isEmpty || activeJetpackPlugins.contains("jetpack"))
    }

    @objc var isXMLRPCDisabled: Bool {
        get { getOption(name: "__app_xmlrpc_disabled") ?? false }
        set { setValue(NSNumber(value: newValue), forOption: "__app_xmlrpc_disabled") }
    }
}
