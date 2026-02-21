import Foundation
import SwiftUI
import PhotosUI

class PhotoStorageService {
    static let shared = PhotoStorageService()

    private init() {}

    func uploadPhoto(item: PhotosPickerItem, journalId: String) async throws -> String {
        // Load image data
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            throw PhotoUploadError.failedToLoadImage
        }

        // Generate unique filename
        let filename = "\(journalId)_\(UUID().uuidString).jpg"
        let filepath = "journal_photos/\(filename)"

        // Upload to Supabase Storage
        _ = try await SupabaseService.shared.client
            .storage
            .from("journals")
            .upload(filepath, data: data)

        // Get public URL
        let url = try SupabaseService.shared.client
            .storage
            .from("journals")
            .getPublicURL(path: filepath)

        return url.absoluteString
    }

    func deletePhoto(url: String) async throws {
        // Extract path from URL
        guard let path = extractPath(from: url) else { return }

        try await SupabaseService.shared.client
            .storage
            .from("journals")
            .remove(paths: [path])
    }

    private func extractPath(from url: String) -> String? {
        // Extract "journal_photos/xxx.jpg" from full URL
        guard let range = url.range(of: "journal_photos/") else { return nil }
        return String(url[range.lowerBound...])
    }

    enum PhotoUploadError: Error {
        case failedToLoadImage
        case uploadFailed
    }
}
