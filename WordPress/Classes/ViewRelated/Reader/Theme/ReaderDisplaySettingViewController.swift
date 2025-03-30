import SwiftUI
import DesignSystem
import WordPressReader
import WordPressShared

/// The tracking source values for the customization sheet.
/// The values are kept in sync with Android.
enum ReaderDisplaySettingViewSource: String {
    case readerPostNavBar = "post_detail_toolbar"
    case unspecified
}

class ReaderDisplaySettingViewController: UIViewController {
    private let initialSetting: ReaderDisplaySettings
    private let completion: ((ReaderDisplaySettings) -> Void)?
    private let trackingSource: ReaderDisplaySettingViewSource
    private var viewModel: ReaderDisplaySettingSelectionViewModel? = nil

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(initialSetting: ReaderDisplaySettings,
         source: ReaderDisplaySettingViewSource = .unspecified,
         completion: ((ReaderDisplaySettings) -> Void)?) {
        self.initialSetting = initialSetting
        self.completion = completion
        self.trackingSource = source

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationItems()
        trackViewOpened()
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        let viewModel = ReaderDisplaySettingSelectionViewModel(displaySetting: initialSetting) { [weak self] setting in
            self?.dismiss(animated: true, completion: {
                self?.completion?(setting)
            })
        }

        viewModel.didSelectItem = { [weak self] in
            // since the navigation bar is transparent, we need to override the interface style so that
            // the navigation items remain visible with the new color.
            self?.updateNavigationBar(with: viewModel.displaySetting)
        }

        let swiftUIView = UIView.embedSwiftUIView(ReaderDisplaySettingSelectionView(viewModel: viewModel))
        view.addSubview(swiftUIView)
        view.pinSubviewToAllEdges(swiftUIView)

        self.viewModel = viewModel
    }

    private func setupNavigationItems() {
        guard let displaySetting = viewModel?.displaySetting else {
            return
        }

        // add the experimental label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.text = Constants.experimentalText
        navigationItem.leftBarButtonItem = .init(customView: label)

        // add close button
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            WPAnalytics.track(.readingPreferencesClosed)
            self?.navigationController?.dismiss(animated: true)
        })

        updateNavigationBar(with: displaySetting)
    }

    private func trackViewOpened() {
        WPAnalytics.track(.readingPreferencesOpened, properties: ["source": trackingSource.rawValue])
    }

    @MainActor
    private func updateNavigationBar(with setting: ReaderDisplaySettings) {
        navigationController?.navigationBar.overrideUserInterfaceStyle = setting.hasLightBackground ? .light : .dark

        // update the experimental label style
        if let label = navigationItem.leftBarButtonItem?.customView as? UILabel {
            label.font = setting.font(with: .footnote, weight: .semibold)
            label.textColor = setting.color.secondaryForeground
        }
    }

    private struct Constants {
        // matches SwiftUI's `easeInOut` default animation duration.
        // see: https://developer.apple.com/documentation/swiftui/animation/easeinout#discussion
        static let animationDuration: TimeInterval = 0.35

        static let experimentalText = NSLocalizedString(
            "reader.preferences.navBar.experimental.label",
            value: "<Experimental>",
            comment: """
                Text for a small label in the navigation bar that hints that this is an experimental feature.

                The enclosing angled brackets ('<' and '>') are decorative and only intended as a flavor.
                Feel free to replace it with other bracket types that you think looks better for the locale.
                """
        )
    }
}

// MARK: - SwiftUI

// MARK: View Model

class ReaderDisplaySettingSelectionViewModel: NSObject, ObservableObject {
    private typealias TrackingKeys = ReaderDisplaySettingSelectionView.TrackingKeys

    @Published var displaySetting: ReaderDisplaySettings

    /// Called when the user selects a new option.
    var didSelectItem: (() -> Void)? = nil

    private let completion: ((ReaderDisplaySettings) -> Void)?

    init(displaySetting: ReaderDisplaySettings, completion: ((ReaderDisplaySettings) -> Void)?) {
        self.displaySetting = displaySetting
        self.completion = completion
    }

    func doneButtonTapped() {
        WPAnalytics.track(.readingPreferencesSaved, properties: [
            TrackingKeys.isDefault: displaySetting.isDefaultSetting,
            TrackingKeys.colorScheme: displaySetting.color.valueForTracks,
            TrackingKeys.fontType: displaySetting.font.valueForTracks,
            TrackingKeys.fontSize: displaySetting.size.valueForTracks,
        ])

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

    @State private var viewHeight: CGFloat = .zero

    @State private var controlViewIntrinsicHeight: CGFloat = .zero

    var body: some View {
        VStack(spacing: .zero) {
            PreviewView(viewModel: viewModel)

            ScrollView(.vertical) {
                ControlView(viewModel: viewModel)
                    .background {
                        GeometryReader { proxy in
                            Color.clear.onAppear {
                                self.controlViewIntrinsicHeight = proxy.size.height
                            }
                        }
                    }
            }
            .overlay(alignment: .top, content: { // add a thin top border.
                Rectangle()
                    .ignoresSafeArea()
                    .frame(width: nil, height: .hairlineBorderWidth, alignment: .top)
                    .foregroundStyle(Color(.tertiaryLabel))
            })
            // if there's enough space to show the entire control view, shrink the scroll view to fit.
            // otherwise, we're going to limit the height so that the preview section remains visible.
            .frame(height: min(controlViewIntrinsicHeight, viewHeight * Constants.maxControlViewHeightRatio))
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear(perform: {
                        self.viewHeight = proxy.size.height
                    })
                    .onChange(of: proxy.size.height) { newValue in
                        // update value in case of orientation change.
                        self.viewHeight = newValue
                    }
            }
        }
    }

    private struct Constants {
        /// The ratio of the screen height to be used for defining the max height of the control view.
        static let maxControlViewHeightRatio = 0.6
    }
}

// MARK: - Preview View

extension ReaderDisplaySettingSelectionView {

    struct PreviewView: View {
        @ObservedObject var viewModel: ReaderDisplaySettingSelectionViewModel

        @Environment(\.openURL) private var openURL

        var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: .DS.Padding.double) {
                    Text(Strings.title)
                        .font(Font(viewModel.displaySetting.font(with: .title1, weight: .semibold)))
                        .foregroundStyle(viewModel.foregroundColor)

                    Text(Strings.bodyText)
                        .font(Font(viewModel.displaySetting.font(with: .callout)))
                        .foregroundStyle(viewModel.foregroundColor)

                    tagsView

                    Spacer()
                }
                .padding(.DS.Padding.double)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .mask({
                // adds a soft gradient mask that hints that there are more content to scroll.
                VStack(spacing: .zero) {
                    Rectangle().fill(.black)
                    LinearGradient(gradient: Gradient(colors: [.black, .clear]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                    .frame(height: Constants.gradientMaskHeight)
                }
            })
            .background(viewModel.backgroundColor)
            .animation(.easeInOut, value: viewModel.displaySetting)
        }

        var linkTintColor: UIColor {
            viewModel.displaySetting.color == .system ? UIAppColor.blue : viewModel.displaySetting.color.foreground
        }

        var tagsView: some View {
            ScrollView(.horizontal) {
                HStack(spacing: .DS.Padding.single) {
                    ForEach(Strings.tags, id: \.self) { text in
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Strings.tagsListAccessibilityLabel)
            }
        }

        private struct Constants {
            static let gradientMaskHeight = 32.0
        }

        private struct Strings {
            static let title = NSLocalizedString(
                "reader.preferences.preview.header",
                value: "Reading Preferences",
                comment: "Title text for a preview"
            )

            static let bodyText = NSLocalizedString(
                "reader.preferences.preview.body.text",
                value: "Choose your colors, fonts, and sizes. Preview your selection here, and read posts with your styles once you're done.",
                comment: "Description text for the preview section of Reader Preferences"
            )

            static let tags = [
                NSLocalizedString("reader.preferences.preview.tags.reading", value: "reading", comment: "Example tag for preview"),
                NSLocalizedString("reader.preferences.preview.tags.colors", value: "colors", comment: "Example tag for preview"),
                NSLocalizedString("reader.preferences.preview.tags.fonts", value: "fonts", comment: "Example tag for preview"),
            ]

            static let tagsListAccessibilityLabel = NSLocalizedString(
                "reader.preferences.preview.tagsList.a11y",
                value: "Example tags",
                comment: "Accessibility label for a list of tags in the preview section."
            )
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
                    ForEach(ReaderDisplaySettings.Color.allCases, id: \.rawValue) { color in
                        Button {
                            viewModel.displaySetting.color = color
                            viewModel.didSelectItem?() // notify the view controller to update.
                            WPAnalytics.track(.readingPreferencesItemTapped,
                                              properties: [TrackingKeys.typeKey: TrackingKeys.colorScheme,
                                                           TrackingKeys.valueKey: color.valueForTracks])
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
                        .accessibilityAddTraits(color == viewModel.displaySetting.color ? .isSelected : [])
                    }
                }
                .padding(.leading, .DS.Padding.double) // initial content offset
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Strings.colorListAccessibilityLabel)
            }
        }

        var fontSelectionView: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .DS.Padding.half) {
                    ForEach(ReaderDisplaySettings.Font.allCases, id: \.rawValue) { font in
                        Button {
                            viewModel.displaySetting.font = font
                            viewModel.didSelectItem?() // notify the view controller to update.
                            WPAnalytics.track(.readingPreferencesItemTapped,
                                              properties: [TrackingKeys.typeKey: TrackingKeys.fontType,
                                                           TrackingKeys.valueKey: font.rawValue])
                        } label: {
                            VStack(spacing: .DS.Padding.half) {
                                Text("Aa")
                                    .font(Font(ReaderDisplaySettings.font(with: font, textStyle: .largeTitle)).bold())
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
                        .accessibilityAddTraits(font == viewModel.displaySetting.font ? .isSelected : [])
                        .accessibilityLabel(font.rawValue.capitalized)
                    }
                }
                .padding(.leading, .DS.Padding.double) // initial content offset
            }
        }

        var sizeSelectionView: some View {
            Slider(value: $sliderValue,
                   in: Double(ReaderDisplaySettings.Size.extraSmall.rawValue)...Double(ReaderDisplaySettings.Size.extraLarge.rawValue),
                   step: 1) {
                Text(Strings.sizeSliderLabel)
            } minimumValueLabel: {
                Text("A")
                    .font(Font(ReaderDisplaySettings.font(with: .sans, size: .extraSmall, textStyle: .body)))
                    .accessibilityHidden(true)
            } maximumValueLabel: {
                Text("A")
                    .font(Font(ReaderDisplaySettings.font(with: .sans, size: .extraLarge, textStyle: .body)))
                    .accessibilityHidden(true)
            } onEditingChanged: { _ in
                let size = ReaderDisplaySettings.Size(rawValue: Int(sliderValue)) ?? .normal
                viewModel.displaySetting.size = size
                viewModel.didSelectItem?() // notify the view controller to update.
                WPAnalytics.track(.readingPreferencesItemTapped,
                                  properties: [TrackingKeys.typeKey: TrackingKeys.fontSize,
                                               TrackingKeys.valueKey: size.valueForTracks])
            }
            .padding(.vertical, .DS.Padding.single)
            .accessibilityValue(Text(viewModel.displaySetting.size.accessibilityLabel))
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

        static let colorListAccessibilityLabel = NSLocalizedString(
            "reader.preferences.control.colors.a11y",
            value: "Colors",
            comment: "Accessibility label describing the list of colors to be selected from."
        )

        static let fontListAccessibilityLabel = NSLocalizedString(
            "reader.preferences.control.fonts.a11y",
            value: "Fonts",
            comment: "Accessibility label describing the list of fonts to be selected from."
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

// MARK: - Tracks

fileprivate extension ReaderDisplaySettingSelectionView {

    struct TrackingKeys {
        static let typeKey = "type"
        static let valueKey = "value"
        static let colorScheme = "color_scheme"
        static let fontType = "font"
        static let fontSize = "font_size"
        static let isDefault = "is_default"
    }
}
