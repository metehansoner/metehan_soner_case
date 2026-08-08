import Photos


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
