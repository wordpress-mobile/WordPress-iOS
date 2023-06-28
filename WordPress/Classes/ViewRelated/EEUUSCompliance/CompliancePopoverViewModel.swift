import Foundation
import UIKit
import WordPressUI

protocol CompliancePopoverViewModelProtocol {
    func didTapSettings()
    func didTapSave()
}

final class CompliancePopoverViewModel: CompliancePopoverViewModelProtocol {
    func didTapSettings() {
        print("** TAPPED SETTINGS **")
        RootViewCoordinator.sharedPresenter.navigateToPrivacySettings()
    }

    func didTapSave() {
        print("** TAPPED SAVE **")
    }
}
