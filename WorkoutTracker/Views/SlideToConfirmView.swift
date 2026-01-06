import SwiftUI

struct SlideToConfirmView: View {
    let text: String
    let onConfirm: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isConfirmed = false
    
    private let handleSize: CGFloat = 60
    private let trackPadding: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            let maxOffset = geometry.size.width - handleSize - (trackPadding * 2)
            
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.red.opacity(0.8))
                
                // Text label
                Text(text)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .opacity(1.0 - Double(offset / maxOffset))
                
                // Handle
                Capsule()
                    .fill(.white)
                    .frame(width: handleSize, height: handleSize - (trackPadding * 2))
                    .overlay {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.red)
                            .fontWeight(.bold)
                    }
                    .padding(.leading, trackPadding)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isConfirmed {
                                    let newOffset = value.translation.width
                                    offset = min(max(0, newOffset), maxOffset)
                                }
                            }
                            .onEnded { value in
                                if !isConfirmed {
                                    if offset > maxOffset * 0.9 {
                                        // Snap to end and confirm
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            offset = maxOffset
                                            isConfirmed = true
                                        }
                                        // Small delay for visual feedback
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            onConfirm()
                                        }
                                    } else {
                                        // Snap back
                                        withAnimation(.interactiveSpring()) {
                                            offset = 0
                                        }
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: handleSize)
    }
}

#Preview {
    SlideToConfirmView(text: "Slide to Finish") {
        print("Confirmed!")
    }
    .padding()
}
