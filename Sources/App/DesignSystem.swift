import SwiftUI

enum Theme {
    static let paper = Color(red: 0.969, green: 0.969, blue: 0.949)
    static let ink = Color(red: 0.098, green: 0.098, blue: 0.098)
    static let line = Color(red: 0.87, green: 0.87, blue: 0.84)
    static let lime = Color(red: 0.843, green: 0.969, blue: 0.357)
    static let muted = Color(red: 0.43, green: 0.43, blue: 0.40)
    static let surface = Color.white.opacity(0.65)
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var enabled = true
    var symbol = "arrow.right"
    var identifier = "primary-action"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title).font(.headline)
                if !symbol.isEmpty { Image(systemName: symbol).font(.subheadline.weight(.semibold)) }
                Spacer()
            }
            .padding(.vertical, 18)
            .foregroundStyle(enabled ? Color.white : Theme.muted)
            .background(enabled ? Theme.ink : Theme.line, in: .rect(cornerRadius: 17))
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
        .accessibilityIdentifier(identifier)
    }
}

struct XPBadge: View {
    let xp: Int
    var body: some View {
        Text("\(xp) XP")
            .font(.subheadline.weight(.heavy).monospacedDigit())
            .padding(.horizontal, 15).padding(.vertical, 10)
            .background(Theme.lime, in: .capsule)
            .accessibilityLabel("\(xp) 经验值")
            .accessibilityIdentifier("xp-badge")
    }
}

struct ThinProgress: View {
    let value: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line.opacity(0.7))
                Capsule().fill(Theme.lime)
                    .frame(width: max(0, geometry.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 7)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("进度")
        .accessibilityValue("\(Int(value * 100))%")
    }
}

struct PacketMascot: View {
    var size: CGFloat = 54
    var celebrating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false
    var body: some View {
        ZStack {
            Ellipse().fill(Theme.ink.opacity(0.08))
                .frame(width: size * 0.78, height: size * 0.12).offset(y: size * 0.43)
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.35)
                    .fill(Theme.ink).frame(width: size * 0.8, height: size * 0.85)
                    .rotationEffect(.degrees(-7))
                HStack(spacing: size * 0.045) {
                    eye.offset(y: -size * 0.03)
                    eye
                }.offset(x: size * 0.08, y: -size * 0.10)
                HStack(spacing: size * 0.28) {
                    Capsule().fill(Theme.ink).frame(width: size * 0.15, height: size * 0.1)
                    Capsule().fill(Theme.ink).frame(width: size * 0.15, height: size * 0.1)
                }.offset(y: size * 0.41)
            }
            .offset(y: celebrating && lifted ? -size * 0.09 : 0)
            .rotationEffect(.degrees(celebrating && lifted ? 5 : -3))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .onAppear {
            guard celebrating, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatCount(3, autoreverses: true)) { lifted = true }
        }
    }
    private var eye: some View {
        ZStack(alignment: .trailing) {
            Ellipse().fill(.white).frame(width: size * 0.16, height: size * 0.23)
            Circle().fill(Theme.ink).frame(width: size * 0.075).offset(x: -size * 0.025)
        }
    }
}

struct TutorBubble: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            PacketMascot(size: 44).padding(.top, 6)
            Text(text)
                .font(.body.weight(.medium)).lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(17)
                .background(Theme.line.opacity(0.34), in: .rect(cornerRadius: 20))
                .overlay(alignment: .leading) {
                    UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2,
                                           bottomTrailingRadius: 1, topTrailingRadius: 1)
                        .fill(Theme.line.opacity(0.34)).frame(width: 9, height: 12)
                        .rotationEffect(.degrees(45)).offset(x: -4, y: -4)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

struct Surface<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(18)
            .background(Theme.surface, in: .rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.line, lineWidth: 1))
    }
}

struct EmptyLearningState: View {
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 20) {
            PacketMascot(size: 80)
            Text(title).font(.title2.bold())
            Text(detail).font(.body).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 48).padding(.horizontal, 20)
    }
}
