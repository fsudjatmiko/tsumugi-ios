import SwiftUI

/// Reusable circular avatar component displaying user's photo, custom emoji, or fallback SF Symbol.
public struct UserAvatarView: View {
    public let imageData: Data?
    public let emoji: String?
    public let size: CGFloat
    public let strokeWidth: CGFloat

    public init(
        imageData: Data? = nil,
        emoji: String? = nil,
        size: CGFloat = 36,
        strokeWidth: CGFloat = 0
    ) {
        self.imageData = imageData
        self.emoji = emoji
        self.size = size
        self.strokeWidth = strokeWidth
    }

    public var body: some View {
        ZStack {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let emoji = emoji, !emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(emoji)
                    .font(.system(size: size * 0.55))
                    .frame(width: size, height: size)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(Color.tsumugiDustyDenim.opacity(0.8))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .if(strokeWidth > 0) { view in
            view.overlay(
                Circle()
                    .stroke(Color.tsumugiDustyDenim.opacity(0.25), lineWidth: strokeWidth)
            )
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        UserAvatarView(size: 36)
        UserAvatarView(emoji: "🦊", size: 36)
        UserAvatarView(emoji: "👘", size: 64)
    }
    .padding()
}
