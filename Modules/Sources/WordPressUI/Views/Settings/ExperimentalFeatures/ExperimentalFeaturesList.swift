import SwiftUI

public struct ExperimentalFeaturesList: View {

    @ObservedObject
    var viewModel: ExperimentalFeaturesViewModel

    @AppStorage("isDeveloperModeEnabled")
    private var isDeveloperModeEnabled = false

    @State private var tapCount = 0

    package init(viewModel: ExperimentalFeaturesViewModel) {
        self.viewModel = viewModel
    }

    private var regularFeatures: [Feature] {
        viewModel.items.filter { !$0.isSuperExperimental }
    }

    private var developerFeatures: [Feature] {
        viewModel.items.filter { $0.isSuperExperimental }
    }

    public var body: some View {
        List {
            Section {
                ForEach(regularFeatures) { item in
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

                    if !isDeveloperModeEnabled {
                        HStack {
                            Spacer()
                            boltButton
                            Spacer()
                        }
                    }
                }
                .padding(.top, 8)
            }

            if isDeveloperModeEnabled && !developerFeatures.isEmpty {
                Section {
                    ForEach(developerFeatures) { item in
                        Toggle(item.name, isOn: viewModel.binding(for: item))
                    }
                } header: {
                    Text(Strings.developerToolsSectionTitle)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Strings.pageTitle)
        .task {
            await viewModel.loadItems()
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
                isDeveloperModeEnabled = true
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

        static let developerToolsSectionTitle = NSLocalizedString(
            "experimentalFeaturesList.developTools.section.title",
            value: "Developer Tools",
            comment: "Section title for developer tools"
        )
    }
}

#Preview {
    NavigationView {
        ExperimentalFeaturesList(viewModel: .withSampleData())
    }
}
