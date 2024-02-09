import UIKit
import WordPressFlux
import WordPressKit
import CocoaLumberjack

protocol SettingsController: ImmuTableController {
    var trackingKey: String { get }
}

// MARK: - Actions
extension SettingsController {
    func insideNavigationController(_ generator: @escaping ImmuTableRowControllerGenerator) -> ImmuTableRowControllerGenerator {
        return { row in
            let controller = generator(row)
            let navigation = UINavigationController(rootViewController: controller)
            navigation.modalPresentationStyle = .formSheet
            return navigation
        }
    }

    func editText(_ changeType: @escaping AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> (ImmuTableRow) -> SettingsTextViewController {
        return { row in
            let editableRow = row as! EditableTextRow
            return self.controllerForEditableText(editableRow, changeType: changeType, hint: hint, service: service)
        }
    }

    func editMultilineText(_ changeType: @escaping AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> (ImmuTableRow) -> SettingsMultiTextViewController {
        return { row in
            let editableRow = row as! EditableTextRow
            return self.controllerForEditableMultilineText(editableRow, changeType: changeType, hint: hint, service: service)
        }
    }

    func editEmailAddress(_ changeType: @escaping AccountSettingsChangeWithString, hint: String? = nil, service: AccountSettingsService) -> (ImmuTableRow) -> SettingsTextViewController {
        return { row in
            let editableRow = row as! EditableTextRow
            let settingsViewController =  self.controllerForEditableText(editableRow, changeType: changeType, hint: hint, service: service)
            settingsViewController.mode = .email

            return settingsViewController
        }
    }

    func controllerForEditableText(_ row: EditableTextRow,
                                   changeType: @escaping AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   service: AccountSettingsService) -> SettingsTextViewController {
        let title = row.title
        let value = row.value

        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.onValueChanged = {
            value in

            let change = changeType(value)
            service.saveChange(change)
            if change.isGravatarField {
                sendGravatarSyncNotice()
            }
            DDLogDebug("\(title) changed: \(value)")

            trackChangeIfNeeded(row)
        }

        return controller
    }

    func controllerForEditableMultilineText(_ row: EditableTextRow,
                                   changeType: @escaping AccountSettingsChangeWithString,
                                   hint: String? = nil,
                                   service: AccountSettingsService) -> SettingsMultiTextViewController {
        let title = row.title
        let value = row.value

        let controller = SettingsMultiTextViewController(text: value, placeholder: "\(title)...", hint: hint, isPassword: false)

        controller.title = title
        controller.onValueChanged = {
            newValue in
            guard value != newValue else { return }
            let change = changeType(newValue)
            service.saveChange(change)
            if change.isGravatarField {
                sendGravatarSyncNotice()
            }
            DDLogDebug("\(title) changed: \(newValue)")

            trackChangeIfNeeded(row)
        }

        return controller
    }

    private func trackChangeIfNeeded(_ row: EditableTextRow) {
        // Don't track if the field name isn't specified
        guard let fieldName = row.fieldName else {
            return
        }

        WPAnalytics.trackSettingsChange(trackingKey, fieldName: fieldName)
    }

    private func sendGravatarSyncNotice() {
        let noticeMessage = NSLocalizedString("Updates might take some time to sync with your Gravatar profile.", comment: "A notice message that's shown after the user updates their profile information.")
        ActionDispatcher.dispatch(NoticeAction.post(Notice(title: noticeMessage)))
    }
}

extension AccountSettingsChange {

    // These are the fields that are in sync with user's Gravatar account
    var isGravatarField: Bool {
        switch self {
        case .firstName, .lastName, .aboutMe, .displayName:
            return true
        default:
            return false
        }
    }
}
