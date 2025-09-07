import Foundation

// 简单的测试运行器
func runTests() {
    print("准备运行游戏系统测试...")
    print("请确保所有依赖项已正确配置")
    print("\n===== 游戏系统测试启动 =====\n")
    
    do {
        // 这里我们可以直接调用测试类
        // 注意：在实际使用中，您需要确保所有类都已正确导入
        
        print("测试提示：")
        print("1. 您可以通过 Xcode 运行 GameSystemTest.swift 来执行详细测试")
        print("2. 测试将验证以下核心功能：")
        print("   - 任务系统的完成、查询和冷却机制")
        print("   - 抽卡系统的单抽和10连抽功能")
        print("   - 任务系统和抽卡系统的集成（概率提升）")
        print("   - 保底机制的基本功能")
        print("\n建议在Xcode中直接运行GameSystemTest类进行完整测试")
        
        // 快速测试一些基本功能
        quickTest()
        
    } catch {
        print("测试执行失败：\(error)")
    }
}

// 快速测试基本功能
func quickTest() {
    print("\n===== 基本功能快速测试 =====")
    
    // 测试Core Data是否初始化成功
    let persistenceTestResult = testPersistence()
    print("Core Data 初始化：\(persistenceTestResult ? "成功" : "失败")")
    
    // 测试枚举是否可以正确访问
    print("\n任务类型枚举测试：")
    print("任务类型数量：\(MissionType.allCases.count)")
    
    // 测试抽卡系统是否可以实例化
    let gachaSystem = GachaSystem()
    print("\n抽卡系统测试：")
    print(gachaSystem.getProbabilityDescription())
    
    print("\n===== 基本功能快速测试完成 =====")
}

// 测试Core Data初始化
func testPersistence() -> Bool {
    do {
        let persistenceController = PersistenceController(inMemory: true)
        return persistenceController.container.persistentStoreCoordinator.persistentStores.count > 0
    } catch {
        return false
    }
}

// 运行测试
runTests()