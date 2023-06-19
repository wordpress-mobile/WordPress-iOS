@testable import WordPress
import WordPressKit

class AccountSettingsRemoteInterfaceStub: AccountSettingsRemoteInterface {

    let updateSettingsStub: Stub<(), Error>
    let getSettingsStub: Stub<AccountSettings, Error>
    let changeUsernameShouldSucceed: Bool
    let suggestUsernamesResult: [String]
    let updatePasswordStub: Stub<(), Error>
    let closeAccountStub: Stub<(), Error>

    init(
        updateSettingResult: Result<Void, Error> = .success(()),
        // Defaulting to failure to avoid having to create AccountSettings here, because it required an NSManagedContext
        getSettingsResult: Result<AccountSettings, Error> = .failure(TestError()),
        changeUsernameShouldSucceed: Bool = true,
        suggestUsernamesResult: [String] = [],
        updatePasswordResult: Result<Void, Error> = .success(()),
        closeAccountResult: Result<Void, Error> = .success(())
    ) {
        self.updateSettingsStub = Stub(stubbedResult: updateSettingResult)
        self.getSettingsStub = Stub(stubbedResult: getSettingsResult)
        self.changeUsernameShouldSucceed = changeUsernameShouldSucceed
        self.suggestUsernamesResult = suggestUsernamesResult
        self.updatePasswordStub = Stub(stubbedResult: updatePasswordResult)
        self.closeAccountStub = Stub(stubbedResult: closeAccountResult)
    }

    func updateSetting(_ change: AccountSettingsChange, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        updateSettingsStub.stubBehavior(success: success, failure: failure)
    }

    func getSettings(success: @escaping (WordPressKit.AccountSettings) -> Void, failure: @escaping (Error) -> Void) {
        getSettingsStub.stubBehavior(success: success, failure: failure)
    }

    func changeUsername(to username: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        if changeUsernameShouldSucceed {
            success()
        } else {
            failure()
        }
    }

    func suggestUsernames(base: String, finished: @escaping ([String]) -> Void) {
        finished(suggestUsernamesResult)
    }

    func updatePassword(_ password: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        updatePasswordStub.stubBehavior(success: success, failure: failure)
    }

    func closeAccount(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        closeAccountStub.stubBehavior(success: success, failure: failure)
    }
}
