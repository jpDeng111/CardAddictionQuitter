import SwiftUI
import CoreData
import UIKit

/// 任务验证视图 - 用户完成任务时需要输入验证内容
struct MissionVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var viewModel: MissionVerificationViewModel

    let missionType: MissionType

    init(missionType: MissionType, viewModel: MissionVerificationViewModel? = nil) {
        self.missionType = missionType
        _viewModel = StateObject(wrappedValue: viewModel ?? MissionVerificationViewModel())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 任务信息卡片
                    missionInfoCard

                    // 验证输入区域
                    verificationInput

                    // 提交按钮
                    submitButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("完成任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadUsageRecords()
            }
            .alert("提交成功", isPresented: $viewModel.showSuccessAlert) {
                Button("完成") {
                    dismiss()
                }
            } message: {
                Text("获得 +\(Int(missionType.probabilityBoost * 100))% 概率提升！")
            }
            .alert("错误", isPresented: $viewModel.showErrorAlert) {
                Button("确定") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    // MARK: - 任务信息卡片
    private var missionInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(difficultyColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: missionIcon)
                        .font(.title3)
                        .foregroundColor(difficultyColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(missionType.name)
                        .font(.headline)

                    Text(difficultyText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("+\(Int(missionType.probabilityBoost * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
            }

            Divider()

            Text(missionType.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - 验证输入区域
    private var verificationInput: AnyView {
        switch missionType {
        case .noFapDiary, .goodDeedRecord:
            return AnyView(TextViewWrapper(
                text: $viewModel.textInput,
                placeholder: missionType == .noFapDiary
                    ? "记录今日戒色心得，保持积极心态..."
                    : "记录今天做的一件好事，传递正能量...",
                minLength: 50
            ))
        case .reading, .study:
            return AnyView(TextViewWrapper(
                text: $viewModel.textInput,
                placeholder: missionType == .reading
                    ? "写下你的阅读心得或学习笔记（至少 50 字）..."
                    : "记录今日学习内容和收获（至少 50 字）...",
                minLength: 50
            ))
        case .healthyDiet:
            return AnyView(ImagePickerView(
                image: $viewModel.selectedImage,
                title: "拍摄健康饮食照片",
                description: "拍摄你的健康餐食，展示均衡营养"
            ))
        case .meditation:
            return AnyView(ImagePickerView(
                image: $viewModel.selectedImage,
                title: "拍摄冥想环境照片",
                description: "拍摄你的冥想空间或冥想后的感受记录"
            ))
        case .morningExercise:
            return AnyView(ImagePickerView(
                image: $viewModel.selectedImage,
                title: "拍摄晨练照片",
                description: "拍摄你的晨练活动或运动记录"
            ))
        case .earlySleep:
            return AnyView(EarlySleepVerificationView(
                isFirstUseTime: viewModel.firstUseTime,
                lastUseTime: viewModel.lastUseTime,
                targetSleepTime: viewModel.targetSleepTime,
                targetWakeTime: viewModel.targetWakeTime
            ))
        }
    }

    // MARK: - 提交按钮
    private var submitButton: some View {
        Button(action: submitMission) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("提交并完成")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSubmit ? Color.green : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!canSubmit || viewModel.isSubmitting)
    }

    // MARK: - Helpers
    private var canSubmit: Bool {
        viewModel.canSubmit(missionType: missionType)
    }

    private var difficultyColor: Color {
        switch missionType.difficulty {
        case .easy: return .green
        case .medium: return .blue
        case .hard: return .orange
        }
    }

    private var difficultyText: String {
        switch missionType.difficulty {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }

    private var missionIcon: String {
        switch missionType {
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

    private func submitMission() {
        Task {
            await viewModel.submitMission(
                missionType: missionType,
                gameManager: gameManager
            )
        }
    }
}

// MARK: - 文本输入视图
struct TextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let minLength: Int

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.textColor = .placeholderText
        textView.text = placeholder
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if text.isEmpty {
            uiView.textColor = .placeholderText
            uiView.text = placeholder
        } else {
            uiView.textColor = .label
            uiView.text = text
        }
        context.coordinator.updateCharacterCount(text.count, minLength: minLength)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextViewWrapper
        var onCharacterCountChange: ((Int, Int) -> Void)?

        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                return
            }
            parent.text = textView.text
            onCharacterCountChange?(textView.text.count, parent.minLength)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                textView.text = nil
                textView.textColor = .label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }

        func updateCharacterCount(_ count: Int, minLength: Int) {
            onCharacterCountChange?(count, minLength)
        }
    }
}

// MARK: - 图片选择视图
struct ImagePickerView: View {
    @Binding var image: UIImage?
    let title: String
    let description: String
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let selectedImage = image {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 2)
                    )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("暂无图片")
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            HStack(spacing: 16) {
                Button(action: { showingCamera = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("拍照")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button(action: { showingPhotoLibrary = true }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("从相册选择")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $image)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $image)
        }
    }
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - 早睡早起验证视图
struct EarlySleepVerificationView: View {
    let isFirstUseTime: Date?
    let lastUseTime: Date?
    let targetSleepTime: Date
    let targetWakeTime: Date

    var body: some View {
        VStack(spacing: 16) {
            Text("早睡早起验证")
                .font(.headline)

            Text("系统将根据你的手机使用时间自动判定")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.purple)
                    Text("早睡判定：最后使用时间早于 \(formatTime(targetSleepTime))")
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("早起判定：首次使用时间晚于 \(formatTime(targetWakeTime))")
                        .font(.subheadline)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            if let firstUse = isFirstUseTime, let lastUse = lastUseTime {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sunrise")
                            .foregroundColor(.orange)
                        Text("首次使用：\(formatTime(firstUse))")
                            .font(.subheadline)
                    }

                    HStack {
                        Image(systemName: "sunset.fill")
                            .foregroundColor(.purple)
                        Text("最后使用：\(formatTime(lastUse))")
                            .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("暂无今日使用记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - ViewModel
class MissionVerificationViewModel: ObservableObject {
    @Published var textInput: String = ""
    @Published var selectedImage: UIImage?
    @Published var isSubmitting: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    @Published var firstUseTime: Date?
    @Published var lastUseTime: Date?
    @Published var targetSleepTime: Date
    @Published var targetWakeTime: Date

    @Published var characterCount: Int = 0
    @Published var meetsLengthRequirement: Bool = false

    init() {
        let calendar = Calendar.current
        var sleepComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        sleepComponents.hour = 23
        sleepComponents.minute = 0
        self.targetSleepTime = calendar.date(from: sleepComponents) ?? Date()

        var wakeComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        wakeComponents.hour = 7
        wakeComponents.minute = 0
        self.targetWakeTime = calendar.date(from: wakeComponents) ?? Date()
    }

    func canSubmit(missionType: MissionType) -> Bool {
        switch missionType {
        case .noFapDiary, .goodDeedRecord, .reading, .study:
            return textInput.count >= 50
        case .healthyDiet, .meditation, .morningExercise:
            return selectedImage != nil
        case .earlySleep:
            return checkEarlySleep()
        }
    }

    func checkEarlySleep() -> Bool {
        guard let lastUse = lastUseTime, let firstUse = firstUseTime else {
            return false
        }

        let calendar = Calendar.current
        let sleepTimeComponents = calendar.dateComponents([.hour, .minute], from: targetSleepTime)
        var targetSleepComponents = calendar.dateComponents([.year, .month, .day], from: lastUse)
        targetSleepComponents.hour = sleepTimeComponents.hour
        targetSleepComponents.minute = sleepTimeComponents.minute
        guard let targetSleep = calendar.date(from: targetSleepComponents) else {
            return false
        }

        let wakeTimeComponents = calendar.dateComponents([.hour, .minute], from: targetWakeTime)
        var targetWakeComponents = calendar.dateComponents([.year, .month, .day], from: firstUse)
        targetWakeComponents.hour = wakeTimeComponents.hour
        targetWakeComponents.minute = wakeTimeComponents.minute
        guard let targetWake = calendar.date(from: targetWakeComponents) else {
            return false
        }

        return lastUse <= targetSleep && firstUse >= targetWake
    }

    @MainActor
    func submitMission(missionType: MissionType, gameManager: GameManager) async {
        guard canSubmit(missionType: missionType) else {
            errorMessage = "请先完成验证要求"
            showErrorAlert = true
            return
        }

        isSubmitting = true
        try? await Task.sleep(nanoseconds: 500_000_000)

        let success = gameManager.completeMissionWithVerification(
            missionType,
            verificationText: textInput,
            verificationImage: selectedImage
        )

        isSubmitting = false

        if success {
            showSuccessAlert = true
        } else {
            errorMessage = "任务提交失败，请稍后重试"
            showErrorAlert = true
        }
    }

    func loadUsageRecords() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<UsageRecord> = UsageRecord.fetchRequest()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", today as CVarArg, tomorrow as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        do {
            let records = try context.fetch(request)
            if let firstRecord = records.first,
               let lastRecord = records.last {
                self.firstUseTime = firstRecord.date
                self.lastUseTime = lastRecord.date
            }
        } catch {
            print("Error loading usage records: \(error)")
        }
    }
}

#if DEBUG
#Preview {
    MissionVerificationView(
        missionType: .noFapDiary,
        viewModel: MissionVerificationViewModel()
    )
    .environmentObject(GameManager())
}
#endif
