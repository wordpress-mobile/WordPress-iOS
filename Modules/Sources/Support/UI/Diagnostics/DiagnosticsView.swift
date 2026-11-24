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
        // Reached from Me, so it takes Me's grouped background rather than the plain one.
        // `.thinMaterial` is what the card is filled with, and it only reads as a card
        // against the grouped grey.
        .background(Color(.systemGroupedBackground))
        .onAppear {
            dataProvider.userDid(.viewDiagnostics)
        }
    }
}

#Preview {
    DiagnosticsView()
}
