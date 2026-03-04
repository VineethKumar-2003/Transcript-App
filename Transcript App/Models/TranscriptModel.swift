//
//  TranscriptModel.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Foundation

struct TranscriptSegment: Identifiable {
    let id = UUID()
    let text: String
    let startTime: TimeInterval
    let duration: TimeInterval
}
