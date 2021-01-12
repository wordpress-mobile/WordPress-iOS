import UIKit

class FilterBarView: UIScrollView {
    let filterStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        filterStackView.alignment = .center
        filterStackView.spacing = Constants.filterStackViewSpacing
        filterStackView.translatesAutoresizingMaskIntoConstraints = false

        let filterIcon = UIImageView(image: UIImage.gridicon(.filter))
        filterIcon.tintColor = .listIcon
        filterIcon.heightAnchor.constraint(equalToConstant: Constants.filterHeightAnchor).isActive = true

        filterStackView.addArrangedSubview(filterIcon)

        canCancelContentTouches = true
        showsHorizontalScrollIndicator = false
        addSubview(filterStackView)

        NSLayoutConstraint.activate([
            filterStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.filterBarHorizontalPadding),
            filterStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1 * Constants.filterBarHorizontalPadding),
            filterStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.filterBarVerticalPadding),
            filterStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.filterBarVerticalPadding),
            heightAnchor.constraint(equalTo: filterStackView.heightAnchor, constant: 2 * Constants.filterBarVerticalPadding)
        ])

        // Ensure that the stackview is right aligned in RTL layouts
        if userInterfaceLayoutDirection() == .rightToLeft {
            transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            filterStackView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard let superview = superview else {
            return
        }

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            separator.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        WPStyleGuide.applyBorderStyle(separator)
        separator.layer.zPosition = 10
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func add(button chip: FilterChipButton) {
        filterStackView.addArrangedSubview(chip)
    }

    private enum Constants {
        static let filterHeightAnchor: CGFloat = 24
        static let filterStackViewSpacing: CGFloat = 8
        static let filterBarHorizontalPadding: CGFloat = 16
        static let filterBarVerticalPadding: CGFloat = 8
    }
}
