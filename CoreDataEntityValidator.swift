import Foundation
import CoreData

// Core Data实体验证测试类
class CoreDataEntityValidator {
    
    // 单例模式
    static let shared = CoreDataEntityValidator()
    private init() {}
    
    // 运行完整验证测试
    func runFullValidation() {
        print("=================================")
        print("Core Data 实体完整性验证测试")
        print("=================================\n")
        
        // 测试1: 验证Core Data初始化
        testCoreDataInitialization()
        
        // 测试2: 验证所有实体定义
        testAllEntities()
        
        // 测试3: 测试MissionRecord实体
        testMissionRecordEntity()
        
        // 测试4: 测试DrawRecord实体
        testDrawRecordEntity()
        
        // 测试5: 测试UsageRecord实体
        testUsageRecordEntity()
        
        // 测试6: 测试实体间的关联和查询
        testEntityQueries()
        
        print("\n=================================")
        print("验证测试完成！")
        print("=================================")
    }
    
    // 测试1: Core Data初始化
    private func testCoreDataInitialization() {
        print("📋 测试1: Core Data 初始化")
        
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        print("✅ Core Data 初始化成功")
        print("   Context: \(context)")
        print()
    }
    
    // 测试2: 验证所有实体定义
    private func testAllEntities() {
        print("📋 测试2: 验证所有实体定义")
        
        let controller = PersistenceController(inMemory: true)
        let model = controller.container.managedObjectModel
        
        let expectedEntities = ["User", "Card", "MissionRecord", "DrawRecord", "UsageRecord"]
        
        for entityName in expectedEntities {
            if let entity = model.entitiesByName[entityName] {
                print("✅ 实体 '\(entityName)' 已定义")
                print("   属性数量: \(entity.properties.count)")
            } else {
                print("❌ 实体 '\(entityName)' 未找到")
            }
        }
        print()
    }
    
    // 测试3: MissionRecord实体
    private func testMissionRecordEntity() {
        print("📋 测试3: 测试 MissionRecord 实体")
        
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // 创建测试记录
        let missionRecord = MissionRecord(context: context)
        missionRecord.id = UUID()
        missionRecord.type = MissionType.reading.rawValue
        missionRecord.completedDate = Date()
        missionRecord.probabilityBoost = 0.3
        
        do {
            try context.save()
            print("✅ MissionRecord 创建成功")
            print("   ID: \(missionRecord.id?.uuidString ?? "无")")
            print("   类型: \(missionRecord.missionName)")
            print("   概率提升: \(missionRecord.formattedProbabilityBoost)")
            
            // 测试查询
            let fetchRequest: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
            let results = try context.fetch(fetchRequest)
            print("   查询结果数量: \(results.count)")
            
            // 测试查询谓词
            let todayPredicate = MissionRecord.predicateForToday()
            fetchRequest.predicate = todayPredicate
            let todayResults = try context.fetch(fetchRequest)
            print("   今日任务数量: \(todayResults.count)")
            
        } catch {
            print("❌ MissionRecord 测试失败: \(error)")
        }
        print()
    }
    
    // 测试4: DrawRecord实体
    private func testDrawRecordEntity() {
        print("📋 测试4: 测试 DrawRecord 实体")
        
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // 创建测试记录
        let userId = UUID()
        let cardId = UUID()
        let drawRecord = DrawRecord(context: context, cardId: cardId, userId: userId)
        
        do {
            try context.save()
            print("✅ DrawRecord 创建成功")
            print("   ID: \(drawRecord.id?.uuidString ?? "无")")
            print("   抽卡时间: \(drawRecord.formattedTimestamp)")
            print("   相对时间: \(drawRecord.relativeTimeDescription)")
            print("   是否今天: \(drawRecord.isToday)")
            
            // 测试查询
            let fetchRequest: NSFetchRequest<DrawRecord> = DrawRecord.fetchRequest()
            fetchRequest.sortDescriptors = DrawRecord.sortByTimestampDescending
            let results = try context.fetch(fetchRequest)
            print("   查询结果数量: \(results.count)")
            
            // 测试今日查询
            fetchRequest.predicate = DrawRecord.predicateForToday()
            let todayResults = try context.fetch(fetchRequest)
            print("   今日抽卡次数: \(todayResults.count)")
            
        } catch {
            print("❌ DrawRecord 测试失败: \(error)")
        }
        print()
    }
    
    // 测试5: UsageRecord实体
    private func testUsageRecordEntity() {
        print("📋 测试5: 测试 UsageRecord 实体")
        
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // 创建测试记录（2小时使用时长）
        let userId = UUID()
        let duration = 2.0 * 3600 // 2小时
        let usageRecord = UsageRecord(context: context, duration: duration, userId: userId)
        
        do {
            try context.save()
            print("✅ UsageRecord 创建成功")
            print("   ID: \(usageRecord.id?.uuidString ?? "无")")
            print("   使用时长: \(usageRecord.formattedDuration)")
            print("   使用评级: \(usageRecord.usageRating)")
            print("   是否超标: \(usageRecord.isOverLimit)")
            print("   是否优秀: \(usageRecord.isExcellent)")
            
            // 测试查询
            let fetchRequest: NSFetchRequest<UsageRecord> = UsageRecord.fetchRequest()
            fetchRequest.sortDescriptors = UsageRecord.sortByDateDescending
            let results = try context.fetch(fetchRequest)
            print("   查询结果数量: \(results.count)")
            
            // 测试统计功能
            let avgDuration = UsageRecord.calculateAverageDuration(from: results)
            print("   平均使用时长: \(String(format: "%.2f", avgDuration / 3600)) 小时")
            
        } catch {
            print("❌ UsageRecord 测试失败: \(error)")
        }
        print()
    }
    
    // 测试6: 实体查询和关联
    private func testEntityQueries() {
        print("📋 测试6: 测试实体查询和关联")
        
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let userId = UUID()
        
        // 创建多条不同类型的记录
        do {
            // 创建3条任务记录
            for missionType in [MissionType.reading, MissionType.morningExercise, MissionType.study] {
                let mission = MissionRecord(context: context)
                mission.id = UUID()
                mission.type = missionType.rawValue
                mission.completedDate = Date()
                mission.probabilityBoost = missionType.probabilityBoost
            }
            
            // 创建5条抽卡记录
            for _ in 1...5 {
                let draw = DrawRecord(context: context, cardId: UUID(), userId: userId)
            }
            
            // 创建3条使用记录
            for hour in [1.5, 2.5, 3.5] {
                let usage = UsageRecord(context: context, duration: hour * 3600, userId: userId)
            }
            
            try context.save()
            print("✅ 批量创建记录成功")
            
            // 查询统计
            let missionCount = try context.count(for: MissionRecord.fetchRequest())
            let drawCount = try context.count(for: DrawRecord.fetchRequest())
            let usageCount = try context.count(for: UsageRecord.fetchRequest())
            
            print("   任务记录总数: \(missionCount)")
            print("   抽卡记录总数: \(drawCount)")
            print("   使用记录总数: \(usageCount)")
            
            // 测试复杂查询
            let todayMissions: NSFetchRequest<MissionRecord> = MissionRecord.fetchRequest()
            todayMissions.predicate = MissionRecord.predicateForToday()
            let todayMissionCount = try context.count(for: todayMissions)
            print("   今日完成任务数: \(todayMissionCount)")
            
            let todayDraws: NSFetchRequest<DrawRecord> = DrawRecord.fetchRequest()
            todayDraws.predicate = DrawRecord.predicateForToday()
            let todayDrawCount = try context.count(for: todayDraws)
            print("   今日抽卡次数: \(todayDrawCount)")
            
            // 测试使用记录统计
            let usageFetch: NSFetchRequest<UsageRecord> = UsageRecord.fetchRequest()
            let usageRecords = try context.fetch(usageFetch)
            let avgUsage = UsageRecord.calculateAverageDuration(from: usageRecords)
            let totalUsage = UsageRecord.calculateTotalDuration(from: usageRecords)
            
            print("   平均使用时长: \(String(format: "%.2f", avgUsage / 3600)) 小时")
            print("   总使用时长: \(String(format: "%.2f", totalUsage / 3600)) 小时")
            
        } catch {
            print("❌ 查询测试失败: \(error)")
        }
        print()
    }
}

// 运行验证测试
// 取消下面的注释来运行测试
// let validator = CoreDataEntityValidator.shared
// validator.runFullValidation()
