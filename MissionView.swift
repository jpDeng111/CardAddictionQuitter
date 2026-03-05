import SwiftUI

struct MissionView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var completedMission: MissionType?
    @State private var navigationPath = NavigationPath()
    @State private var selectedMission: MissionType?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // Boost Status Card
                    boostStatusCard

                    // Available Missions
                    availableMissionsSection

                    // Completed Missions
                    completedMissionsSection

                    // Mission Info
                    missionInfoSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("每日任务")
            .navigationDestination(for: MissionType.self) { mission in
                MissionVerificationView(missionType: mission)
                    .environmentObject(gameManager)
            }
            .alert("任务完成!", isPresented: $showingAlert) {
                Button("太棒了!") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Boost Status Card
    private var boostStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前概率提升")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .bottom, spacing: 4) {
                        Text("+\(Int(gameManager.probabilityBoost * 100))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.orange)
                        Text("%")
                            .font(.title)
                            .foregroundColor(.orange)
                            .padding(.bottom, 6)
                    }
                }

                Spacer()

                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: min(gameManager.probabilityBoost, 1.0))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(min(gameManager.probabilityBoost, 1.0) * 100))")
                            .font(.title3.bold())
                        Text("/ 100")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Info Text
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("完成任务可提升抽卡概率，最高 100%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Available Missions
    private var availableMissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("可完成任务")
                    .font(.headline)
                Spacer()
                Text("\(gameManager.getAvailableMissions().count) 个可用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            let availableMissions = gameManager.getAvailableMissions()

            if availableMissions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("今日任务已全部完成!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(availableMissions, id: \.rawValue) { mission in
                    MissionCard(
                        mission: mission,
                        isCompleted: false
                    ) {
                        navigateToVerification(mission: mission)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Completed Missions
    private var completedMissionsSection: some View {
        let completedMissions = gameManager.getCompletedMissions()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("已完成任务")
                    .font(.headline)
                Spacer()
                Text("\(completedMissions.count) 个完成")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            if completedMissions.isEmpty {
                HStack {
                    Spacer()
                    Text("今日暂无完成的任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(completedMissions, id: \.rawValue) { mission in
                    MissionCard(
                        mission: mission,
                        isCompleted: true
                    ) { }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Mission Info
    private var missionInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("任务说明")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "star.fill", color: .green, text: "简单任务：+10% 概率提升")
                InfoRow(icon: "star.fill", color: .blue, text: "中等任务：+30% 概率提升")
                InfoRow(icon: "star.fill", color: .orange, text: "困难任务：+50% 概率提升")

                Divider()

                InfoRow(icon: "clock", color: .gray, text: "任务每日重置，24 小时冷却")
                InfoRow(icon: "arrow.up.circle", color: .purple, text: "概率提升最高可达 100%")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Actions
    private func navigateToVerification(mission: MissionType) {
        navigationPath.append(mission)
    }
}

// MARK: - Supporting Views

struct MissionCard: View {
    let mission: MissionType
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(difficultyColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: missionIcon)
                    .font(.title3)
                    .foregroundColor(difficultyColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mission.name)
                        .font(.subheadline.bold())

                    // Difficulty Badge
                    Text(difficultyText)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(difficultyColor)
                        .cornerRadius(4)
                }

                Text(mission.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action / Status
            if isCompleted {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("+\(Int(mission.probabilityBoost * 100))%")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                }
            } else {
                Button(action: action) {
                    VStack(spacing: 2) {
                        Text("去完成")
                            .font(.caption.bold())
                        Text("+\(Int(mission.probabilityBoost * 100))%")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(difficultyColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? Color.green.opacity(0.05) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var difficultyColor: Color {
        switch mission.difficulty {
        case .easy: return .green
        case .medium: return .blue
        case .hard: return .orange
        }
    }

    private var difficultyText: String {
        switch mission.difficulty {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }

    private var missionIcon: String {
        switch mission {
        case .noFapDiary: return "book.fill"
        case .goodDeedRecord: return "heart.fill"
        case .morningExercise: return "figure.run"
        case .reading: return "text.book.closed.fill"
        case .meditation: return "brain.head.profile"
        case .study: return "graduationcap.fill"
        case .earlySleep: return "moon.fill"
        case .healthyDiet: return "leaf.fill"
        }
    }
}

struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MissionView()
        .environmentObject(GameManager())
}
