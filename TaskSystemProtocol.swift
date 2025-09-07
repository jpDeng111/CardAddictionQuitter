import Foundation
import CoreData

// 任务系统协议
enum MissionDifficulty: Int {
    case easy = 1
    case medium = 2
    case hard = 3
}

// 任务类型枚举
enum MissionType {
    case noFapDiary
    case goodDeedRecord
    case morningExercise
    case reading
    case meditation
    case study
    case earlySleep
    case healthyDiet
    
    // 任务名称和描述
    var name: String {
        switch self {
        case .noFapDiary: return "写戒色日记"
        case .goodDeedRecord: return "记录善举"
        case .morningExercise: return "晨练"
        case .reading: return "阅读学习"
        case .meditation: return "冥想放松"
        case .study: return "专注学习"
        case .earlySleep: return "早睡早起"
        case .healthyDiet: return "健康饮食"
        }
    }
    
    var description: String {
        switch self {
        case .noFapDiary: return "记录今日戒色心得，保持积极心态"
        case .goodDeedRecord: return "记录今天做的一件好事，传递正能量"
        case .morningExercise: return "早上进行至少15分钟的运动，保持身体健康"
        case .reading: return "阅读至少30分钟，充实知识储备"
        case .meditation: return "进行10分钟冥想，放松身心"
        case .study: return "专注学习至少1小时，提升自我"
        case .earlySleep: return "在23点前入睡，保证充足睡眠"
        case .healthyDiet: return "今日保持健康饮食，远离垃圾食品"
        }
    }
    
    var difficulty: MissionDifficulty {
        switch self {
        case .noFapDiary, .goodDeedRecord: return .easy
        case .morningExercise, .reading, .meditation: return .medium
        case .study, .earlySleep, .healthyDiet: return .hard
        }
    }
    
    // 任务完成后的概率提升值
    var probabilityBoost: Double {
        switch difficulty {
        case .easy: return 0.1 // 10%
        case .medium: return 0.3 // 30%
        case .hard: return 0.5 // 50%
        }
    }
}

// 任务系统协议
protocol MissionSystem {
    func completeMission(type: MissionType) -> Bool
    func getProbabilityBoost() -> Double
    func getTodayCompletedMissions() -> [MissionType]
    func canCompleteMission(type: MissionType) -> Bool
}

// 任务系统实现类
class DefaultMissionSystem: MissionSystem {
    // 单例模式
    static let shared = DefaultMissionSystem()
    private init() {}
    
    // 任务冷却时间（秒）- 防止重复完成同一任务
    private let missionCooldown: TimeInterval = 86400 // 24小时
    
    // 完成任务
    func completeMission(type: MissionType) -> Bool {
        // 检查是否可以完成该任务
        guard canCompleteMission(type: type) else {
            return false
        }
        
        // 记录任务完成
        let context = PersistenceController.shared.container.viewContext
        let missionRecord = MissionRecord(context: context)
        missionRecord.id = UUID()
        missionRecord.type = type.rawValue
        missionRecord.completedDate = Date()
        missionRecord.probabilityBoost = type.probabilityBoost
        
        do {
            try context.save()
            return true
        } catch {
            print("Error saving mission record: \(error)")
            return false
        }
    }
    
    // 获取当前可用的概率提升
    func getProbabilityBoost() -> Double {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        
        // 只查询今天的任务记录
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "completedDate >= %@ AND completedDate < %@", today as CVarArg, tomorrow as CVarArg)
        
        do {
            let records = try context.fetch(request)
            // 计算总概率提升（累加所有任务的提升值）
            let totalBoost = records.reduce(0.0) { $0 + $1.probabilityBoost }
            return min(1.0, totalBoost) // 最大提升100%
        } catch {
            print("Error fetching mission records: \(error)")
            return 0.0
        }
    }
    
    // 获取今日已完成的任务列表
    func getTodayCompletedMissions() -> [MissionType] {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        
        // 只查询今天的任务记录
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "completedDate >= %@ AND completedDate < %@", today as CVarArg, tomorrow as CVarArg)
        
        do {
            let records = try context.fetch(request)
            return records.compactMap { MissionType(rawValue: $0.type ?? "") }
        } catch {
            print("Error fetching mission records: \(error)")
            return []
        }
    }
    
    // 检查是否可以完成特定任务
    func canCompleteMission(type: MissionType) -> Bool {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
        
        // 检查该任务在冷却期内是否已完成
        let calendar = Calendar.current
        let cooldownDate = calendar.date(byAdding: .second, value: Int(-missionCooldown), to: Date())!
        
        request.predicate = NSPredicate(format: "type == %@ AND completedDate >= %@", type.rawValue, cooldownDate as CVarArg)
        
        do {
            let records = try context.fetch(request)
            return records.isEmpty
        } catch {
            print("Error checking mission cooldown: \(error)")
            return false
        }
    }
    
    // 获取当前可接取的任务列表
    func getAvailableMissions() -> [MissionType] {
        var availableMissions: [MissionType] = []
        
        // 检查所有任务类型
        for type in MissionType.allCases {
            if canCompleteMission(type: type) {
                availableMissions.append(type)
            }
        }
        
        return availableMissions
    }
}