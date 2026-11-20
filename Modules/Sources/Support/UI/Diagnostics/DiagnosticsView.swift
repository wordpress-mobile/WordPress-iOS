import SwiftUI
import UIKit
import WordPressCoreProtocols

public struct DiagnosticsView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(Localization.diagnosticsDescription)
                    .foregroundStyle(.secondary)

                EmptyDiskCacheView()
            }
            .padding()
        }
        .navigationTitle(Localization.diagnosticsTitle)
        // Grouped, to match the support list this is pushed from. `DiagnosticCard` is filled
        // with the secondary grouped colour so it stands out against this background.
        .background(Color(.systemGroupedBackground))
        .onAppear {
            dataProvider.userDid(.viewDiagnostics)
        }
    }
}

#Preview {
    DiagnosticsView()
}
