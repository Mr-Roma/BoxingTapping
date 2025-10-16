
// ============================================================
//  ContentView.swift
//  HandDetectionToucApp
//
//  Created by Romario Marcal on 16/10/25.
// ============================================================

import SwiftUI

struct ContentView: View {
    @State private var score = 0
    @State private var punchStats = PunchStats()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // This View bridges our UIKit Controller into SwiftUI
            HandPunchGameView(score: $score, punchStats: $punchStats)
                .edgesIgnoringSafeArea(.all)
            
            // This is the Score display UI
            VStack(alignment: .trailing, spacing: 10) {
                Text("Score: \(score)")
                    .font(.title).bold()
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                // Punch Statistics
                VStack(alignment: .trailing, spacing: 5) {
                    if punchStats.totalPunches > 0 {
                        Text("Last: \(punchStats.lastPunchType.rawValue)")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .background(punchTypeColor(punchStats.lastPunchType))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    HStack(spacing: 15) {
                        VStack {
                            Text("🥊 Jabs")
                                .font(.caption2)
                            Text("\(punchStats.jabs)")
                                .font(.caption)
                                .bold()
                        }
                        
                        VStack {
                            Text("💪 Straights")
                                .font(.caption2)
                            Text("\(punchStats.straights)")
                                .font(.caption)
                                .bold()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Text("👊 Punch the target!")
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Text("Double tap to toggle skeleton")
                    .font(.caption2)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private func punchTypeColor(_ punchType: PunchType) -> Color {
        switch punchType {
        case .jab:
            return Color.orange.opacity(0.8)
        case .straight:
            return Color.red.opacity(0.8)
        case .unknown:
            return Color.gray.opacity(0.7)
        }
    }
}

// UIViewControllerRepresentable acts as a View bridge
struct HandPunchGameView: UIViewControllerRepresentable {
    @Binding var score: Int
    @Binding var punchStats: PunchStats
    
    func makeUIViewController(context: Context) -> HandPunchViewController {
        let controller = HandPunchViewController()
        // The controller communicates back to the SwiftUI view via closures
        controller.onScoreUpdate = { newScore in
            self.score = newScore
        }
        controller.onPunchStatsUpdate = { newStats in
            self.punchStats = newStats
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: HandPunchViewController, context: Context) {}
}

#Preview {
    ContentView()
}
