fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
### code_freeze
```
fastlane code_freeze
```
Creates a new release branch from the current develop
### complete_code_freeze
```
fastlane complete_code_freeze
```
Creates a new release branch from the current develop
### update_appstore_strings
```
fastlane update_appstore_strings
```
Updates the AppStoreStrings.po file with the latest data
### new_beta_release
```
fastlane new_beta_release
```
Updates a release branch for a new beta release
### new_hotfix_release
```
fastlane new_hotfix_release
```
Creates a new hotfix branch from the given tag
### finalize_release
```
fastlane finalize_release
```
Removes all the temp tags and puts the final one
### finalize_hotfix_release
```
fastlane finalize_hotfix_release
```
Performs the final checks and tags the hotfix in the current branch
### build_and_upload_release
```
fastlane build_and_upload_release
```
Builds and updates for distribution
### build_and_upload_installable_build
```
fastlane build_and_upload_installable_build
```
Builds and uploads an installable build
### build_and_upload_internal
```
fastlane build_and_upload_internal
```
Builds and uploads for distribution
### build_and_upload_itc
```
fastlane build_and_upload_itc
```
Builds and uploads for distribution
### build_for_translation_review
```
fastlane build_for_translation_review
```
Builds and uploads for translation review
### build_for_testing
```
fastlane build_for_testing
```
Build for Testing
### register_new_device
```
fastlane register_new_device
```
Registers a Device in the developer console
### update_certs_and_profiles
```
fastlane update_certs_and_profiles
```

### test_without_building
```
fastlane test_without_building
```
Run tests without building
### get_pullrequests_list
```
fastlane get_pullrequests_list
```
Get a list of pull request from `start_tag` to the current state
### gutenberg_dep_check
```
fastlane gutenberg_dep_check
```
Verifies that Gutenberg is referenced by release version and not by commit

----

## iOS
### ios screenshots
```
fastlane ios screenshots
```
Generate localised screenshots
### ios create_promo_screenshots
```
fastlane ios create_promo_screenshots
```
Creates promo screenshots
### ios download_promo_strings
```
fastlane ios download_promo_strings
```
Downloads translated promo strings from GlotPress

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
