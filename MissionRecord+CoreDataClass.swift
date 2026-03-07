import Foundation
import CoreData

// MissionRecord 类的 Core Data 实现
@objc(MissionRecord)
public class MissionRecord: NSManagedObject {

    // 从 MissionType 创建 MissionRecord 的便捷方法
    convenience init(context: NSManagedObjectContext, missionType: MissionType) {
        self.init(context: context)
        self.id = UUID()
        self.type = missionType.rawValue
        self.completedDate = Date()
        self.probabilityBoost = missionType.probabilityBoost
        self.isVerified = false
    }

    // 从 MissionType 创建 MissionRecord 带验证信息
    convenience init(context: NSManagedObjectContext, missionType: MissionType, verificationText: String?, verificationImage: UIImage?) {
        self.init(context: context)
        self.id = UUID()
        self.type = missionType.rawValue
        self.completedDate = Date()
        self.probabilityBoost = missionType.probabilityBoost
        self.verificationText = verificationText
        self.verificationImage = verificationImage?.jpegData(compressionQuality: 0.8)
        self.isVerified = true
        self.submittedAt = Date()
    }

    // 获取关联的 MissionType
    var missionType: MissionType? {
        guard let type = type else {
            return nil
        }
        return MissionType(rawValue: type)
    }

    // 获取任务名称
    var missionName: String {
        return missionType?.name ?? "未知任务"
    }

    // 获取任务描述
    var missionDescription: String {
        return missionType?.description ?? "无描述"
    }

    // 检查是否是今天完成的任务
    var isToday: Bool {
        guard let completedDate = completedDate else {
            return false
        }

        let calendar = Calendar.current
        return calendar.isDateInToday(completedDate)
    }

    // 获取任务完成的格式化时间
    var formattedCompletedTime: String {
        guard let completedDate = completedDate else {
            return "未知时间"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current

        return dateFormatter.string(from: completedDate)
    }

    // 获取概率提升的百分比表示
    var formattedProbabilityBoost: String {
        let percentage = Int(probabilityBoost * 100)
        return "+\(percentage)%"
    }

    // 获取验证图片（如果有）
    var verificationUIImage: UIImage? {
        guard let imageData = verificationImage else {
            return nil
        }
        return UIImage(data: imageData)
    }

    // 检查是否有验证内容
    var hasVerification: Bool {
        return isVerified && (verificationText != nil || verificationImage != nil)
    }
}
