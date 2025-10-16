
import SwiftUI

struct ContentView: View {
    @State private var score = 0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // This View bridges our UIKit Controller into SwiftUI
            HandPunchGameView(score: $score)
                .edgesIgnoringSafeArea(.all)
            
            // This is the Score display UI
            VStack(alignment: .trailing, spacing: 10) {
                Text("Score: \(score)")
                    .font(.title).bold()
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
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
}

// UIViewControllerRepresentable acts as a View bridge
struct HandPunchGameView: UIViewControllerRepresentable {
    @Binding var score: Int
    
    func makeUIViewController(context: Context) -> HandPunchViewController {
        let controller = HandPunchViewController()
        // The controller communicates back to the SwiftUI view via this closure
        controller.onScoreUpdate = { newScore in
            self.score = newScore
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: HandPunchViewController, context: Context) {}
}

#Preview {
    ContentView()
}
