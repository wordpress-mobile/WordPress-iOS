import SwiftUI
import DesignSystem

class ReaderDisplaySettingViewController: UIViewController {
    private let initialSetting: ReaderDisplaySetting
    private let completion: ((ReaderDisplaySetting) -> Void)?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(initialSetting: ReaderDisplaySetting, completion: ((ReaderDisplaySetting) -> Void)?) {
        self.initialSetting = initialSetting
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        let viewModel = ReaderDisplaySettingSelectionViewModel(displaySetting: initialSetting) { [weak self] setting in
            self?.dismiss(animated: true, completion: {
                self?.completion?(setting)
            })
        }

        let swiftUIView = UIView.embedSwiftUIView(ReaderDisplaySettingSelectionView(viewModel: viewModel))
        view.addSubview(swiftUIView)
        view.pinSubviewToAllEdges(swiftUIView)
    }
}

// MARK: - SwiftUI

// MARK: View Model

class ReaderDisplaySettingSelectionViewModel: NSObject, ObservableObject {

    let feedbackLinkString = String() // TODO: Update with actual link

    @Published var displaySetting: ReaderDisplaySetting

    private let completion: ((ReaderDisplaySetting) -> Void)?

    init(displaySetting: ReaderDisplaySetting, completion: ((ReaderDisplaySetting) -> Void)?) {
        self.displaySetting = displaySetting
        self.completion = completion
    }

    func doneButtonTapped() {
        completion?(displaySetting)
    }

    // Convenience accessors

    var foregroundColor: Color {
        Color(displaySetting.color.foreground)
    }

    var backgroundColor: Color {
        Color(displaySetting.color.background)
    }
}

// MARK: Container View

struct ReaderDisplaySettingSelectionView: View {

    @ObservedObject var viewModel: ReaderDisplaySettingSelectionViewModel

    var body: some View {
        ZStack {
            PreviewView(viewModel: viewModel)
            VStack {
                Spacer() // stick the control view to the bottom.
                ControlView(viewModel: viewModel)
                    .overlay(alignment: .top, content: { // add 1pt top border.
                        Rectangle()
                            .frame(width: nil, height: 1.0, alignment: .top)
                            .foregroundStyle(Color(.tertiaryLabel))
                    })
            }
        }
    }

}

// MARK: - Preview View

extension ReaderDisplaySettingSelectionView {

    struct PreviewView: View {
        @ObservedObject var viewModel: ReaderDisplaySettingSelectionViewModel

        var body: some View {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: .DS.Padding.double) {
                    Text(Strings.Preview.title)
                        .font(Font(viewModel.displaySetting.font(with: .title1)))
                        .foregroundStyle(Color(viewModel.displaySetting.color.foreground))

                    tagsView

                    // TODO: Add feature flag for feedback collection.
                    // TODO: Apply link styles.
                    if let feedbackURL = URL(string: viewModel.feedbackLinkString) {
                        Link(Strings.Preview.feedbackLinkText, destination: feedbackURL)
                    }

                    Text(Strings.Preview.bodyDescription)
                        .font(Font(viewModel.displaySetting.font(with: .callout)))
                        .foregroundStyle(viewModel.foregroundColor)

                    Text(Strings.Preview.bodyNotice)
                        .font(Font(viewModel.displaySetting.font(with: .callout)))
                        .foregroundStyle(viewModel.foregroundColor)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.DS.Padding.double)
            .background(viewModel.backgroundColor)
            .animation(.easeInOut, value: viewModel.displaySetting)
        }

        var tagsView: some View {
            ScrollView(.horizontal) {
                HStack(spacing: .DS.Padding.single) {
                    ForEach(Strings.Preview.tags, id: \.self) { text in
                        Text(text)
                            .font(Font(viewModel.displaySetting.font(with: .callout)))
                            .foregroundStyle(viewModel.foregroundColor)
                            .padding(.horizontal, .DS.Padding.double)
                            .padding(.vertical, .DS.Padding.single)
                            .overlay {
                                RoundedRectangle(cornerRadius: .DS.Radius.small)
                                    .strokeBorder(Color(viewModel.displaySetting.color.foreground.withAlphaComponent(0.3)), lineWidth: 1.0)
                            }
                    }
                }
            }
        }

        private struct Strings {
            struct Preview {
                static let title = NSLocalizedString(
                    "reader.preferences.preview.title",
                    value: "Choose your Reading Preferences",
                    comment: "Title text for a preview"
                )

                static let tags = [
                    NSLocalizedString("reader.preferences.preview.tags.1", value: "dogs", comment: "Example tag for preview"),
                    NSLocalizedString("reader.preferences.preview.tags.2", value: "fox", comment: "Example tag for preview"),
                    NSLocalizedString("reader.preferences.preview.tags.3", value: "design", comment: "Example tag for preview"),
                    NSLocalizedString("reader.preferences.preview.tags.4", value: "writing", comment: "Example tag for preview"),
                ]

                static let feedbackLinkText = NSLocalizedString(
                    "reader.preferences.preview.body.feedbackLink",
                    value: "Send us a feedback on this feature",
                    comment: "Text for a feedback link for the Reader Preferences feature"
                )

                static let bodyDescription = NSLocalizedString(
                    "reader.preferences.preview.body.description",
                    value: "Reading is personal, we want you to have control. Choose the styles that suit you.",
                    comment: "Description text for the preview section of Reader Preferences"
                )

                static let bodyNotice = NSLocalizedString(
                    "reader.preferences.preview.body.notice",
                    value: "This feature is still in development.",
                    comment: "Footnote to be displayed in the preview section, noticing that the feature is in development."
                )
            }
        }
    }

}

// MARK: - Control View

extension ReaderDisplaySettingSelectionView {

    struct ControlView: View {
        @ObservedObject var viewModel: ReaderDisplaySettingSelectionViewModel

        @State private var sliderValue: Double

        init(viewModel: ReaderDisplaySettingSelectionViewModel) {
            self.viewModel = viewModel
            self.sliderValue = Double(viewModel.displaySetting.size.rawValue)
        }

        var body: some View {
            VStack(spacing: .DS.Padding.large) {
                colorSelectionView
                fontSelectionView
                sizeSelectionView
                    .padding(.horizontal, .DS.Padding.double)
                DSButton(title: Strings.doneButton, style: DSButtonStyle.init(emphasis: .primary, size: .large)) {
                    viewModel.doneButtonTapped()
                }
                .padding(.horizontal, .DS.Padding.double)
            }
            .padding(.top, .DS.Padding.medium)
            .padding(.bottom, .DS.Padding.single)
            .background(Color(.systemBackground))
        }

        var colorSelectionView: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .DS.Padding.half) {
                    ForEach(ReaderDisplaySetting.Color.allCases, id: \.rawValue) { color in
                        Button {
                            viewModel.displaySetting.color = color
                        } label: {
                            VStack(spacing: .DS.Padding.single) {
                                DualColorCircle(primaryColor: Color(color.foreground),
                                                secondaryColor: Color(color.background))
                                Text(color.label)
                                    .font(.footnote)
                                    .foregroundStyle(Color(.label))
                            }
                            .padding(.horizontal, .DS.Padding.split)
                            .padding(.vertical, .DS.Padding.single)
                            .overlay {
                                RoundedRectangle(cornerRadius: .DS.Radius.small)
                                    .strokeBorder(color == viewModel.displaySetting.color
                                                  ? .primary
                                                  : Color(UIColor.label.withAlphaComponent(0.1)), lineWidth: 1.0)
                            }
                        }
                    }
                }
                .padding(.leading, .DS.Padding.double) // initial content offset
            }
        }

        var fontSelectionView: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .DS.Padding.half) {
                    ForEach(ReaderDisplaySetting.Font.allCases, id: \.rawValue) { font in
                        Button {
                            viewModel.displaySetting.font = font
                        } label: {
                            VStack(spacing: .DS.Padding.half) {
                                Text("Aa")
                                    .font(Font(ReaderDisplaySetting.font(with: font, textStyle: .largeTitle)).bold())
                                    .foregroundStyle(Color(.label))
                                Text(font.rawValue.capitalized)
                                    .font(.footnote)
                                    .foregroundStyle(Color(.label))
                            }
                            .padding(.horizontal, .DS.Padding.double)
                            .padding(.vertical, .DS.Padding.single)
                            .overlay {
                                RoundedRectangle(cornerRadius: .DS.Radius.small)
                                    .strokeBorder(font == viewModel.displaySetting.font
                                                  ? .primary
                                                  : Color(UIColor.label.withAlphaComponent(0.1)), lineWidth: 1.0)
                            }
                        }
                    }
                }
                .padding(.leading, .DS.Padding.double) // initial content offset
            }
        }

        var sizeSelectionView: some View {
            Slider(value: $sliderValue,
                   in: Double(ReaderDisplaySetting.Size.extraSmall.rawValue)...Double(ReaderDisplaySetting.Size.extraLarge.rawValue),
                   step: 1) {
                Text(Strings.sizeSliderLabel)
            } minimumValueLabel: {
                Text("A")
                    .font(Font(ReaderDisplaySetting.font(with: .sans, size: .extraSmall, textStyle: .body)))
            } maximumValueLabel: {
                Text("A")
                    .font(Font(ReaderDisplaySetting.font(with: .sans, size: .extraLarge, textStyle: .body)))
            } onEditingChanged: { _ in
                viewModel.displaySetting.size = .init(rawValue: Int(sliderValue)) ?? .normal
            }
            .padding(.vertical, .DS.Padding.single)
        }
    }

    private struct Strings {
        static let doneButton = NSLocalizedString(
            "reader.preferences.control.doneButton",
            value: "Done",
            comment: "Title for a button to save and apply the customized Reader Preferences settings when tapped."
        )

        static let sizeSliderLabel = NSLocalizedString(
            "reader.preferences.control.sizeSlider.description",
            value: "Size",
            comment: "Describes that the slider is used to customize the text size in the Reader."
        )
    }
}

fileprivate struct DualColorCircle: View {
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(primaryColor)
                .overlay(content: {
                    Circle().strokeBorder(strokeColor(for: primaryColor), lineWidth: 0.5)
                })
                .clipShape(Circle().trim(from: 0.5, to: 1))
            Circle()
                .fill(secondaryColor)
                .overlay(content: {
                    Circle().strokeBorder(strokeColor(for: secondaryColor), lineWidth: 0.5)
                })
                .clipShape(Circle().trim(from: 0, to: 0.5))
        }
        .frame(width: 48.0, height: 48.0)
        .rotationEffect(.degrees(-45.0))
    }

    func strokeColor(for fillColor: Color) -> Color {
        guard fillColor == Color(UIColor.systemBackground) else {
            return .clear
        }
        return .secondary
    }
}
