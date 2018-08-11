import UIKit

extension RegisterDomainDetailsViewController {

    func checkMarkCell(with row: CheckMarkRow) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: WPTableViewCellDefault.defaultReuseID
            ) as? WPTableViewCellDefault {
            cell.textLabel?.text = row.title
            cell.selectionStyle = .none
            cell.accessoryType = (row.isSelected) ? .checkmark : .none
            WPStyleGuide.configureTableViewCell(cell)
            return cell
        }
        return UITableViewCell()
    }

    func addAdddressLineCell(with title: String?) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: WPTableViewCellDefault.defaultReuseID
            ) as? WPTableViewCellDefault {
            cell.textLabel?.text = title
            cell.selectionStyle = .none
            WPStyleGuide.configureTableViewActionCell(cell)
            return cell
        }
        return UITableViewCell()
    }

    func editableKeyValueCell(with row: EditableKeyValueRow, indexPath: IndexPath) -> UITableViewCell {

        func valueColor(row: EditableKeyValueRow) -> UIColor? {
            //we don't want to show red fonts before user taps register button
            if !registerButtonTapped {
                return nil
            } else {
                return row.isValid(forTag: Tag.proceedSubmit.rawValue) ? nil : WPStyleGuide.errorRed()
            }
        }

        if let cell = tableView.dequeueReusableCell(
            withIdentifier: InlineEditableNameValueCell.defaultReuseID
            ) as? InlineEditableNameValueCell {

            cell.update(with: InlineEditableNameValueCell.Model(
                key: row.key,
                value: row.value,
                placeholder: row.placeholder,
                valueColor: valueColor(row: row),
                accessoryType: row.accessoryType()
            ))
            updateStyle(of: cell, at: indexPath)
            cell.delegate = self
            return cell
        }
        return UITableViewCell()
    }

    private func updateStyle(of cell: InlineEditableNameValueCell, at indexPath: IndexPath) {
        guard let section = SectionIndex(rawValue: indexPath.section) else {
            return
        }
        switch section {
        case .contactInformation:
            guard let index = RegisterDomainDetailsViewModel.CellIndex.ContactInformation(rawValue: indexPath.row) else {
                return
            }
            cell.valueTextField.keyboardType = index.keyboardType
        case .phone:
            cell.valueTextField.keyboardType = .numberPad
        case .address:
            let addressField = viewModel.addressSectionIndexHelper.addressField(for: indexPath.row)
            switch addressField {
            case .postalCode:
                cell.valueTextField.keyboardType = .numbersAndPunctuation
            default:
                cell.valueTextField.keyboardType = .default
            }
        default:
            cell.valueTextField.keyboardType = .default
        }
    }
}
