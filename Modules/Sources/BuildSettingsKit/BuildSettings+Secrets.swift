extension BuildSettings {

    /// For security reasons, we don't allow reading secrets from the Info.plist in our open source apps like we do for the rest of the
    /// build settings.
    ///
    /// Secrets values should not be tracked in the open source repository.
    ///
    /// As such, we need an alternative way to provide `BuildSettings` with the values for its `secrets` property and we rely to
    /// runtime injection which can be done with this static method.
    public static func configure(secrets: BuildSecrets) {
        BuildSecrets.configuredSecrets = secrets
    }
}
