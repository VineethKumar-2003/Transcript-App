//
//  CleanGradientBackground.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//


import SwiftUI

struct CleanGradientBackground: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
                
            baseGradient
                
            glowLayer
                
            depthOverlay
        }
        .ignoresSafeArea()
    }
}

// MARK: - Layers
private extension CleanGradientBackground {
    
    var baseGradient: LinearGradient {
        if colorScheme == .light {
            return LinearGradient (
                colors: [
                    Color(hex: "D6BFBE"),
                    Color(hex: "6266B3")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient (
                colors: [
                    Color(hex: "1F2135"),
                    Color(hex: "3c3F7A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var glowLayer: some View {
        RadialGradient(
            colors: [
                Color.white.opacity(colorScheme == .light ? 0.25 : 0.08),
                Color.clear
            ],
            center: .topLeading,
            startRadius: 50,
            endRadius: 400
        )
        .blur(radius: 60)
    }
    
    var depthOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(colorScheme == .light ? 0.05 : 0.2),
                Color.clear
            ],
            startPoint: .bottom,
            endPoint: .center
        )
    }
}

// MARK: - Hex Color Helper
extension Color {
    
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}
