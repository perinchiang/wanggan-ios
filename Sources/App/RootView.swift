import SwiftUI

struct RootView: View {
    @Environment(LearningStore.self) private var store
    @State private var selectedTab = 0
    @State private var activeLesson: Lesson?

    var body: some View {
        Group {
            if let error = store.loadError {
                EmptyLearningState(title: "课程暂时无法打开", detail: error)
            } else {
                TabView(selection: $selectedTab) {
                    LearningRouteView { activeLesson = $0 }
                        .tabItem { Label("学习", systemImage: "book.closed.fill") }.tag(0)
                    ReviewView { activeLesson = $0 }
                        .tabItem { Label("复习", systemImage: "arrow.counterclockwise") }.tag(1)
                    ProfileView()
                        .tabItem { Label("我的", systemImage: "person.crop.circle") }.tag(2)
                }
            }
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.paper)
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonPlayer(lesson: lesson, initialSession: store.session(for: lesson)) { next in
                activeLesson = next
            }
            .id(lesson.id)
        }
        .alert("进度提示", isPresented: Binding(
            get: { store.storageWarning != nil }, set: { if !$0 { store.storageWarning = nil } }
        )) {
            Button("知道了") { store.storageWarning = nil }
        } message: { Text(store.storageWarning ?? "") }
    }
}

struct LearningRouteView: View {
    @Environment(LearningStore.self) private var store
    let openLesson: (Lesson) -> Void
    @State private var lockedTitle: String?

    private var recommended: Lesson? { store.currentLesson }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { Text("网感").font(.largeTitle.weight(.black)); Spacer(); XPBadge(xp: store.ledger.totalXP) }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("今天，想通一个问题。")
                            .font(.title.weight(.bold)).accessibilityAddTraits(.isHeader)
                        Text("本周已学习 \(store.ledger.activeDaysThisWeek()) 天 · 每次约 3 分钟")
                            .font(.subheadline).foregroundStyle(Theme.muted)
                    }
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Text("\(store.completedCount) / \(store.lessons.count)").font(.subheadline.monospacedDigit())
                        }
                        ThinProgress(value: Double(store.completedCount) / Double(max(store.lessons.count, 1)))
                    }
                    ForEach(store.chapters) { chapter in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(chapter.title).font(.subheadline.weight(.semibold))
                            VStack(spacing: 0) {
                                ForEach(store.lessons(in: chapter)) { lesson in
                                    let done = store.ledger.lessons[lesson.id] != nil
                                    let unlocked = store.isUnlocked(lesson)
                                    let current = lesson.id == store.currentLesson?.id && !done
                                    RouteRow(lesson: lesson, done: done, current: current, unlocked: unlocked,
                                             isLast: lesson.id == store.orderedLessonIDs.last) {
                                        if unlocked { openLesson(lesson) } else { lockedTitle = lesson.title }
                                    }
                                }
                            }
                        }
                    }
                    Text("不背答案，练习看懂网络。")
                        .font(.footnote).foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
                }.padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 14)
            }
            .background(Theme.paper)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let lesson = recommended {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lesson.title).font(.headline).accessibilityIdentifier("recommended-lesson-title")
                                Text(store.ledger.draft?.lessonID == lesson.id ? "上次学到的地方，还在这里" : "约 3 分钟 · 4 段探索")
                                    .font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer(minLength: 4)
                            PacketMascot(size: 36)
                        }
                        PrimaryButton(title: store.ledger.draft?.lessonID == lesson.id ? "继续探索" : "开始探索", identifier: "start-lesson") {
                            openLesson(lesson)
                        }
                    }
                    .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 12)
                    .background(Theme.paper)
                    .overlay(alignment: .top) { Rectangle().fill(Theme.line.opacity(0.6)).frame(height: 1) }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(Theme.paper, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .alert("先把上一站想明白", isPresented: Binding(get: { lockedTitle != nil }, set: { if !$0 { lockedTitle = nil } })) {
                Button("知道了", role: .cancel) { lockedTitle = nil }
            } message: { Text("完成前一小节后，就能探索「\(lockedTitle ?? "")」。") }
        }
    }
}

struct RouteRow: View {
    let lesson: Lesson
    let done: Bool
    let current: Bool
    let unlocked: Bool
    let isLast: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 0) {
                    ZStack {
                        Circle().fill(done ? Theme.ink : current ? Theme.lime : Theme.line).frame(width: 43, height: 43)
                        Image(systemName: done ? "checkmark" : current ? "play.fill" : "lock.fill")
                            .font(.system(size: current ? 16 : 13, weight: .bold))
                            .foregroundStyle(done ? Color.white : unlocked ? Theme.ink : Theme.muted)
                    }
                    if !isLast {
                        LineSegment().stroke(Theme.line, style: StrokeStyle(lineWidth: 2, dash: [3, 4]))
                            .frame(width: 2).frame(minHeight: 20)
                    }
                }.frame(width: 43)
                VStack(alignment: .leading, spacing: 6) {
                    Text(lesson.title).font(.headline).foregroundStyle(unlocked ? Theme.ink : Theme.muted)
                    Text(lesson.subtitle).font(.caption).foregroundStyle(Theme.muted)
                }.padding(.top, 5).padding(.bottom, 14)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10).padding(.top, 8)
            .background(current ? Theme.line.opacity(0.24) : .clear, in: .rect(cornerRadius: 18))
        }.buttonStyle(PressStyle())
            .accessibilityLabel("\(lesson.title)，\(done ? "已完成" : unlocked ? "可以开始" : "未解锁")")
            .accessibilityIdentifier("lesson-\(lesson.id)")
    }
}

struct LineSegment: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in path.move(to: CGPoint(x: rect.midX, y: rect.minY)); path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY)) }
    }
}
