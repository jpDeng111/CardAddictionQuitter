import Foundation
import CoreData

// 重构后数据库完整测试
class RefactoredDatabaseTest {
    
    static let shared = RefactoredDatabaseTest()
    private init() {}
    
    // 运行完整测试
    func runFullTest() {
        print("=================================")
        print("重构后数据库完整测试")
        print("=================================\n")
        
        // 使用内存存储进行测试
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // 测试1: 初始化卡片模板
        test1_InitializeTemplates(context: context)
        
        // 测试2: 创建用户
        let userId = test2_CreateUser(context: context)
        
        // 测试3: 测试抽卡系统
        test3_GachaSystem(userId: userId, context: context)
        
        // 测试4: 测试任务系统
        test4_MissionSystem(userId: userId, context: context)
        
        // 测试5: 测试使用记录
        test5_UsageRecords(userId: userId, context: context)
        
        // 测试6: 测试时间兑换逻辑
        test6_TimeExchangeLogic(userId: userId, context: context)
        
        // 测试7: 综合统计
        test7_Statistics(userId: userId, context: context)
        
        print("\n=================================")
        print("所有测试完成！")
        print("=================================")
    }
    
    // 测试1: 初始化卡片模板
    private func test1_InitializeTemplates(context: NSManagedObjectContext) {
        print("📋 测试1: 初始化卡片模板")
        
        CardTemplateInitializer.shared.initializeTemplates(context: context)
        
        let stats = CardTemplateInitializer.shared.getTemplateStatistics(context: context)
        print(stats)
        print()
    }
    
    // 测试2: 创建用户
    private func test2_CreateUser(context: NSManagedObjectContext) -> UUID {
        print("📋 测试2: 创建测试用户")
        
        let userId = UUID()
        print("✅ 用户ID: \(userId.uuidString)")
        print()
        
        return userId
    }
    
    // 测试3: 测试抽卡系统
    private func test3_GachaSystem(userId: UUID, context: NSManagedObjectContext) {
        print("📋 测试3: 测试抽卡系统")
        
        let gachaSystem = GachaSystemV2.shared
        
        // 单抽测试
        print("  执行单抽...")
        if let card = gachaSystem.draw(userId: userId, context: context) {
            print("  ✅ 抽到卡片:")
            print("     角色: \(card.getCardName(context: context))")
            print("     系列: \(card.getAnimeSeries(context: context))")
            print("     稀有度: \(card.getRarity(context: context).displayName)")
            print("     等级: Lv.\(card.level)")
        }
        
        // 10连抽测试
        print("\n  执行10连抽...")
        let cards = gachaSystem.drawMultiple(userId: userId, count: 10, context: context)
        print("  ✅ 抽到 \(cards.count) 张卡片:")
        
        var rarityCounts: [Rarity: Int] = [.N: 0, .R: 0, .SR: 0, .SSR: 0]
        for card in cards {
            let rarity = card.getRarity(context: context)
            rarityCounts[rarity, default: 0] += 1
        }
        
        print("     N: \(rarityCounts[.N] ?? 0)张")
        print("     R: \(rarityCounts[.R] ?? 0)张")
        print("     SR: \(rarityCounts[.SR] ?? 0)张")
        print("     SSR: \(rarityCounts[.SSR] ?? 0)张")
        
        // 显示抽卡统计
        let stats = gachaSystem.getDrawStatistics(userId: userId, context: context)
        print("\n  抽卡统计:")
        print("     " + stats.description.replacingOccurrences(of: "\n", with: "\n     "))
        print()
    }
    
    // 测试4: 测试任务系统
    private func test4_MissionSystem(userId: UUID, context: NSManagedObjectContext) {
        print("📋 测试4: 测试任务系统")
        
        let missionSystem = DefaultMissionSystem.shared
        
        // 完成几个任务
        let missions: [MissionType] = [.reading, .morningExercise, .study]
        
        for mission in missions {
            if missionSystem.completeMission(type: mission) {
                print("  ✅ 完成任务: \(mission.name)")
                print("     难度: \(mission.difficulty)")
                print("     概率提升: +\(Int(mission.probabilityBoost * 100))%")
            }
        }
        
        let totalBoost = missionSystem.getProbabilityBoost()
        print("\n  当前总概率提升: +\(Int(totalBoost * 100))%")
        print()
    }
    
    // 测试5: 测试使用记录
    private func test5_UsageRecords(userId: UUID, context: NSManagedObjectContext) {
        print("📋 测试5: 测试使用记录")
        
        // 创建几条使用记录
        let durations: [Double] = [1.5, 2.5, 3.5] // 小时
        
        for (index, hours) in durations.enumerated() {
            let duration = hours * 3600 // 转换为秒
            let record = UsageRecord(context: context, duration: duration, userId: userId)
            
            // 设置不同的日期
            let calendar = Calendar.current
            if let date = calendar.date(byAdding: .day, value: -index, to: Date()) {
                record.date = date
            }
        }
        
        do {
            try context.save()
            print("  ✅ 创建了 \(durations.count) 条使用记录")
            
            // 统计
            let request: NSFetchRequest<UsageRecord> = UsageRecord.fetchRequest()
            request.predicate = UsageRecord.predicateForUser(userId: userId)
            let records = try context.fetch(request)
            
            let avgDuration = UsageRecord.calculateAverageDuration(from: records)
            let totalDuration = UsageRecord.calculateTotalDuration(from: records)
            
            print("     平均使用时长: \(String(format: "%.2f", avgDuration / 3600)) 小时")
            print("     总使用时长: \(String(format: "%.2f", totalDuration / 3600)) 小时")
        } catch {
            print("  ❌ 保存使用记录失败: \(error)")
        }
        print()
    }
    
    // 测试6: 测试时间兑换逻辑
    private func test6_TimeExchangeLogic(userId: UUID, context: NSManagedObjectContext) {
        print("📋 测试6: 测试时间兑换逻辑")
        
        let timeManager = TimeExchangeManager.shared
        
        // 测试不同使用时长的抽卡次数
        let testHours: [Double] = [1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
        
        print("  使用时长 → 可获得抽卡次数:")
        for hours in testHours {
            let draws = timeManager.calculateDrawChances(usageHours: hours)
            let emoji = hours <= 1.5 ? "🌟" : (hours <= 3.0 ? "✅" : "⚠️")
            print("     \(emoji) \(hours)小时 → \(draws)次")
        }
        
        // 测试今日剩余抽卡次数
        let remaining = timeManager.getRemainingDrawsForToday(userId: userId)
        print("\n  今日剩余抽卡次数: \(remaining)")
        
        // 测试进度信息
        let progress = timeManager.getProgressInfo()
        print("  使用时间进度:")
        print("     当前: \(String(format: "%.2f", progress.currentHours))小时")
        print("     目标: \(progress.targetHours)小时")
        print("     进度: \(String(format: "%.1f", progress.progressPercentage * 100))%")
        print()
    }
    
    // 测试7: 综合统计
    private func test7_Statistics(userId: UUID, context: NSManagedObjectContext) {
        print("📋 测试7: 综合统计")
        
        // 用户卡片统计
        let totalCards = UserCard.countUserCards(userId: userId, context: context)
        print("  用户拥有卡片总数: \(totalCards)")
        
        let rarityCounts = UserCard.countByRarity(userId: userId, context: context)
        print("  按稀有度分布:")
        print("     SSR: \(rarityCounts[.SSR] ?? 0)张")
        print("     SR: \(rarityCounts[.SR] ?? 0)张")
        print("     R: \(rarityCounts[.R] ?? 0)张")
        print("     N: \(rarityCounts[.N] ?? 0)张")
        
        // 平均等级
        let avgLevel = UserCard.averageLevel(userId: userId, context: context)
        print("\n  平均卡片等级: \(String(format: "%.2f", avgLevel))")
        
        // 最高等级卡片
        if let highestCard = UserCard.highestLevelCard(userId: userId, context: context) {
            print("  最高等级卡片:")
            print("     \(highestCard.getCardName(context: context)) Lv.\(highestCard.level)")
        }
        
        // 收藏数量
        let favoriteCount = UserCard.favoriteCount(userId: userId, context: context)
        print("\n  收藏卡片数: \(favoriteCount)")
        
        // 任务完成情况
        let todayMissions = DefaultMissionSystem.shared.getTodayCompletedMissions()
        print("\n  今日完成任务: \(todayMissions.count)个")
        for mission in todayMissions {
            print("     - \(mission.name)")
        }
        
        print()
    }
    
    // 测试用户卡片升级
    func testCardLevelUp(context: NSManagedObjectContext) {
        print("\n📋 额外测试: 卡片升级系统")
        
        let userId = UUID()
        
        // 初始化模板
        CardTemplateInitializer.shared.initializeTemplates(context: context)
        
        // 抽一张卡
        if let card = GachaSystemV2.shared.draw(userId: userId, context: context) {
            print("  抽到卡片: \(card.getCardName(context: context)) Lv.\(card.level)")
            print("  初始属性: 攻击\(card.getCurrentAttack(context: context)) 防御\(card.getCurrentDefense(context: context))")
            
            // 添加经验升级
            print("\n  添加经验值...")
            for i in 1...5 {
                let exp: Int32 = 150
                let didLevelUp = card.addExperience(exp, context: context)
                
                if didLevelUp {
                    print("  🎉 升级! Lv.\(card.level)")
                    print("     当前属性: 攻击\(card.getCurrentAttack(context: context)) 防御\(card.getCurrentDefense(context: context))")
                } else {
                    print("  添加 \(exp) 经验 (进度: \(String(format: "%.1f", card.experienceProgress * 100))%)")
                }
            }
        }
        
        print()
    }
}

// 运行测试（取消注释来执行）
// let tester = RefactoredDatabaseTest.shared
// tester.runFullTest()
// tester.testCardLevelUp(context: PersistenceController(inMemory: true).container.viewContext)
