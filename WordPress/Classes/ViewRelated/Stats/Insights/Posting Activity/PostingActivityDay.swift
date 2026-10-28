import UIKit
import WordPressKit
import WordPressShared

protocol PostingActivityDayDelegate: AnyObject {
    func daySelected(_ day: PostingActivityDay)
}

class PostingActivityDay: UIView {

    // MARK: - Properties

    let dayButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return button
    }()
    private weak var delegate: PostingActivityDayDelegate?

    private var visible = true
    private var active = true
    private(set) var dayData: PostingStreakEvent?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyStatsXibRootDefaults(size: CGSize(width: 12, height: 12))

        backgroundColor = .white
        dayButton.addTarget(self, action: #selector(dayButtonPressed), for: .touchUpInside)
        addSubview(dayButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Position the button with a frame rather than constraints: a system button laid out
        // with Auto Layout creates a (hidden) title label, and the ghost animation only covers
        // views without subviews, so the loading state would lose its placeholder squares.
        let guide = bounds.inset(by: safeAreaInsets)
        dayButton.frame = CGRect(
            x: guide.midX - Metrics.daySize / 2,
            y: guide.midY - Metrics.daySize / 2,
            width: Metrics.daySize,
            height: Metrics.daySize
        )
    }

    private enum Metrics {
        static let daySize: CGFloat = 12
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(dayData: PostingStreakEvent? = nil, delegate: PostingActivityDayDelegate? = nil) {
        self.dayData = dayData
        visible = dayData != nil
        active = delegate != nil
        self.delegate = delegate
        backgroundColor = .clear
        configureButton()
    }

    func unselect() {
        dayButton.backgroundColor = colorForCount()
    }
}

// MARK: - Private Extension

private extension PostingActivityDay {

    func configureButton() {
        dayButton.isGhostableDisabled = !visible
        dayButton.isEnabled = visible && active
        dayButton.backgroundColor = visible ? colorForCount() : .clear
    }

    func colorForCount() -> UIColor? {
        guard let dayData else {
            return .clear
        }

        return PostingActivityLegend.colorForCount(dayData.postCount)
    }

    @objc func dayButtonPressed(_ sender: UIButton) {
        WPAppAnalytics.track(.statsItemTappedPostingActivityDay)
        dayButton.backgroundColor = WPStyleGuide.Stats.PostingActivityColors.selectedDay
        delegate?.daySelected(self)
    }
}
