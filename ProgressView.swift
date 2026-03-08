import SwiftUI
import CoreData

// MARK: - 打卡统计视图
struct ProgressView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedDate: Date?
    @State private var showingDetail = false
    @State private var missions: [MissionRecord] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计卡片
                    statsCards

                    // 热力图
                    heatmapSection

                    // 最近打卡记录
                    recentMissionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("打卡统计")
            .sheet(isPresented: $showingDetail) {
                if let date = selectedDate {
                    MissionDetailSheet(date: date, missions: missions)
                }
            }
        }
    }

    // MARK: - 统计卡片
    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "连续打卡",
                value: "\(calculateStreak())天",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "本月打卡",
                value: "\(thisMonthCount)次",
                icon: "calendar",
                color: .blue
            )
            StatCard(
                title: "总打卡",
                value: "\(totalCount)次",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }

    // MARK: - 热力图区域
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("打卡热力图")
                .font(.headline)

            VStack(spacing: 4) {
                // 星期标签
                HStack(spacing: 4) {
                    Text("")
                        .frame(width: 30)
                    ForEach(0..<52, id: \.self) { week in
                        Text("")
                            .frame(width: 12)
                    }
                }

                // 热力图网格
                ForEach(0..<7) { day in
                    HStack(spacing: 4) {
                        // 星期标签
                        Text(["", "一", "", "三", "", "五", ""][day])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30)

                        // 每周的方块
                        ForEach(0..<52) { week in
                            let date = getDateForWeek(week, day: day)
                            let count = getMissionCount(for: date)
                            HeatmapCell(count: count, isActive: isToday(date))
                                .onTapGesture {
                                    showMissionDetail(for: date)
                                }
                        }
                    }
                }
            }

            // 图例
            HStack {
                Text("少")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HeatmapLegend()
                Text("多")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - 最近打卡记录
    private var recentMissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近打卡")
                .font(.headline)

            if recentMissions.isEmpty {
                Text("暂无打卡记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(recentMissions.prefix(10), id: \.self) { mission in
                    RecentMissionRow(mission: mission)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - 计算属性
    private var thisMonthCount: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate >= %@ AND completedDate < %@", startOfMonth as CVarArg, endOfMonth as CVarArg)

        do {
            let context = PersistenceController.shared.container.viewContext
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    private var totalCount: Int {
        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        do {
            let context = PersistenceController.shared.container.viewContext
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    private var recentMissions: [MissionRecord] {
        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]
        request.fetchLimit = 10

        do {
            let context = PersistenceController.shared.container.viewContext
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    // MARK: - 方法
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]

        do {
            let context = PersistenceController.shared.container.viewContext
            let missions = try context.fetch(request)

            var streak = 0
            var currentDate = Date()

            for mission in missions {
                guard let date = mission.completedDate else { continue }

                if calendar.isDate(date, inSameDayAs: currentDate) {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                } else if date < calendar.startOfDay(for: currentDate) {
                    break
                }
            }

            return streak
        } catch {
            return 0
        }
    }

    private func getDateForWeek(_ week: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()

        // 计算一年前的日期作为起点
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: oneYearAgo))!

        // 计算目标日期
        var components = DateComponents()
        components.day = week * 7 + day
        return calendar.date(byAdding: components, to: startOfWeek)!
    }

    private func getMissionCount(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate >= %@ AND completedDate < %@", startOfDay as CVarArg, endOfDay as CVarArg)

        do {
            let context = PersistenceController.shared.container.viewContext
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }

    private func showMissionDetail(for date: Date) {
        selectedDate = date

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate >= %@ AND completedDate < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: true)]

        do {
            let context = PersistenceController.shared.container.viewContext
            missions = try context.fetch(request)
            showingDetail = true
        } catch {
            print("Error fetching missions: \(error)")
        }
    }
}


// MARK: - 热力图单元格
struct HeatmapCell: View {
    let count: Int
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colorForCount(count))
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }

    private func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0: return Color(.systemBackground)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green.opacity(1.0)
        }
    }
}

// MARK: - 热力图图例
struct HeatmapLegend: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForIndex(i))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.horizontal, 8)
    }

    private func colorForIndex(_ index: Int) -> Color {
        switch index {
        case 0: return Color(.systemBackground)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green.opacity(1.0)
        }
    }
}

// MARK: - 最近打卡记录行
struct RecentMissionRow: View {
    let mission: MissionRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForType(mission.type ?? ""))
                .font(.title2)
                .foregroundColor(colorForType(mission.type ?? ""))
                .frame(width: 40, height: 40)
                .background(colorForType(mission.type ?? "").opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(missionName(for: mission.type ?? ""))
                    .font(.subheadline.bold())

                Text(formattedDate(mission.completedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("+\(Int(mission.probabilityBoost * 100))%")
                .font(.caption.bold())
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "noFapDiary": return "book.fill"
        case "goodDeedRecord": return "heart.fill"
        case "morningExercise": return "figure.run"
        case "reading": return "text.book.closed.fill"
        case "meditation": return "brain.head.profile"
        case "study": return "graduationcap.fill"
        case "earlySleep": return "moon.fill"
        case "healthyDiet": return "leaf.fill"
        default: return "questionmark"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "noFapDiary", "goodDeedRecord": return .green
        case "morningExercise", "reading", "meditation": return .blue
        case "study", "earlySleep", "healthyDiet": return .orange
        default: return .gray
        }
    }

    private func missionName(for type: String) -> String {
        switch type {
        case "noFapDiary": return "戒色日记"
        case "goodDeedRecord": return "记录善举"
        case "morningExercise": return "晨练"
        case "reading": return "阅读学习"
        case "meditation": return "冥想放松"
        case "study": return "专注学习"
        case "earlySleep": return "早睡早起"
        case "healthyDiet": return "健康饮食"
        default: return "未知任务"
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 打卡详情弹窗
struct MissionDetailSheet: View {
    let date: Date
    let missions: [MissionRecord]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 日期标题
                    Text(formattedTitle(date))
                        .font(.title2.bold())
                        .padding(.bottom, 8)

                    if missions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("这一天没有打卡记录")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(missions, id: \.self) { mission in
                            MissionDetailCard(mission: mission)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("打卡详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formattedTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        return formatter.string(from: date)
    }
}

// MARK: - 打卡详情卡片
struct MissionDetailCard: View {
    let mission: MissionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: iconForType(mission.type ?? ""))
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(colorForType(mission.type ?? ""))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(missionName(for: mission.type ?? ""))
                        .font(.headline)

                    Text(formattedTime(mission.completedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("+\(Int(mission.probabilityBoost * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }

            // 验证内容
            if let text = mission.verificationText, !text.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("打卡内容")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    Text(text)
                        .font(.subheadline)
                        .lineLimit(nil)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }

            if let imageData = mission.verificationImage,
               let image = UIImage(data: imageData) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("打卡图片")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "noFapDiary": return "book.fill"
        case "goodDeedRecord": return "heart.fill"
        case "morningExercise": return "figure.run"
        case "reading": return "text.book.closed.fill"
        case "meditation": return "brain.head.profile"
        case "study": return "graduationcap.fill"
        case "earlySleep": return "moon.fill"
        case "healthyDiet": return "leaf.fill"
        default: return "questionmark"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "noFapDiary", "goodDeedRecord": return .green
        case "morningExercise", "reading", "meditation": return .blue
        case "study", "earlySleep", "healthyDiet": return .orange
        default: return .gray
        }
    }

    private func missionName(for type: String) -> String {
        switch type {
        case "noFapDiary": return "戒色日记"
        case "goodDeedRecord": return "记录善举"
        case "morningExercise": return "晨练"
        case "reading": return "阅读学习"
        case "meditation": return "冥想放松"
        case "study": return "专注学习"
        case "earlySleep": return "早睡早起"
        case "healthyDiet": return "健康饮食"
        default: return "未知任务"
        }
    }

    private func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    ProgressView()
        .environmentObject(GameManager())
}
