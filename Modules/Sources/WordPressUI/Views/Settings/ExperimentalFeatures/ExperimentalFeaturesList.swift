import SwiftUI

public struct ExperimentalFeaturesList: View {

    @ObservedObject
    var viewModel: ExperimentalFeaturesViewModel

    @AppStorage("superExperimentalFeaturesEnabled")
    private var superExperimentalFeaturesEnabled = false

    @AppStorage("pulseEnabled")
    private var pulseEnabled = false

    @State private var tapCount = 0
    @State private var showPulseAlert = false

    package init(viewModel: ExperimentalFeaturesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            Section {
                ForEach(viewModel.items) { item in
                    Toggle(item.name, isOn: viewModel.binding(for: item))
                }
            } footer: {
                VStack(alignment: .leading, spacing: 12) {
                    if !viewModel.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.notes, id: \.self) { note in
                                Text(note)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if !superExperimentalFeaturesEnabled {
                        HStack {
                            Spacer()
                            boltButton
                            Spacer()
                        }
                    }
                }
                .padding(.top, 8)
            }

            if superExperimentalFeaturesEnabled {
                Section {
                    Toggle("Pulse", isOn: $pulseEnabled)
                        .onChange(of: pulseEnabled) { oldValue, newValue in
                            if newValue {
                                showPulseAlert = true
                            }
                        }
                } header: {
                    Text("Super Experimental Features")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Strings.pageTitle)
        .task {
            await viewModel.loadItems()
        }
        .alert(Strings.pulseAlertTitle, isPresented: $showPulseAlert) {
            Button(Strings.pulseAlertCancel, role: .cancel) {
                pulseEnabled = false
            }
            Button(Strings.pulseAlertConfirm) {
                // User confirmed, keep pulseEnabled = true
                // In a real implementation, this would trigger an app restart
            }
        } message: {
            Text(Strings.pulseAlertMessage)
        }
    }

    private var boltButton: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: 20))
            .foregroundColor(.secondary)
            .symbolEffect(.bounce.up, value: tapCount)
            .onTapGesture {
                handleBoltTap()
            }
    }

    private func handleBoltTap() {
        tapCount += 1

        let generator = UIImpactFeedbackGenerator(style: impactStyle(for: tapCount))
        generator.impactOccurred()

        if tapCount >= 5 {
            withAnimation {
                superExperimentalFeaturesEnabled = true
            }
        }
    }

    private func impactStyle(for count: Int) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch count {
        case 1: return .light
        case 2: return .medium
        case 3: return .heavy
        case 4: return .rigid
        default: return .rigid
        }
    }

    public static func asViewController(
        viewModel: ExperimentalFeaturesViewModel
    ) -> UIHostingController<Self> {
        let rootView = ExperimentalFeaturesList(viewModel: viewModel)

        let vc = UIHostingController(rootView: rootView)
        vc.title = Strings.pageTitle
        return vc
    }

    enum Strings {
        static let pageTitle = NSLocalizedString(
            "experimentalFeaturesList.heading",
            value: "Experimental Features",
            comment: "The title for the experimental features list"
        )

        static let pulseAlertTitle = NSLocalizedString(
            "experimentalFeaturesList.pulse.alert.title",
            value: "Enable Pulse Logging?",
            comment: "Alert title when enabling Pulse logging feature"
        )

        static let pulseAlertMessage = NSLocalizedString(
            "experimentalFeaturesList.pulse.alert.message",
            value: "This will enable extensive local logging for debugging purposes and add a new Logger row in App Settings. This is not recommended unless you know what you're doing. The app will restart to apply changes.",
            comment: "Alert message explaining Pulse logging feature and warning users"
        )

        static let pulseAlertConfirm = NSLocalizedString(
            "experimentalFeaturesList.pulse.alert.confirm",
            value: "Apply & Restart",
            comment: "Button to confirm enabling Pulse logging and restart the app"
        )

        static let pulseAlertCancel = NSLocalizedString(
            "experimentalFeaturesList.pulse.alert.cancel",
            value: "Cancel",
            comment: "Button to cancel enabling Pulse logging"
        )
    }
}

#Preview {
    NavigationView {
        ExperimentalFeaturesList(viewModel: .withSampleData())
    }
}
