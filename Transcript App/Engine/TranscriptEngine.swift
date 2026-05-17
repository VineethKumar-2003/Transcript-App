//
//  TranscriptEngine.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import AVFoundation
import Foundation
import Speech

final class TranscriptEngine {
    static let shared = TranscriptEngine()

    private let recognitionLocale = Locale(identifier: "en-US")

    struct Progress {
        let current: Int
        let total: Int
    }

    func transcribe(
        videoURL: URL,
        progress: @escaping (Progress) -> Void,
    ) async throws -> [TranscriptSegment] {
        let asset = AVURLAsset(url: videoURL)

        let chunker = AudioChunker()
        let session = try await chunker.createChunks(from: asset)
        defer { try? FileManager.default.removeItem(at: session.folder) }

        let chunks = session.chunks
        let total = chunks.count

        var completed = 0
        var allSegments: [TranscriptSegment] = []
        var allowOnDeviceRecognition = true

        for chunk in chunks {
            try Task.checkCancellation()

            let result: [TranscriptSegment]

            do {
                result = try await transcribeChunkAdjusted(
                    chunk,
                    allowOnDeviceRecognition: allowOnDeviceRecognition,
                )
            } catch {
                if isLocalSpeechServiceError(error), allowOnDeviceRecognition {
                    allowOnDeviceRecognition = false
                    result = try await transcribeChunkAdjusted(
                        chunk,
                        allowOnDeviceRecognition: false,
                    )
                } else {
                    throw error
                }
            }

            allSegments.append(contentsOf: result)

            completed += 1
            progress(.init(current: completed, total: total))
        }

        return allSegments.sorted { $0.startTime < $1.startTime }
    }

    private func transcribeChunkAdjusted(
        _ chunk: AudioChunker.Chunk,
        allowOnDeviceRecognition: Bool = true,
    ) async throws -> [TranscriptSegment] {
        let segments = try await transcribeChunk(
            chunk.url,
            allowOnDeviceRecognition: allowOnDeviceRecognition,
        )

        return segments.map {
            TranscriptSegment(
                text: $0.text,
                startTime: $0.startTime + chunk.startTime,
                duration: $0.duration,
            )
        }
    }

    private func transcribeChunk(
        _ url: URL,
        allowOnDeviceRecognition: Bool,
    ) async throws -> [TranscriptSegment] {
        let maxAttempts = 3
        var attempt = 1

        while true {
            try Task.checkCancellation()

            do {
                return try await transcribeChunkOnce(
                    url,
                    allowOnDeviceRecognition: allowOnDeviceRecognition && attempt == 1,
                )
            } catch {
                if isNoSpeechError(error) {
                    return []
                }

                guard isLocalSpeechServiceError(error), attempt < maxAttempts else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(nanoseconds: 350_000_000)
            }
        }
    }

    private func transcribeChunkOnce(
        _ url: URL,
        allowOnDeviceRecognition: Bool,
    ) async throws -> [TranscriptSegment] {
        guard let recognizer = SFSpeechRecognizer(locale: recognitionLocale) else {
            throw NSError(
                domain: "TranscriptEngine",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is unavailable for this locale."],
            )
        }

        let request = SFSpeechURLRecognitionRequest(url: url)

        request.requiresOnDeviceRecognition =
            allowOnDeviceRecognition && recognizer.supportsOnDeviceRecognition
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        request.taskHint = .dictation

        return try await withCheckedThrowingContinuation { continuation in
            let lock = NSLock()
            var didResume = false

            func resumeOnce(_ result: Result<[TranscriptSegment], Error>) {
                lock.lock()
                defer { lock.unlock() }

                guard !didResume else { return }
                didResume = true

                switch result {
                case let .success(segments):
                    continuation.resume(returning: segments)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            var task: SFSpeechRecognitionTask?
            task = recognizer.recognitionTask(with: request) { result, error in
                _ = task

                if let error {
                    resumeOnce(.failure(error))
                    return
                }

                guard let result else { return }

                if result.isFinal {
                    let segments = result.bestTranscription.segments.map {
                        TranscriptSegment(
                            text: $0.substring,
                            startTime: $0.timestamp,
                            duration: $0.duration,
                        )
                    }

                    resumeOnce(.success(segments))
                }
            }
        }
    }

    private func isNoSpeechError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110
    }

    private func isLocalSpeechServiceError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101
    }
}
