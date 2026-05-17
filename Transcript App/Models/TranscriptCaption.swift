//
//  TranscriptCaption.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Foundation

struct TranscriptCaption: Identifiable {
    let id = UUID()
    let text: String
    let startTime: TimeInterval
}
