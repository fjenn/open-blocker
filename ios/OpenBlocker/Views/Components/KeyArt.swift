// Key art component with animated fill from research brief BRIEF.md section b.10

import SwiftUI

struct KeyArt: View {
    var progress: CGFloat
    @State private var use3D: Bool = true
    
    var body: some View {
        Group {
            if use3D {
                KeyView3D(progress: progress)
                    .onAppear {
                        if Bundle.main.url(forResource: "KeyModel", withExtension: "usdz") == nil {
                            use3D = false
                        }
                    }
            } else {
                fallback2D
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var fallback2D: some View {
        ZStack {
            keyShape
                .fill(Color.brickKey)
            
            keyShape
                .fill(Color.brickKeyFill)
                .mask(alignment: .bottom) {
                    GeometryReader { geometry in
                        Rectangle()
                            .frame(height: geometry.size.height * progress)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            
            keyholeSymbol
        }
        .frame(width: 162, height: 165)
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        .accessibilityLabel(progress >= 1 ? "Blocked" : "Not blocked")
    }
    
    private var keyShape: some Shape {
        RoundedRectangle(cornerRadius: 44, style: .continuous)
    }
    
    private var keyholeSymbol: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 40, height: 40)
            
            VStack(spacing: 2) {
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 16, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 10, height: 18)
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        KeyArt(progress: 0)
            .background(Color.brickPanel)
        
        KeyArt(progress: 0.5)
            .background(Color.brickPanel)
        
        KeyArt(progress: 1.0)
            .background(Color.brickPanel)
    }
    .padding()
    .background(Color.brickCanvas)
}
