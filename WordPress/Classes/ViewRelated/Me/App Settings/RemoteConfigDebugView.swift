import SwiftUI

struct RemoteConfigDebugView: View {
    @StateObject private var viewModel = RemoteConfigDebugViewModel()

    var body: some View {
        List {
            listContent
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Strings.reset, action: viewModel.resetAll)
            }
        }
        .navigationTitle(Strings.title)
    }

    @ViewBuilder private var listContent: some View {
        ForEach(viewModel.parameters, id: \.self) { parameter in
            let (value, isOverriden) = viewModel.getValue(for: parameter)
            NavigationLink {
                RemoteConfigEditorView(viewModel: viewModel, parameter: parameter)
            } label: {
                RemoteConfigDebugRow(title: parameter.description, value: value ?? "–", isOverriden: isOverriden)
            }
        }
    }
}

private struct RemoteConfigDebugRow: View {
    let title: String
    let value: String
    var isOverriden = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                    if isOverriden {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(.blue)
                    }
                }
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RemoteConfigEditorView: View {
    @ObservedObject var viewModel: RemoteConfigDebugViewModel
    let parameter: RemoteConfigParameter

    @FocusState private var isTextFieldFocused: Bool
    private var store: RemoteConfigStore { viewModel.store }

    var body: some View {
        List {
            let binding = viewModel.binding(for: parameter)
            Section(Strings.overridenValue) {
                TextField(viewModel.getOriginalValue(for: parameter) ?? "", text: binding)
                    .focused($isTextFieldFocused, equals: true)
                Button(Strings.reset, role: .destructive) {
                    viewModel.reset(parameter)
                }.disabled(binding.wrappedValue.isEmpty)
            }
            Section {
                let value = store.value(for: parameter.key).map { String(describing: $0) }
                RemoteConfigDebugRow(title: Strings.currentValue, value: viewModel.getValue(for: parameter).value ?? "–")
                RemoteConfigDebugRow(title: Strings.remoteConfigValue, value: value ?? "–")
                RemoteConfigDebugRow(title: Strings.defaultValue, value: parameter.defaultValue?.description ?? "–")
            }
        }
        .onAppear { isTextFieldFocused = true }
        .navigationTitle(parameter.description)
    }
}

private final class RemoteConfigDebugViewModel: ObservableObject {
    @Published var parameters: [RemoteConfigParameter] = []
    @Published var searchText = "" {
        didSet { reload() }
    }

    let store = RemoteConfigStore()
    let overrideStore = RemoteConfigOverrideStore()

    init() {
        reload()
    }

    func binding(for parameter: RemoteConfigParameter) -> Binding<String> {
        Binding(get: {
            self.overrideStore.overriddenValue(for: parameter) ?? ""
        }, set: {
            if $0.isEmpty {
                self.overrideStore.reset(parameter)
            } else {
                self.overrideStore.override(parameter, withValue: $0)
            }
            self.objectWillChange.send()
        })
    }

    func getOriginalValue(for parameter: RemoteConfigParameter) -> String? {
        parameter.originalValue(using: store).map { String(describing: $0) }
    }

    func getValue(for parameter: RemoteConfigParameter) -> (value: String?, isOverriden: Bool) {
        let overridenValue = overrideStore.overriddenValue(for: parameter)
        let value = overridenValue ?? getOriginalValue(for: parameter)
        return (value, overridenValue != nil)
    }

    func reset(_ parameter: RemoteConfigParameter) {
        overrideStore.reset(parameter)
        objectWillChange.send()
    }

    func resetAll() {
        RemoteConfigParameter.allCases.forEach(reset)
    }

    private func reload() {
        parameters = RemoteConfigParameter.allCases.filter {
            guard !searchText.isEmpty else { return true }
            return $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("debugMenu.remoteConfig.title", value: "Remote Config", comment: "Remote Config Debug Menu screen title")
    static let reset = NSLocalizedString("debugMenu.remoteConfig.reset", value: "Reset", comment: "Remote Config Debug Menu reset button title")
    static let overridenValue = NSLocalizedString("debugMenu.remoteConfig.overridenValue", value: "Remote Config", comment: "Remote Config Debug Menu section title")
    static let currentValue = NSLocalizedString("debugMenu.remoteConfig.currentValue", value: "Current Value", comment: "Remote Config Debug Menu section title")
    static let remoteConfigValue = NSLocalizedString("debugMenu.remoteConfig.remoteConfigValue", value: "Remote Config Value", comment: "Remote Config Debug Menu section title")
    static let defaultValue = NSLocalizedString("debugMenu.remoteConfig.defaultValue", value: "Default Value", comment: "Remote Config Debug Menu section title")
}

private extension RemoteConfigParameter {
    func originalValue(using store: RemoteConfigStore = .init()) -> Any? {
        if let value = store.value(for: key) {
            return value
        }
        return defaultValue
    }
}
