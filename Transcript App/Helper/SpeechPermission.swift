//
//  SpeechPermission.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Speech

enum SpeechPermissionError: LocalizedError {
    case denied
    case restricted
    case notDetermined

    var errorDescription: String? {
        switch self {
        case .denied:
            "Speech recognition permission is denied. Enable it in Settings."
        case .restricted:
            "Speech recognition is restricted on this device."
        case .notDetermined:
            "Speech recognition permission was not determined."
        }
    }
}

enum SpeechPermission {
    static func request() async throws {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        switch status {
        case .authorized:
            return
        case .denied:
            throw SpeechPermissionError.denied
        case .restricted:
            throw SpeechPermissionError.restricted
        case .notDetermined:
            throw SpeechPermissionError.notDetermined
        @unknown default:
            throw SpeechPermissionError.denied
        }
    }
}
