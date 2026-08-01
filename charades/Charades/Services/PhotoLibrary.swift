import Photos

/// §04 §4.3–4.4: arşiv kartının ve oynatıcının `Photos'a Kaydet` eylemi.
///
/// İzin **yalnızca ekleme** için isteniyor (`.addOnly`): uygulamanın kullanıcının
/// mevcut fotoğraflarını okuması için hiçbir sebep yok ve tam erişim istemek
/// gereksiz bir izin diyaloğu ile reddedilme sebebi.
enum PhotoLibrary {

    enum Result {
        case saved
        case denied
        case failed
    }

    static func save(_ urls: [URL]) async -> Result {
        guard !urls.isEmpty else { return .failed }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return .denied }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                for url in urls {
                    let request = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    // Kayıt arşivde kalmaya devam ediyor; Photos kendi kopyasını alıyor.
                    options.shouldMoveFile = false
                    request.addResource(with: .video, fileURL: url, options: options)
                }
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
