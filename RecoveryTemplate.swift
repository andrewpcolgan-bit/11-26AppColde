import Foundation

struct RecoveryTemplate: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var description: String?
    var createdAt: Date
    var tasks: [RecoveryTask]
    
    init(id: UUID = UUID(), name: String, description: String? = nil, createdAt: Date = Date(), tasks: [RecoveryTask]) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.tasks = tasks
    }
    
    // Computed properties for display
    var taskCount: Int {
        tasks.count
    }
    
    var quickTaskCount: Int {
        tasks.filter { $0.includeInQuick }.count
    }
    
    var isQuickRoutine: Bool {
        quickTaskCount >= taskCount / 2
    }
    
    var estimatedMinutes: Int {
        // Rough estimate: 2 minutes per task
        taskCount * 2
    }
}
