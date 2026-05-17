//
//  CaptionBuilder.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Foundation

enum CaptionBuilder {
    static let defaultWindow: TimeInterval = 4

    static func buildCaptions(
        from segments: [TranscriptSegment],
        window: TimeInterval = defaultWindow,
    ) -> [TranscriptCaption] {
        guard let first = segments.first else { return [] }

        var captions: [TranscriptCaption] = []

        var bufferText = first.text
        var windowStart = first.startTime

        for segment in segments.dropFirst() {
            if segment.startTime - windowStart > window {
                captions.append(
                    TranscriptCaption(
                        text: bufferText.trimmingCharacters(in: .whitespaces),
                        startTime: windowStart,
                    ),
                )

                bufferText = segment.text
                windowStart = segment.startTime

            } else {
                bufferText += " \(segment.text)"
            }
        }

        if !bufferText.isEmpty {
            captions.append(
                TranscriptCaption(
                    text: bufferText.trimmingCharacters(in: .whitespaces),
                    startTime: windowStart,
                ),
            )
        }

        return captions
    }
}
