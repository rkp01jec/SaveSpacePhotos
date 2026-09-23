import Foundation
import Photos
import SwiftUI

struct SaveReport: Sendable {
    let savedCount: Int
    let errorMessage: String?
}

@MainActor
final class PhotoLibraryService: ObservableObject {
    private static let albumTitle = "SaveSpace Photos"

    @Published private(set) var authorization: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var errorMessage: String?

    func refreshAuthorization() {
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("PhotoLibraryService authorization is now: \(authorization.rawValue)")
        if authorization == .authorized || authorization == .limited {
            errorMessage = nil
        }
    }
    @discardableResult
    func requestAccessIfNeeded() async -> Bool {
        refreshAuthorization()
        if authorization == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            refreshAuthorization()
        }
        guard authorization == .authorized || authorization == .limited else {
            if authorization == .restricted {
                errorMessage = "Photos access is restricted on this device. Ask the device administrator to allow Photos access."
            } else {
                errorMessage = "Photos access is denied. Allow access in Settings to choose and save compressed copies."
            }
            return false
        }
        return true
    }

    func save(_ results: [CompressionResult]) async -> SaveReport {
        refreshAuthorization()
        guard authorization == .authorized || authorization == .limited else {
            let message = "Photos access is required to save compressed copies."
            errorMessage = message
            return SaveReport(savedCount: 0, errorMessage: message)
        }

        do {
            guard let album = try Self.fetchOrCreateAlbum() else {
                throw PhotoLibraryError.albumCreationFailed
            }
            let payloads = results.map {
                SavePayload(url: $0.outputURL, type: $0.outputType)
            }
            try Self.save(payloads, to: album)
            return SaveReport(savedCount: results.count, errorMessage: nil)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            return SaveReport(savedCount: 0, errorMessage: message)
        }
    }

    private struct SavePayload: Sendable {
        let url: URL
        let type: MediaType
    }

    nonisolated private static func fetchOrCreateAlbum() throws -> PHAssetCollection? {
        let fetch = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )
        var existing: PHAssetCollection?
        fetch.enumerateObjects { collection, _, stop in
            if collection.localizedTitle == albumTitle {
                existing = collection
                stop.pointee = true
            }
        }
        if let existing { return existing }

        try PHPhotoLibrary.shared().performChangesAndWait {
            _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
        }
        let createdAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        var createdAlbum: PHAssetCollection?
        createdAlbums.enumerateObjects { collection, _, stop in
            if collection.localizedTitle == albumTitle {
                createdAlbum = collection
                stop.pointee = true
            }
        }
        return createdAlbum
    }

    nonisolated private static func save(_ payloads: [SavePayload], to album: PHAssetCollection) throws {
        try PHPhotoLibrary.shared().performChangesAndWait {
            let albumRequest = PHAssetCollectionChangeRequest(for: album)

            for payload in payloads {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let resourceType: PHAssetResourceType = payload.type == .video ? .video : .photo
                creationRequest.addResource(with: resourceType, fileURL: payload.url, options: nil)
                if let placeholder = creationRequest.placeholderForCreatedAsset {
                    albumRequest?.addAssets([placeholder] as NSArray)
                }
            }
        }
    }
}

private enum PhotoLibraryError: LocalizedError {
    case albumCreationFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .albumCreationFailed: "The SaveSpace Photos album could not be created."
        case .saveFailed: "The compressed copies could not be saved to Photos."
        }
    }
}
