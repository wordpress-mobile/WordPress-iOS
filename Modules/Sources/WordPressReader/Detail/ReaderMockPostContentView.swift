import UIKit

/// A mock post content view used in previews to simulate real article content
/// below the `ReaderPostHeaderView`.
@available(iOS 17, *)
final class ReaderMockPostContentView: UIView {

    private let textView = UITextView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 16, right: 12)

        addSubview(textView)
        textView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ setting: ReaderDisplaySettings) {
        textView.attributedText = Self.makePostContent(with: setting)
    }

    private static func makePostContent(with setting: ReaderDisplaySettings) -> NSAttributedString {
        let colors = setting.color
        let bodyFont = setting.font(with: .body)
        let headingFont = setting.font(with: .title3, weight: .bold)

        let bodyParagraph = NSMutableParagraphStyle()
        bodyParagraph.lineSpacing = 4
        bodyParagraph.paragraphSpacing = 12

        let headingParagraph = NSMutableParagraphStyle()
        headingParagraph.lineSpacing = 4
        headingParagraph.paragraphSpacing = 4
        headingParagraph.paragraphSpacingBefore = 8

        let body: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: colors.foreground,
            .paragraphStyle: bodyParagraph
        ]
        let heading: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: colors.foreground,
            .paragraphStyle: headingParagraph
        ]

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "We love working with talented artists from around the world, and this year, we invited Cinta to capture Automattic's holiday spirit in an illustration for our holiday card. We're excited to introduce Cinta and share her wonderful work with you!\n", attributes: body))
        result.append(NSAttributedString(string: "How would you describe your artistic style in three words, and why those three?\n", attributes: heading))
        result.append(NSAttributedString(string: "Colorful, conceptual, and playful. I like combining strong visual impact with ideas that invite interpretation and a sense of joy.\n", attributes: body))
        result.append(NSAttributedString(string: "What draws you to your medium?\n", attributes: heading))
        result.append(NSAttributedString(string: "I'm drawn to traditional techniques such as ink on paper because drawing with brushes and a fluid medium like ink allows me to give the line a strong sense of expressiveness and texture. I enjoy working with the imperfections and unexpected accidents of analog processes, as they add a sense of soul and authenticity to the final illustration. I then apply color digitally, combining the warmth of traditional media with the flexibility of digital tools.", attributes: body))
        return result
    }
}

// MARK: - ReaderPostHeaderPreviewController

@available(iOS 17, *)
final class ReaderPostHeaderPreviewController: UIViewController {
    private let scrollView = UIScrollView()
    private let headerView = ReaderPostHeaderView()
    private let contentView = ReaderMockPostContentView()
    private let viewModel: ReaderPostHeaderView.ViewModel
    private var currentSetting = ReaderDisplaySettings.standard

    init(viewModel: ReaderPostHeaderView.ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stack = UIStackView(arrangedSubviews: [headerView, contentView])
        stack.axis = .vertical

        view.addSubview(scrollView)
        scrollView.pinEdges()

        scrollView.addSubview(stack)
        stack.pinEdges()
        stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true

        headerView.configure(with: viewModel)
        applyDisplaySetting(.standard)

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil),
            UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: nil, action: nil),
        ]

        toolbarItems = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: currentSetting.color.label, menu: makeThemeMenu()),
        ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    private func applyDisplaySetting(_ setting: ReaderDisplaySettings) {
        currentSetting = setting
        headerView.apply(setting)
        contentView.apply(setting)
        view.backgroundColor = setting.color.background
        scrollView.backgroundColor = setting.color.background
    }

    private func makeThemeMenu() -> UIMenu {
        let colorActions = ReaderDisplaySettings.Color.allCases.map { color in
            UIAction(title: color.label, state: currentSetting.color == color ? .on : .off) { [weak self] _ in
                guard let self else { return }
                let setting = ReaderDisplaySettings(color: color, font: self.currentSetting.font, size: self.currentSetting.size)
                self.applyDisplaySetting(setting)
                self.toolbarItems?[1] = UIBarButtonItem(title: "Theme", menu: self.makeThemeMenu())
            }
        }
        return UIMenu(title: "Theme", children: colorActions)
    }
}
