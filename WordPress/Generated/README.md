# Derived Sources

`DerivedSecrets.swift` is shown in red in Xcode and `Open Quickly` cannot find it.
That is expected: it does not exist in the repository.

The `Generate Credentials` build phase writes it into the building target's `$(DERIVED_FILE_DIR)` on every build, from the secrets under `~/.configure/wordpress-ios/secrets`, or, failing those, from `WordPress/Credentials/Secrets-example.swift`.
See `Scripts/BuildPhases/GenerateCredentials.sh`.

Each target gets its own copy, so `WordPress`, `Jetpack` and `Reader` cannot overwrite each other's secrets.

Do not delete the red reference. The apps will not compile without it!
