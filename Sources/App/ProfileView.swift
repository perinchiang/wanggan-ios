import SwiftUI

struct ProfileView: View {
    @Environment(LearningStore.self) private var store
    @State private var confirmReset = false
    var body: some View {
        @Bindable var settings = store
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("每次，想明白一点。").font(.title.bold())
                            Text("网络探索者 · Lv.\(store.ledger.level)").font(.subheadline).foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 0); PacketMascot(size: 62)
                    }
                    HStack(spacing: 12) {
                        statistic("总经验", value: "\(store.ledger.totalXP)", suffix: "XP")
                        statistic("已想通", value: "\(store.completedCount)", suffix: "个问题")
                    }
                    Surface {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack { Text("这一周").font(.headline); Spacer(); Text("\(store.ledger.activeDaysThisWeek()) 天").font(.subheadline) }
                            HStack(spacing: 0) {
                                ForEach(weekDays, id: \.self) { date in
                                    let active = store.ledger.activityDays.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                                    VStack(spacing: 8) {
                                        Text(date.formatted(.dateTime.weekday(.narrow))).font(.caption)
                                        Image(systemName: active ? "checkmark.circle.fill" : "circle")
                                            .font(.title3).foregroundStyle(active ? Theme.ink : Theme.line)
                                            .padding(5).background(active ? Theme.lime : .clear, in: .circle)
                                    }.frame(maxWidth: .infinity)
                                        .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted))，\(active ? "已学习" : "未学习")")
                                }
                            }
                        }
                    }
                    if store.completedCount > 0 {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("已经想通的事").font(.headline)
                            ForEach(store.lessons.filter { store.ledger.lessons[$0.id] != nil }) { lesson in
                                Label(lesson.takeaway, systemImage: "checkmark").font(.subheadline)
                            }
                        }
                    }
                    Surface {
                        VStack(alignment: .leading, spacing: 18) {
                            Toggle("触感反馈", isOn: $settings.hapticsEnabled).tint(Theme.ink)
                            Divider()
                            Label("进度只保存在这台设备", systemImage: "iphone")
                                .font(.subheadline)
                            Text("无需登录，无广告。卸载应用会移除本地进度；更新请保留同一个应用标识。")
                                .font(.caption).foregroundStyle(Theme.muted).lineSpacing(4)
                        }
                    }
                    Button("重置学习进度", role: .destructive) { confirmReset = true }
                        .font(.subheadline).frame(minHeight: 44)
                    Text("网感 0.1 · 原生 SwiftUI 体验版")
                        .font(.caption).foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
                }.padding(22)
            }.background(Theme.paper).navigationTitle("我的").navigationBarTitleDisplayMode(.inline)
                .confirmationDialog("重置所有学习进度？", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("重置进度", role: .destructive) { store.resetProgress() }
                } message: { Text("将清除经验值、已完成小节和本次学习记录，无法撤销。") }
        }
    }

    private func statistic(_ title: String, value: String, suffix: String) -> some View {
        Surface {
            VStack(alignment: .leading, spacing: 11) {
                Text(title).font(.caption).foregroundStyle(Theme.muted)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(value).font(.largeTitle.bold().monospacedDigit())
                    Text(suffix).font(.caption)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
