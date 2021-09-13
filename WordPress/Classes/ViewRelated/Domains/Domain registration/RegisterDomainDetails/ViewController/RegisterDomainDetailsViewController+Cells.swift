import UIKit

extension RegisterDomainDetailsViewController {

    func checkMarkCell(with row: CheckMarkRow) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WPTableViewCellDefault.defaultReuseID)
            as? WPTableViewCellDefault else {
                return UITableViewCell()
        }

        cell.textLabel?.text = row.title
        cell.selectionStyle = .none
        cell.accessoryType = (row.isSelected) ? .checkmark : .none
        WPStyleGuide.configureTableViewCell(cell)

        return cell
    }

    func addAdddressLineCell(with title: String?) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WPTableViewCellDefault.defaultReuseID)
            as? WPTableViewCellDefault else {
                return UITableViewCell()
        }

        cell.textLabel?.text = title
        cell.selectionStyle = .none
        WPStyleGuide.configureTableViewActionCell(cell)
        return cell
    }

    func editableKeyValueCell(with row: EditableKeyValueRow, indexPath: IndexPath) -> UITableViewCell {

        func valueColor(row: EditableKeyValueRow) -> UIColor? {
            //we don't want to show red fonts before user taps register button
            return row.isValid(inContext: .serverSide) ? nil : .error
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: InlineEditableNameValueCell.defaultReuseID)
            as? InlineEditableNameValueCell else {
                return UITableViewCell()
        }

        cell.update(with: InlineEditableNameValueCell.Model(
            key: row.key,
            value: row.value,
            placeholder: row.placeholder,
            valueColor: valueColor(row: row),
            accessoryType: row.accessoryType(),
            valueSanitizer: row.valueSanitizer
        ))

        updateStyle(of: cell, at: indexPath)
        cell.delegate = self

        return cell
    }

    private func updateStyle(of cell: InlineEditableNameValueCell, at indexPath: IndexPath) {
        guard let section = SectionIndex(rawValue: indexPath.section) else {
            return
        }

        cell.valueTextField.returnKeyType = .next

        switch section {
        case .contactInformation:
            guard let index = RegisterDomainDetailsViewModel.CellIndex.ContactInformation(rawValue: indexPath.row) else {
                return
            }
            cell.valueTextField.keyboardType = index.keyboardType
            cell.valueTextField.autocapitalizationType = .words
        case .phone:
            cell.valueTextField.keyboardType = .numberPad
        case .address:
            let addressField = viewModel.addressSectionIndexHelper.addressField(for: indexPath.row)
            switch addressField {
            case .postalCode:
                cell.valueTextField.keyboardType = .numbersAndPunctuation
            default:
                cell.valueTextField.keyboardType = .default
                cell.valueTextField.autocapitalizationType = .words
            }
        default:
            cell.valueTextField.keyboardType = .default
            cell.valueTextField.autocapitalizationType = .none
        }
    }
}
