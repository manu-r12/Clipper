import SwiftUI

struct IslandActionButton: View {
    enum Role {
        case primary
        case secondary
    }

    let systemImage: String
    let role: Role
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(systemImage: String, role: Role, size: CGFloat, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.role = role
        self.size = size
        self.action = action
    }

    init(systemImage: String, isPrimary: Bool, action: @escaping () -> Void) {
        self.init(
            systemImage: systemImage,
            role: isPrimary ? .primary : .secondary,
            size: isPrimary ? 44 : 36,
            action: action
        )
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundFill)

                Circle()
                    .stroke(borderColor, lineWidth: 0.6)

                Image(systemName: systemImage)
                    .font(iconFont)
                    .foregroundStyle(foregroundColor)
                    .offset(x: systemImage == "play.fill" ? 1 : 0)
            }
            .frame(width: size, height: size)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 20,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }

    private var backgroundFill: AnyShapeStyle {
        switch role {
        case .primary:
            return AnyShapeStyle(Color.white)

        case .secondary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.07)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var borderColor: Color {
        switch role {
        case .primary:
            return Color.white.opacity(0.18)

        case .secondary:
            return Color.white.opacity(0.06)
        }
    }

    private var foregroundColor: Color {
        switch role {
        case .primary:
            return .black

        case .secondary:
            return .white
        }
    }

    private var iconFont: Font {
        switch role {
        case .primary:
            return .system(size: 16, weight: .bold)

        case .secondary:
            return .system(size: 13, weight: .bold)
        }
    }
}
