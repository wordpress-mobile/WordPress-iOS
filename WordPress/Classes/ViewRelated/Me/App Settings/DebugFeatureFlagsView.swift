import SwiftUI

struct DebugFeatureFlagsView: View {
    @StateObject private var viewModel = DebugFeatureFlagsViewModel()

    var body: some View {
        List {
            sections
        }
        .tint(Color(UIColor.jetpackGreen))
        .listStyle(.grouped)
        .searchable(text: $viewModel.filterTerm, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .apply(addToolbarTitleMenu)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu(content: {
                    Button("Enable All Flags", action: viewModel.enableAllFlags)
                    Button("Reset All Flags", role: .destructive, action: viewModel.reset)
                }, label: {
                    Image(systemName: "ellipsis.circle")
                })
            }
        }
    }

    @ViewBuilder
    private var sections: some View {
        let remoteFlags = viewModel.getRemoteFeatureFlags()
        if !remoteFlags.isEmpty {
            Section("Remote Feature Flags") {
                ForEach(remoteFlags, id: \.self) { flag in
                    makeToggle(flag.description, isOn: viewModel.binding(for: flag), isOverriden: viewModel.isOverriden(flag))
                }
            }
        }

        let localFlags = viewModel.getLocalFeatureFlags()
        if !localFlags.isEmpty {
            Section("Local Feature Flags") {
                ForEach(localFlags, id: \.self) { flag in
                    makeToggle(flag.description, isOn: viewModel.binding(for: flag), isOverriden: viewModel.isOverriden(flag))
                }
            }
        }
    }

    private func makeToggle(_ title: String, isOn: Binding<Bool>, isOverriden: Bool) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading) {
                Text(title)
                if isOverriden {
                    Text("Overriden")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    func addToolbarTitleMenu<T: View>(_ view: T) -> some View {
        if #available(iOS 16, *) {
            view.toolbarTitleMenu {
                Picker("Filter", selection: $viewModel.filter) {
                    Text("Feature Flags (All)").tag(DebugFeatureFlagFilter.all)
                    Text("Remote Feature Flags").tag(DebugFeatureFlagFilter.remote)
                    Text("Local Feature Flags").tag(DebugFeatureFlagFilter.local)
                    Text("Overriden Feature Flags").tag(DebugFeatureFlagFilter.overriden)
                }.pickerStyle(.inline)
            }
        } else {
            view
        }
    }

    private var navigationTitle: String {
        switch viewModel.filter {
        case .all: return "Feature Flags"
        case .remote: return "Remote Feature Flags"
        case .local: return "Local Feature Flags"
        case .overriden: return "Overriden Feature Flags"
        }
    }
}

private final class DebugFeatureFlagsViewModel: ObservableObject {
    private let remoteStore = RemoteFeatureFlagStore()
    private let overrideStore = FeatureFlagOverrideStore()

    private let allRemoteFlags = RemoteFeatureFlag.allCases.filter(\.canOverride)
    private let allLocalFlags = FeatureFlag.allCases.filter(\.canOverride)

    @Published var filter: DebugFeatureFlagFilter = .all
    @Published var filterTerm = ""

    // MARK: Remote Feature Flags

    func getRemoteFeatureFlags() -> [RemoteFeatureFlag] {
        allRemoteFlags.filter {
            switch filter {
            case .all, .remote: return true
            case .local: return false
            case .overriden: return isOverriden($0)
            }
        }.filter {
            guard !filterTerm.isEmpty else { return true }
            return $0.description.localizedCaseInsensitiveContains(filterTerm) ||
            $0.remoteKey.contains(filterTerm)
        }
    }

    func binding(for flag: RemoteFeatureFlag) -> Binding<Bool> {
        Binding(get: { [unowned self] in
            flag.enabled(using: remoteStore, overrideStore: overrideStore)
        }, set: { [unowned self] in
            override(flag, withValue: $0)
        })
    }

    func isOverriden(_ flag: OverridableFlag) -> Bool {
        overrideStore.isOverridden(flag)
    }

    private func override(_ flag: OverridableFlag, withValue value: Bool) {
        try? overrideStore.override(flag, withValue: value)
        objectWillChange.send()
    }

    // MARK: Local Feature Flags

    func getLocalFeatureFlags() -> [FeatureFlag] {
        allLocalFlags.filter {
            switch filter {
            case .all, .local: return true
            case .remote: return false
            case .overriden: return isOverriden($0)
            }
        }.filter {
            guard !filterTerm.isEmpty else { return true }
            return $0.description.localizedCaseInsensitiveContains(filterTerm)
        }
    }

    func binding(for flag: FeatureFlag) -> Binding<Bool> {
        Binding(get: {
            flag.enabled
        }, set: { [unowned self] in
            override(flag, withValue: $0)
        })
    }

    // MARK: Actions

    func enableAllFlags() {
        for flag in RemoteFeatureFlag.allCases where !flag.enabled() {
            try? overrideStore.override(flag, withValue: true)
        }
        for flag in FeatureFlag.allCases where !flag.enabled {
            try? overrideStore.override(flag, withValue: true)
        }
        objectWillChange.send()
    }

    func reset() {
        for flag in RemoteFeatureFlag.allCases {
            overrideStore.removeOverride(for: flag)
        }
        for flag in FeatureFlag.allCases {
            overrideStore.removeOverride(for: flag)
        }
        objectWillChange.send()
    }
}

private enum DebugFeatureFlagFilter: Hashable {
    case all
    case remote
    case local
    case overriden
}
