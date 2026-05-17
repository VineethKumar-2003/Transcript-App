//
//  TranscriptListView.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import AVKit
import SwiftUI

struct TranscriptListView: View {
    let transcript: [TranscriptSegment]
    let videoURL: URL?

    @State private var searchText = ""
    @State private var player: AVPlayer?
    @State private var activeCaptionID: UUID?
    @State private var timeObserverToken: Any?

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
        VStack(spacing: 0) {
            // VIDEO PLAYER (PINNED)
            if let player {
                VideoPlayer(player: player)
                    .frame(height: 220)
            }

            Divider()

            ScrollViewReader { proxy in
                List(filteredCaptions) { caption in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(timeString(caption.startTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(caption.text)
                            .font(.body)
                    }
                    .padding(.vertical, 6)
                    .background(
                        caption.id == activeCaptionID
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear,
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard let player else { return }

                        let time = CMTime(seconds: caption.startTime, preferredTimescale: 600)

                        player.seek(to: time)
                        player.play()
                    }
                    .id(caption.id)
                }
                .onChange(of: activeCaptionID) { _, newValue in
                    guard let id = newValue else { return }

                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .navigationTitle("Transcript")
        .searchable(text: $searchText)
        .toolbar {
            exportButton
        }
        .onAppear {
            if let videoURL {
                player = AVPlayer(url: videoURL)
                observePlayback()
            }
        }
        .onDisappear {
            removePlaybackObserver()
            player?.pause()
        }
        .onChange(of: searchText) { _, _ in
            let currentTime = player?.currentTime().seconds ?? 0
            updateActiveCaption(currentTime: currentTime)
        }
    }

    // MARK: Playback observer

    private func observePlayback() {
        guard let player else { return }

        removePlaybackObserver()

        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main,
        ) { time in
            updateActiveCaption(currentTime: time.seconds)
        }
    }

    private func removePlaybackObserver() {
        guard
            let player,
            let timeObserverToken
        else { return }

        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }

    private func updateActiveCaption(currentTime: TimeInterval) {
        let source = searchText.isEmpty ? captions : filteredCaptions

        guard let caption = source.last(where: { $0.startTime <= currentTime }) else {
            activeCaptionID = nil
            return
        }

        activeCaptionID = caption.id
    }

    // MARK: Export

    private var exportButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("Export TXT") {
                    exportTXT()
                }

                Button("Export SRT") {
                    exportSRT()
                }

            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    private func exportTXT() {
        let text = captions
            .map { "[\(timeString($0.startTime))] \($0.text)" }
            .joined(separator: "\n")

        print(text)
    }

    private func exportSRT() {
        var srt = ""
        var index = 1

        for caption in captions {
            let start = formatSRTTime(caption.startTime)
            let end = formatSRTTime(caption.startTime + CaptionBuilder.defaultWindow)

            srt += "\(index)\n"
            srt += "\(start) --> \(end)\n"
            srt += "\(caption.text)\n\n"

            index += 1
        }

        print(srt)
    }

    // MARK: Time helpers

    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        return String(format: "%02d:%02d:%02d,000", hours, minutes, seconds)
    }
}
