import ScreenTime

class UsageTimeMonitor {
    private var schedule: STScreenTimeSchedule?
    private var coordinator: STScreenTimeConfigurationObserver?
    
    // 补全schedule初始化
    func startMonitoring() {
        let schedule = STScreenTimeSchedule(
            bluetoothDeviceIdentifiers: [],
            calendarIdentifiers: [],
            dayStartHour: 0,
            dayStartMinute: 0,
            endHour: 23,
            endMinute: 59,
            weekdays: [1,2,3,4,5,6,7]
        )
        
        coordinator = STScreenTimeConfigurationObserver(schedule: schedule) { [weak self] newSchedule in
            self?.schedule = newSchedule
        }
    }
    
    // 添加使用时间监听
    func trackUsageTime() async throws -> TimeInterval {
        let request = STScreenTimeConfigurationRequest(usage:
            .init(predicate: STUsageDetails.predicateForUsageDuringDates())
        )
        
        let response = try await request.perform()
        guard let usage = response.usageDetails.first else {
            throw NSError(domain: "UsageTimeError", code: 404)
        }
        
        // 存储到CoreData
        let context = PersistenceController.shared.container.viewContext
        let record = UsageRecord(context: context)
        record.date = Date()
        record.duration = usage.totalUsageTime
        try context.save()
        
        return usage.totalUsageTime
    }
}