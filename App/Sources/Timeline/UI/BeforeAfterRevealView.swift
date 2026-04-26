import SwiftUI

/// A draggable before/after photo comparison slider.
/// Users drag a vertical line to reveal the "after" photo over the "before" photo.
struct BeforeAfterRevealView: View {
    let beforeImage: UIImage
    let afterImage: UIImage

    @State private var dragPosition: CGFloat = 0.5
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let dividerX = max(0, min(width, width * dragPosition + dragOffset))

            ZStack {
                // Before image (full)
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous))

                // After image (clipped to divider position)
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(
                        RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                            .path(in: CGRect(x: 0, y: 0, width: dividerX, height: height))
                    )

                // Divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 0)
                    .position(x: dividerX, y: height / 2)

                // Handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CleraColor.accent)
                    )
                    .position(x: dividerX, y: height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let newPosition = dragPosition + value.translation.width / width
                        dragPosition = max(0.05, min(0.95, newPosition))
                    }
            )
        }
    }
}
