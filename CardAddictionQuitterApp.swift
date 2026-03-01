import SwiftUI

@main
struct CardAddictionQuitterApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var gameManager = GameManager()
    
    init() {
        // Initialize card templates on first launch
        let context = PersistenceController.shared.container.viewContext
        CardTemplateInitializer.shared.initializeTemplates(context: context)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(gameManager)
        }
    }
}
