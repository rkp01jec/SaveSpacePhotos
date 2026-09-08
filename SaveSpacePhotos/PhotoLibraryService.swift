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

    func requestAccess() async {
        authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func save(_ results: [CompressionResult]) async -> SaveReport {
        guard authorization == .authorized || authorization == .limited else {
            let message = "Photos access is required to save compressed copies."
            errorMessage = message
            return SaveReport(savedCount: 0, errorMessage: message)
        }

        do {
            guard let album = try await Self.fetchOrCreateAlbum() else {
                throw PhotoLibraryError.albumCreationFailed
            }
            let payloads = results.map {
                SavePayload(url: $0.outputURL, type: $0.outputType)
            }
            try await Self.save(payloads, to: album)
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

    private static func fetchOrCreateAlbum() async throws -> PHAssetCollection? {
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

        let identifier = try await withCheckedThrowingContinuation { continuation in
            let box = PlaceholderBox()
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
                box.identifier = request.placeholderForCreatedAssetCollection.localIdentifier
            } completionHandler: { success, error in
                if success, let identifier = box.identifier {
                    continuation.resume(returning: identifier)
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.albumCreationFailed)
                }
            }
        }

        return PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [identifier],
            options: nil
        ).firstObject
    }

    private static func save(_ payloads: [SavePayload], to album: PHAssetCollection) async throws {
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let albumRequest = PHAssetCollectionChangeRequest(for: album)
                var placeholders: [PHObjectPlaceholder] = []

                for payload in payloads {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    let resourceType: PHAssetResourceType = payload.type == .video ? .video : .photo
                    creationRequest.addResource(with: resourceType, fileURL: payload.url, options: nil)
                    if let placeholder = creationRequest.placeholderForCreatedAsset {
                        placeholders.append(placeholder)
                    }
                }
                albumRequest?.addAssets(placeholders as NSArray)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                }
            }
        }
    }
}

private final class PlaceholderBox: @unchecked Sendable {
    var identifier: String?
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
