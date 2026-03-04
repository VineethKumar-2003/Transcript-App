//
//  TranscriptEngine.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Foundation
import Speech
import AVFoundation

final class TranscriptEngine {

    static let shared = TranscriptEngine()

    private let recognizer = SFSpeechRecognizer()

    struct Progress {
        let current: Int
        let total: Int
    }

    func transcribe(
        videoURL: URL,
        progress: @escaping (Progress) -> Void
    ) async throws -> [TranscriptSegment] {

        let asset = AVURLAsset(url: videoURL)

        let chunker = AudioChunker()
        let session = try await chunker.createChunks(from: asset)
        let chunks = session.chunks

        var allSegments: [TranscriptSegment] = []
        var index = 0

        for chunk in chunks {

            let segments = try await transcribeChunk(chunk.url)

            let adjusted = segments.map {
                TranscriptSegment(
                    text: $0.text,
                    startTime: $0.startTime + chunk.startTime,
                    duration: $0.duration
                )
            }

            allSegments.append(contentsOf: adjusted)

            index += 1
            progress(.init(current: index, total: chunks.count))
        }

        let sorted = allSegments.sorted { $0.startTime < $1.startTime }

        try? FileManager.default.removeItem(at: session.folder)

        return sorted
    }

    private func transcribeChunk(_ url: URL) async throws -> [TranscriptSegment] {

        let request = SFSpeechURLRecognitionRequest(url: url)

        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        request.taskHint = .dictation

        return try await withCheckedThrowingContinuation { continuation in

            recognizer?.recognitionTask(with: request) { result, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else { return }

                if result.isFinal {

                    let segments = result.bestTranscription.segments.map {
                        TranscriptSegment(
                            text: $0.substring,
                            startTime: $0.timestamp,
                            duration: $0.duration
                        )
                    }

                    continuation.resume(returning: segments)
                }
            }
        }
    }
}
