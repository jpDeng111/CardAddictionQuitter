import Foundation
import CoreData

// 游戏系统测试脚本
class GameSystemTest {
    // 初始化测试环境
    private let persistenceController = PersistenceController(inMemory: true) // 使用内存存储进行测试
    private var gachaSystem = GachaSystem()
    private let missionSystem = DefaultMissionSystem.shared
    
    // 运行完整测试
    func runFullTest() {
        print("===== 开始游戏系统测试 =====\n")
        
        // 测试1：任务系统
        testMissionSystem()
        
        // 测试2：抽卡系统
        testGachaSystem()
        
        // 测试3：任务系统和抽卡系统集成
        testMissionGachaIntegration()
        
        // 测试4：保底机制
        testPitySystem()
        
        print("\n===== 游戏系统测试完成 =====")
    }
    
    // 测试任务系统
    private func testMissionSystem() {
        print("----- 测试任务系统 -----")
        
        // 获取可用任务
        let availableMissions = missionSystem.getAvailableMissions()
        print("可用任务数量：\(availableMissions.count)")
        
        // 尝试完成一个简单任务
        if let missionType = availableMissions.first {
            print("尝试完成任务：\(missionType.name)")
            let success = missionSystem.completeMission(type: missionType)
            print("任务完成结果：\(success ? "成功" : "失败")")
            
            // 检查今日已完成任务
            let completedMissions = missionSystem.getTodayCompletedMissions()
            print("今日已完成任务数量：\(completedMissions.count)")
            
            // 检查是否无法重复完成同一任务
            let repeatSuccess = missionSystem.completeMission(type: missionType)
            print("重复完成同一任务结果：\(repeatSuccess ? "成功" : "失败")")
            
            // 检查概率提升值
            let probabilityBoost = missionSystem.getProbabilityBoost()
            print("当前概率提升值：\(String(format: "%.2f%%", probabilityBoost * 100))")
        }
        
        print("----- 任务系统测试完成 -----")
    }
    
    // 测试抽卡系统
    private func testGachaSystem() {
        print("\n----- 测试抽卡系统 -----")
        
        // 测试单抽
        print("执行单抽测试...")
        let singleCard = gachaSystem.draw()
        print("单抽结果：\n\(singleCard.cardDescription)")
        print("是否使用概率提升：\(singleCard.isBoosted ? "是" : "否")")
        
        // 测试10连抽
        print("\n执行10连抽测试...")
        let multipleCards = gachaSystem.drawMultiple(count: 10)
        
        // 统计抽卡结果
        var rarityCount: [Rarity: Int] = [:]
        for card in multipleCards {
            rarityCount[card.rarity, default: 0] += 1
        }
        
        // 打印抽卡统计
        print("10连抽结果统计：")
        for (rarity, count) in rarityCount {
            print("- \(rarity.displayName): \(count)张")
        }
        
        // 显示概率配置
        print("\n\(gachaSystem.getProbabilityDescription())")
        
        print("----- 抽卡系统测试完成 -----")
    }
    
    // 测试任务系统和抽卡系统集成
    private func testMissionGachaIntegration() {
        print("\n----- 测试任务系统和抽卡系统集成 -----")
        
        // 为了测试方便，我们手动创建一些任务记录来模拟概率提升
        print("创建模拟任务记录以获取概率提升...")
        
        // 手动添加一些任务记录到Core Data
        addMockMissionRecords()
        
        // 检查当前概率提升值
        let probabilityBoost = missionSystem.getProbabilityBoost()
        print("当前概率提升值：\(String(format: "%.2f%%", probabilityBoost * 100))")
        
        // 使用提升后的概率进行抽卡
        print("\n使用概率提升进行10连抽测试...")
        let boostedCards = gachaSystem.drawMultiple(count: 10)
        
        // 统计带概率提升的抽卡结果
        var boostedRarityCount: [Rarity: Int] = [:]
        var boostedCount = 0
        
        for card in boostedCards {
            boostedRarityCount[card.rarity, default: 0] += 1
            if card.isBoosted {
                boostedCount += 1
            }
        }
        
        // 打印带概率提升的抽卡统计
        print("带概率提升的10连抽结果统计：")
        for (rarity, count) in boostedRarityCount {
            print("- \(rarity.displayName): \(count)张")
        }
        print("使用概率提升的卡牌数量：\(boostedCount)")
        
        print("----- 任务系统和抽卡系统集成测试完成 -----")
    }
    
    // 添加模拟任务记录
    private func addMockMissionRecords() {
        let context = PersistenceController.shared.container.viewContext
        
        // 模拟完成几个高难度任务
        let hardMissions: [MissionType] = [.study, .earlySleep, .healthyDiet]
        
        for missionType in hardMissions {
            let missionRecord = MissionRecord(context: context)
            missionRecord.id = UUID()
            missionRecord.type = missionType.rawValue
            missionRecord.completedDate = Date()
            missionRecord.probabilityBoost = missionType.probabilityBoost
        }
        
        do {
            try context.save()
            print("成功添加\(hardMissions.count)个模拟任务记录")
        } catch {
            print("添加模拟任务记录失败：\(error)")
        }
    }
    
    // 测试保底机制
    private func testPitySystem() {
        print("\n----- 测试保底机制 -----")
        
        // 重置保底计数器
        gachaSystem.resetPityCounter()
        
        // 检查保底状态
        let pityStatus = gachaSystem.getPityStatus()
        print("初始保底状态 - SSR计数器：\(pityStatus.current)/\(pityStatus.threshold)，SR计数器：\(pityStatus.srCurrent)/\(pityStatus.srThreshold)")
        
        // 模拟9次抽卡，增加保底计数器
        print("模拟9次抽卡...")
        for _ in 1...9 {
            gachaSystem.incrementPityCounter()
        }
        
        // 检查保底状态
        let updatedPityStatus = gachaSystem.getPityStatus()
        print("更新后保底状态 - SSR计数器：\(updatedPityStatus.current)/\(updatedPityStatus.threshold)，SR计数器：\(updatedPityStatus.srCurrent)/\(updatedPityStatus.srThreshold)")
        
        // 执行第10次抽卡（应该触发SR保底）
        let tenthDraw = gachaSystem.draw()
        print("第10次抽卡结果：\n\(tenthDraw.cardDescription)")
        print("是否为SR或SSR：\(tenthDraw.rarity == .SR || tenthDraw.rarity == .SSR ? "是" : "否")")
        
        // 注意：在实际的抽卡系统中，保底逻辑应该在抽卡时自动处理
        // 这里只是展示保底机制的基本功能
        
        print("----- 保底机制测试完成 -----")
    }
}

// 运行测试
// 注意：在实际使用中，建议通过Xcode直接运行此测试
// let gameTest = GameSystemTest()
// gameTest.runFullTest()