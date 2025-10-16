import UIKit

class TargetView: UIView {
    
    static let defaultSize: CGFloat = 80
    
    override init(frame: CGRect) {
        // Ensure the frame is square for a perfect circle
        let size = max(frame.width, frame.height)
        let squareFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: size, height: size)
        super.init(frame: squareFrame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .systemBlue
        layer.cornerRadius = bounds.width / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 4
    }
    
    // Animate the hit and subsequent respawn
    func animateHitAndRespawn(newCenter: CGPoint) {
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.alpha = 0
        }) { _ in
            // Move to new position while invisible
            self.center = newCenter
            
            // Animate appear at new location
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut) {
                self.transform = .identity
                self.alpha = 1
            }
        }
    }
}

