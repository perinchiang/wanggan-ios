import SwiftUI

struct CompletionView: View {
    let lesson: Lesson
    let earnedXP: Int
    let totalXP: Int
    let level: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 25) {
            Text("想通了！").font(.largeTitle.weight(.black)).padding(.top, 28)
            ZStack {
                RouteCelebration().stroke(Theme.ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 260, height: 120)
                ForEach(0..<5, id: \.self) { mark in
                    Capsule().fill(Theme.lime).frame(width: 7, height: 18)
                        .rotationEffect(.degrees(Double(mark * 47)))
                        .offset(x: CGFloat([-100, -60, 70, 105, 20][mark]), y: CGFloat([-30, -60, -55, -5, -75][mark]))
                }
                PacketMascot(size: 83, celebrating: true).offset(y: -12)
                Image(systemName: "flag.fill").font(.title).foregroundStyle(Theme.ink).offset(x: 117, y: -44)
            }.frame(height: 160).padding(.top, 20).accessibilityHidden(true)
            VStack(spacing: 12) {
                Text("你已完成").font(.subheadline).foregroundStyle(Theme.muted)
                Text(lesson.title).font(.title2.bold()).multilineTextAlignment(.center)
                    .accessibilityIdentifier("completion-lesson-title")
            }
            Text(earnedXP > 0 ? "+\(earnedXP) XP" : "又巩固了一次")
                .font(earnedXP > 0 ? .largeTitle.weight(.black).monospacedDigit() : .title2.bold())
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(Theme.lime, in: .capsule)
                .scaleEffect(revealed ? 1 : 0.85)
                .accessibilityIdentifier("completion-reward")
            VStack(spacing: 10) {
                ThinProgress(value: revealed ? Double(totalXP % 100) / 100 : 0)
                Text("Lv.\(level) · 距离下一级还差 \(100 - totalXP % 100) XP")
                    .font(.caption).foregroundStyle(Theme.muted)
                if earnedXP == 0 {
                    Text("同一天重复探索不再加分，明天复习可得 5 XP。")
                        .font(.caption).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                }
            }
            Surface {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: "lightbulb").font(.title2)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("下一个疑问").font(.caption).foregroundStyle(Theme.muted)
                        Text(lesson.nextCuriosity).font(.headline).lineSpacing(4)
                    }
                    Spacer(minLength: 0)
                }
            }
        }.frame(maxWidth: .infinity)
            .onAppear { withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.7)) { revealed = true } }
    }
}

private struct RouteCelebration: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 8, y: rect.height - 10))
            path.addCurve(to: CGPoint(x: rect.width - 8, y: 12),
                          control1: CGPoint(x: rect.width * 0.22, y: -20),
                          control2: CGPoint(x: rect.width * 0.7, y: rect.height + 30))
        }
    }
}
