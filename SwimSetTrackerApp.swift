import SwiftUI

@main
struct SwimSetTrackerApp: App {
    // Shared data model across all tabs
    @StateObject private var appData = AppData()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    init() {
        // Configure opaque tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppColor.background)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    TabView {
                        LogView()
                            .tabItem { Label("Log", systemImage: "camera.viewfinder") }

                        WeekView()
                            .tabItem { Label("My Week", systemImage: "calendar") }

                        StatsDashboardView()
                            .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                    }
                } else {
                    OnboardingFlowView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .environmentObject(appData)
        }
    }
}
