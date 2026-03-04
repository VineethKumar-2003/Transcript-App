//
//  Chunker.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import AVFoundation
import Foundation

final class AudioChunker {
    enum ChunkerError: LocalizedError {
        case noAudioTrack
        case failedToCreateExportSession
        case failedToExportChunk(index: Int, underlying: Error?)

        var errorDescription: String? {
            switch self {
            case .noAudioTrack:
                return "The selected video does not contain an audio track."
            case .failedToCreateExportSession:
                return "Unable to create an audio export session."
            case let .failedToExportChunk(index, underlying):
                if let underlying {
                    return "Failed to export audio chunk \(index): \(underlying.localizedDescription)"
                }
                return "Failed to export audio chunk \(index)."
            }
        }
    }

    struct Chunk {
        let url: URL
        let startTime: TimeInterval
    }

    struct ChunkSession {
        let folder: URL
        let chunks: [Chunk]
    }

    func createChunks(
        from asset: AVURLAsset,
        chunkDuration: TimeInterval = 30,
    ) async throws -> ChunkSession {
        let sessionFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcription_\(UUID().uuidString)")

        try FileManager.default.createDirectory(
            at: sessionFolder,
            withIntermediateDirectories: true,
        )

        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw ChunkerError.noAudioTrack
        }

        let duration = try await asset.load(.duration)
        let totalDuration = CMTimeGetSeconds(duration)

        guard totalDuration.isFinite, totalDuration > 0 else {
            return ChunkSession(folder: sessionFolder, chunks: [])
        }

        var chunks: [Chunk] = []
        var chunkIndex = 0
        var startTime: TimeInterval = 0

        while startTime < totalDuration {
            let currentDuration = min(chunkDuration, totalDuration - startTime)
            let outputURL = sessionFolder
                .appendingPathComponent("chunk_\(chunkIndex)")
                .appendingPathExtension("m4a")

            try await exportAudioChunk(
                from: asset,
                startTime: startTime,
                duration: currentDuration,
                outputURL: outputURL,
                index: chunkIndex,
            )

            chunks.append(.init(url: outputURL, startTime: startTime))

            startTime += currentDuration
            chunkIndex += 1
        }

        return ChunkSession(folder: sessionFolder, chunks: chunks)
    }

    private func exportAudioChunk(
        from asset: AVURLAsset,
        startTime: TimeInterval,
        duration: TimeInterval,
        outputURL: URL,
        index: Int,
    ) async throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A,
        ) else {
            throw ChunkerError.failedToCreateExportSession
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let chunkDuration = CMTime(seconds: duration, preferredTimescale: 600)
        exportSession.timeRange = CMTimeRange(start: start, duration: chunkDuration)

        do {
            try await exportSession.export(to: outputURL, as: .m4a)
        } catch {
            throw ChunkerError.failedToExportChunk(index: index, underlying: error)
        }
    }
}
