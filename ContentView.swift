import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)
            
            GachaView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("抽卡")
                }
                .tag(1)
            
            CollectionView()
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("收藏")
                }
                .tag(2)
            
            MissionView()
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("任务")
                }
                .tag(3)
        }
        .accentColor(.purple)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
