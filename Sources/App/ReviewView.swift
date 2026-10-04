import SwiftUI

struct ReviewView: View {
    @Environment(LearningStore.self) private var store
    let openLesson: (Lesson) -> Void
    private var completed: [Lesson] { store.lessons.filter { store.ledger.lessons[$0.id] != nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("把懂了，变成记住。").font(.title.bold())
                    Text("换个时间再判断一次，看看机制还在不在脑子里。")
                        .font(.subheadline).foregroundStyle(Theme.muted).lineSpacing(5)
                    if completed.isEmpty {
                        EmptyLearningState(title: "先去想通一个问题", detail: "完成第一节后，这里会为你安排复习。")
                    } else {
                        Surface {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(store.dueLessons.isEmpty ? "今天没有到期复习" : "\(store.dueLessons.count) 节，到了回看的时候")
                                        .font(.headline)
                                    Text("首轮完成后的次日开始复习")
                                        .font(.caption).foregroundStyle(Theme.muted)
                                }
                                Spacer(); PacketMascot(size: 44)
                            }
                        }
                        ForEach(completed) { lesson in
                            Button { openLesson(lesson) } label: {
                                Surface {
                                    HStack(spacing: 14) {
                                        Image(systemName: store.ledger.isDue(lesson.id) ? "arrow.counterclockwise.circle.fill" : "checkmark.circle")
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 7) {
                                            Text(lesson.title).font(.headline)
                                            if let progress = store.ledger.lessons[lesson.id] {
                                                Text(store.ledger.isDue(lesson.id) ? "现在复习 · 每日首次 +5 XP" : "下次复习：\(progress.nextReviewAt.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption).foregroundStyle(Theme.muted)
                                            }
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right").font(.caption)
                                    }
                                }
                            }.buttonStyle(PressStyle()).accessibilityIdentifier("review-\(lesson.id)")
                        }
                    }
                }.padding(22)
            }.background(Theme.paper).navigationTitle("复习").navigationBarTitleDisplayMode(.inline)
        }
    }
}
