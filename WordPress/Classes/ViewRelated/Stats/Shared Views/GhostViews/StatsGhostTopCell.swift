import UIKit
import DesignSystem
import WordPressUI

final class StatsGhostTopCell: StatsGhostBaseCell, NibLoadable {
    private let titleHeader: UIView = {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        return header
    }()

    private let valueHeaders: UIStackView = {
        let headers = UIStackView()
        headers.translatesAutoresizingMaskIntoConstraints = false
        headers.spacing = .DS.Padding.double
        headers.distribution = .fill
        headers.alignment = .fill
        headers.axis = .horizontal
        return headers
    }()

    private let contentRows: StatsGhostTopCellRow = {
        let contentRows = StatsGhostTopCellRow()
        contentRows.translatesAutoresizingMaskIntoConstraints = false
        return contentRows
    }()

    var numberOfColumns: Int = 2 {
        didSet {
            configureCell(with: numberOfColumns)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubviews([titleHeader, valueHeaders, contentRows])

        topConstraint = valueHeaders.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .DS.Padding.single)
        topConstraint?.isActive = true
        NSLayoutConstraint.activate([
            titleHeader.topAnchor.constraint(equalTo: valueHeaders.topAnchor),
            titleHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .DS.Padding.double),
            titleHeader.widthAnchor.constraint(equalToConstant: 50),
            titleHeader.heightAnchor.constraint(equalToConstant: .DS.Padding.double),

            valueHeaders.heightAnchor.constraint(equalToConstant: .DS.Padding.double),
            valueHeaders.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.DS.Padding.double),

            contentRows.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            contentRows.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            contentRows.topAnchor.constraint(equalTo: valueHeaders.bottomAnchor, constant: .DS.Padding.half),
            contentRows.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.DS.Padding.single)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureCell(with count: Int) {
        updateHeaders(count: count)
        contentRows.updateColumns(count: count)
    }

    private func updateHeaders(count: Int) {
        valueHeaders.removeAllSubviews()
        let headers = Array(repeating: UIView(), count: count - 1)
        headers.forEach { header in
            configureHeader(header)
            valueHeaders.addArrangedSubview(header)
        }
    }

    private func configureHeader(_ header: UIView) {
        header.startGhostAnimation()
        header.widthAnchor.constraint(equalToConstant: Constants.columnWidth).isActive = true
    }
}

final class StatsGhostTopCellRow: UIView {
    private let avatarView = UIView()
    private let columnsStackView = createStackView()
    private let mainColumn = StatsGhostTopCellColumn()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private static func createStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.spacing = .DS.Padding.double
        return stackView
    }

    private func setupViews() {
        [columnsStackView, mainColumn, avatarView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: .DS.Padding.medium),
            avatarView.widthAnchor.constraint(equalToConstant: .DS.Padding.medium),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .DS.Padding.double),
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: .DS.Padding.double),
            avatarView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.DS.Padding.double),
            mainColumn.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: .DS.Padding.double),
            mainColumn.centerYAnchor.constraint(equalTo: centerYAnchor),
            columnsStackView.leadingAnchor.constraint(equalTo: mainColumn.trailingAnchor, constant: .DS.Padding.double),
            columnsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            columnsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.DS.Padding.double)
        ])
    }

    func updateColumns(count: Int) {
        columnsStackView.removeAllSubviews()
        mainColumn.isHidden = count <= 1

        let columns = Array(repeating: StatsGhostTopCellColumn(width: StatsGhostTopCell.Constants.columnWidth), count: count - 1)
        columns.forEach(columnsStackView.addArrangedSubview)
    }
}

private class StatsGhostTopCellColumn: UIView {
    private let topView = UIView()
    private let bottomView = UIView()
    private let width: CGFloat?

    init(width: CGFloat? = nil) {
        self.width = width
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let stackView = createStackView()
        addSubview(stackView)
        pinSubviewToAllEdges(stackView)
        setupConstraints()
    }

    private func createStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [topView, bottomView])
        stackView.axis = .vertical
        stackView.spacing = .DS.Padding.half
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    private func setupConstraints() {
        var constraints = [
            topView.heightAnchor.constraint(equalToConstant: .DS.Padding.medium),
            bottomView.heightAnchor.constraint(equalToConstant: .DS.Padding.double)
        ]

        if let width {
            constraints += [
                topView.widthAnchor.constraint(equalToConstant: width),
                bottomView.widthAnchor.constraint(equalToConstant: width)
            ]
        }

        NSLayoutConstraint.activate(constraints)
        startAnimations()
    }

    private func startAnimations() {
        topView.startGhostAnimation(style: GhostCellStyle.muriel)
        bottomView.startGhostAnimation(style: GhostCellStyle.muriel)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        topView.restartGhostAnimation(style: GhostCellStyle.muriel)
        bottomView.restartGhostAnimation(style: GhostCellStyle.muriel)
    }
}

fileprivate extension StatsGhostTopCell {
    enum Constants {
        static let columnWidth: CGFloat = 60
    }
}
