import SwiftUI

class ReaderDisplaySettingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        let viewModel = ReaderDisplaySettingSelectionViewModel(displaySetting: .default)
        let swiftUIView = UIView.embedSwiftUIView(ReaderDisplaySettingSelectionView(viewModel: viewModel))
        view.addSubview(swiftUIView)
        view.pinSubviewToAllEdges(swiftUIView)
    }
}

// MARK: - SwiftUI

class ReaderDisplaySettingSelectionViewModel: NSObject, ObservableObject {

    @Published var displaySetting: ReaderDisplaySetting

    init(displaySetting: ReaderDisplaySetting) {
        self.displaySetting = displaySetting
    }
}

struct ReaderDisplaySettingSelectionView: View {

    @ObservedObject var viewModel: ReaderDisplaySettingSelectionViewModel

    @State private var sliderValue: Double = 0

    var body: some View {
        VStack(spacing: 24.0) {
            previewView
            colorSelectionView
            fontSelectionView
            sizeSelectionView

            // TODO: Add a 'Done' button

            Spacer()
        }
    }

    var previewView: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            Text("The quick brown fox jumps over the lazy dog")
                .font(Font(viewModel.displaySetting.font(with: .title1)))
                .foregroundStyle(foregroundColor)

            HStack(spacing: 8.0) {
                ForEach(["dogs", "fox", "design", "writing"], id: \.self) { text in
                    Text(text)
                        .font(Font(viewModel.displaySetting.font(with: .callout)))
                        .foregroundStyle(foregroundColor)
                        .padding(.horizontal, 16.0)
                        .padding(.vertical, 8.0)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5.0)
                                .strokeBorder(foregroundColor, lineWidth: 1.0)
                        }
                }
            }

            Text("Once upon a time, in a quaint little village nestled between rolling hills and lush greenery, there lived a quick brown fox named Jasper.")
                .font(Font(viewModel.displaySetting.font(with: .callout)))
                .foregroundStyle(foregroundColor)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(backgroundColor)
        .animation(.easeInOut, value: viewModel.displaySetting)
    }

    var colorSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4.0) {
                ForEach(ReaderDisplaySetting.Color.allCases, id: \.rawValue) { color in
                    Button {
                        viewModel.displaySetting.color = color
                    } label: {
                        VStack(spacing: 8.0) {
                            DualColorCircle(primaryColor: Color(color.foreground),
                                            secondaryColor: Color(color.background))
                            Text(color.label)
                                .font(.footnote)
                                .foregroundStyle(Color(.label))
                        }
                        .padding(.horizontal, 10.0)
                        .padding(.vertical, 8.0)
                        .clipShape(RoundedRectangle(cornerRadius: 5.0))
                        .overlay {
                            RoundedRectangle(cornerRadius: 5.0)
                                .strokeBorder(color == viewModel.displaySetting.color ? .secondary : Color(.secondarySystemBackground), lineWidth: 1.0)
                        }
                    }
                }
            }
            .padding(.leading, 16.0) // initial content inset
        }
    }

    var fontSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4.0) {
                ForEach(ReaderDisplaySetting.Font.allCases, id: \.rawValue) { font in
                    Button {
                        viewModel.displaySetting.font = font
                    } label: {
                        VStack(spacing: 4.0) {
                            Text("Aa")
                                .font(Font(ReaderDisplaySetting.font(with: font, textStyle: .largeTitle)).bold())
                                .foregroundStyle(Color(.label))
                            Text(font.rawValue.capitalized)
                                .font(.footnote)
                                .foregroundStyle(Color(.label))
                        }
                        .padding(.horizontal, 16.0)
                        .padding(.vertical, 8.0)
                        .clipShape(RoundedRectangle(cornerRadius: 5.0))
                        .overlay {
                            RoundedRectangle(cornerRadius: 5.0)
                                .strokeBorder(font == viewModel.displaySetting.font ? .secondary : Color(.secondarySystemBackground), lineWidth: 1.0)
                        }
                    }
                }
            }
            .padding(.leading, 16.0) // initial content inset
        }
    }

    var sizeSelectionView: some View {
        Slider(value: $sliderValue,
               in: Double(ReaderDisplaySetting.Size.smaller.rawValue)...Double(ReaderDisplaySetting.Size.larger.rawValue),
               step: 1) {
            Text("Size")
        } minimumValueLabel: {
            Text("A")
                .font(Font(ReaderDisplaySetting.font(with: .sans, size: .smaller, textStyle: .body)))
        } maximumValueLabel: {
            Text("A")
                .font(Font(ReaderDisplaySetting.font(with: .sans, size: .larger, textStyle: .body)))
        } onEditingChanged: { _ in
            viewModel.displaySetting.size = .init(rawValue: Int(sliderValue)) ?? .normal
        }
        .padding(.vertical, 8.0)
        .padding(.horizontal, 16.0)
    }

    private var foregroundColor: Color {
        Color(viewModel.displaySetting.color.foreground)
    }

    private var backgroundColor: Color {
        Color(viewModel.displaySetting.color.background)
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
