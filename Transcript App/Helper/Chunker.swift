//
//  Chunker.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Foundation
import AVFoundation

final class AudioChunker {
    
    struct Chunk {
        let url: URL
        let startTime: TimeInterval
    }
    
    struct ChunkSession {
        let folder: URL
        let chunks: [Chunk]
    }
    
    /// Split video/audio into time-based audio chunks
    /// - Parameters:
    ///     - asset: AVURLAsset of the video
    ///     - chunkDuration: duration of each chunk in seconds (Default 30)
    /// - Returns: array of chunk metadata
    func createChunks(
        from asset: AVURLAsset,
        chunkDuration: TimeInterval = 30
    ) async throws -> ChunkSession {
        
        let sessionFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcription_\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(
            at: sessionFolder,
            withIntermediateDirectories: true
        )
        
        let durationSeconds = try await asset.load(.duration).seconds
        
        var chunks: [Chunk] = []
        var currentStart: TimeInterval = 0
        var index = 0
        
        while currentStart < durationSeconds {
            let exportURL = sessionFolder
                .appendingPathComponent("chunk_\(index)")
                .appendingPathExtension("m4a")
                
                let startTime = CMTime(seconds: currentStart, preferredTimescale: 600)
                let remaining = durationSeconds - currentStart
                let segmentDuration = min(chunkDuration, remaining)
                        
                let timeRange = CMTimeRange(
                    start: startTime,
                    duration: CMTime(seconds: segmentDuration, preferredTimescale: 600)
                )
                        
                guard let exportSession = AVAssetExportSession(
                    asset: asset,
                    presetName: AVAssetExportPresetAppleM4A
                ) else {
                    throw NSError(domain: "ChunkExport", code: -1)
                }
                        
                exportSession.timeRange = timeRange
                
                try await exportSession.export(to: exportURL, as: .m4a)
                
                let chunk = Chunk(
                    url: exportURL,
                    startTime: currentStart
                )
                
                chunks.append(chunk)
                
                currentStart += chunkDuration
                index += 1
        }
        return ChunkSession(
            folder: sessionFolder,
            chunks: chunks
        )
    }
}
