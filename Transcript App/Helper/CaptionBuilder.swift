//
//  CaptionBuilder.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Foundation

enum CaptionBuilder {
    static func buildCaptions(
        from segments: [TranscriptSegment],
        window: TimeInterval = 4
    ) -> [TranscriptCaption] {
        guard !segments.isEmpty else { return [] }

        var captions: [TranscriptCaption] = []

        var bufferText = ""
        var windowStart = segments.first!.startTime

        for segment in segments {
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
                bufferText += " " + segment.text
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
