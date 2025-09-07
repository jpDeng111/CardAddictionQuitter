import CoreData

struct PersistenceController {
    // 单例模式
    static let shared = PersistenceController()
    
    // Core Data容器
    let container: NSPersistentContainer
    
    // 初始化Core Data堆栈
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // 替换为适当的错误处理代码
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // 自动合并来自iCloud的更改
        container.viewContext.automaticallyMergesChangesFromParent = true
        // 设置合并策略
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // 保存上下文的便捷方法
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // 创建新的后台上下文用于执行异步操作
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}

// 扩展Core Data的NSManagedObjectContext，添加便捷的保存方法
extension NSManagedObjectContext {
    func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch {
            rollback()
            print("Core Data save error: \(error)")
            return false
        }
    }
    
    func performChanges(_ block: @escaping () -> Void) {
        perform { [weak self] in
            block()
            _ = self?.saveOrRollback()
        }
    }
}

// 扩展String，为MissionType提供rawValue支持
extension MissionType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "noFapDiary": self = .noFapDiary
        case "goodDeedRecord": self = .goodDeedRecord
        case "morningExercise": self = .morningExercise
        case "reading": self = .reading
        case "meditation": self = .meditation
        case "study": self = .study
        case "earlySleep": self = .earlySleep
        case "healthyDiet": self = .healthyDiet
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .noFapDiary: return "noFapDiary"
        case .goodDeedRecord: return "goodDeedRecord"
        case .morningExercise: return "morningExercise"
        case .reading: return "reading"
        case .meditation: return "meditation"
        case .study: return "study"
        case .earlySleep: return "earlySleep"
        case .healthyDiet: return "healthyDiet"
        }
    }
    
    // 提供所有case的列表
    static var allCases: [MissionType] {
        return [.noFapDiary, .goodDeedRecord, .morningExercise, .reading, .meditation, .study, .earlySleep, .healthyDiet]
    }
}