public struct ImmuTable {
    public typealias ActionType = () -> Void
    public let sections: [Section]

    public func rowAtIndexPath(indexPath: NSIndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    public struct Row {
        let title: String
        let detail: String?
        let icon: UIImage?
        let visible: Bool
        let selected: ActionType?
    }

    public struct Section {
        let headerText: String?
        let rows: [Row]
        let footerText: String?

        init(rows: [Row]) {
            self.headerText = nil
            self.rows = rows
            self.footerText = nil
        }

        init(headerText: String?, rows: [Row], footerText: String?) {
            self.headerText = headerText
            self.rows = rows
            self.footerText = footerText
        }

        var visibleRows: [Row] {
            return rows.filter { $0.visible }
        }
    }

    public static func ButtonRow(title title: String, visible: Bool = true, action: ActionType) -> ImmuTable.Row {
        return ImmuTable.Row(
            title: title,
            detail: nil,
            icon: nil,
            visible: visible,
            selected: action
        )
    }

    public static func MenuItem(icon icon: UIImage, title: String, visible: Bool = true, action: ActionType) -> ImmuTable.Row {
        return ImmuTable.Row(
            title: title,
            detail: nil,
            icon: icon,
            visible: visible,
            selected: action
        )
    }

    public static func Item(title title: String, visible: Bool = true, action: ActionType) -> ImmuTable.Row {
        return ImmuTable.Row(
            title: title,
            detail: nil,
            icon: nil,
            visible: visible,
            selected: action
        )
    }

    public static func TextField(title title: String, value: String, visible: Bool = true, action: ActionType) -> ImmuTable.Row {
        return ImmuTable.Row(
            title: title,
            detail: value,
            icon: nil,
            visible: visible,
            selected: action
        )
    }
}
