import Foundation

enum TestCredentials {
    /// The WordPress.com bearer token the app signs in with, resolved the same way as
    /// `Scripts/sim-signin.sh`: the `WPCOM_TOKEN` environment variable, then `~/.wpcom-token` on
    /// the host Mac.
    ///
    /// `xcodebuild` forwards `TEST_RUNNER_`-prefixed variables to the test runner with the prefix
    /// removed, so pass the token as `TEST_RUNNER_WPCOM_TOKEN` when running from the command line.
    static var wpcomToken: String? {
        let environment = ProcessInfo.processInfo.environment

        if let token = environment["WPCOM_TOKEN"].flatMap(normalized) {
            return token
        }

        // The test runner runs in the Simulator, so `~` is the Simulator's home directory rather
        // than the Mac's. The Simulator exposes the Mac's home directory in `SIMULATOR_HOST_HOME`.
        guard let hostHome = environment["SIMULATOR_HOST_HOME"] else {
            return nil
        }
        let tokenFile = URL(filePath: hostHome).appending(path: ".wpcom-token")
        return (try? String(contentsOf: tokenFile, encoding: .utf8)).flatMap(normalized)
    }

    private static func normalized(_ token: String) -> String? {
        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }
}
