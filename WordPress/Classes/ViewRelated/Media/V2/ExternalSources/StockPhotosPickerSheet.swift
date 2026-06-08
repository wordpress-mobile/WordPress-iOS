import SwiftUI
import WordPressKit // WordPressComRestApi lives here (see DefaultStockPhotosService.swift:1-20)
import WordPressMediaLibrary

struct StockPhotosPickerSheet: View {
    let api: WordPressComRestApi
    let delegate: any ExternalMediaPickerDelegate

    var body: some View {
        ExternalMediaPickerSheet(
            title: Strings.pickFromStockPhotos,
            source: .stockPhotos,
            makeDataSource: { StockPhotosDataSource(service: DefaultStockPhotosService(api: api)) },
            makeWelcomeView: { StockPhotosWelcomeView() },
            mapAsset: ExternalRemoteMedia.init(stockPhotosAsset:),
            delegate: delegate
        )
    }
}

private enum Strings {
    static let pickFromStockPhotos = NSLocalizedString(
        "mediaLibrary.v2.stockPhotos.title",
        value: "Free Photo Library",
        comment: "Title of the Stock Photos picker (matches V1 MediaPickerMenu+External.swift)"
    )
}
