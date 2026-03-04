//
//  TranscriptListView.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import SwiftUI

struct TranscriptListView: View {

    let transcript: [TranscriptSegment]

    @State private var searchText = ""

    var captions: [TranscriptCaption] {
        CaptionBuilder.buildCaptions(from: transcript)
    }

    var filteredCaptions: [TranscriptCaption] {

        if searchText.isEmpty {
            return captions
        }

        return captions.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {

        List(filteredCaptions) { caption in

            VStack(alignment: .leading, spacing: 6) {

                Text(timeString(caption.startTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(caption.text)
                    .font(.body)
            }
        }
        .navigationTitle("Transcript")
        .searchable(text: $searchText)
    }

    private func timeString(_ time: TimeInterval) -> String {

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
