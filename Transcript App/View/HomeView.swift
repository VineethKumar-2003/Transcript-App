//
//  HomeView.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import SwiftUI

struct HomeView: View {
    
    var body: some View {
        ZStack {
            CleanGradientBackground()
            
            VStack {
                Spacer()
                
                Text("Transcript")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .top) {
            header
        }
    }
}

// MARK: - Header
private extension HomeView {
    
    var header: some View {
        VStack(spacing: 0) {
            
            HStack {
                
                // App Icon + Name
                HStack(spacing: 10) {
                    Image("EchoNoteLogo")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("EchoNote")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Right icons
                HStack(spacing: 18) {
                    
                    Button {
                        // History
                    } label: {
                        Image(systemName: "clock")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    
                    Button {
                        // Settings
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
                .background(.white.opacity(0.3))
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    HomeView()
}
