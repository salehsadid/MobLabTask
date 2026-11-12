import Foundation

// One task. (Named TodoItem because "Task" is already a Swift type)
struct TodoItem: Identifiable {
    var id: String
    var title: String
    var description: String
    var isDone: Bool
    var createdAt: String = ""
}

// CRUD operations on Cloud Firestore using the REST API.
// Data is stored at:  users/{uid}/tasks/{taskId}
class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoItem] = []
    @Published var errorMessage: String = ""
    @Published var isLoading = false

    private let auth: AuthViewModel
    private let tasksURL: String

    init(auth: AuthViewModel, uid: String) {
        self.auth = auth
        self.tasksURL = "\(FirebaseConfig.firestoreBase)/users/\(uid)/tasks"
    }

    // READ
    @MainActor func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await auth.validIdToken()
            let result = try await FirebaseREST.send("\(tasksURL)?pageSize=300", token: token)
            let documents = result["documents"] as? [[String: Any]] ?? []
            tasks = documents.map(parse).sorted { $0.createdAt > $1.createdAt } // newest first
            errorMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // CREATE
    @MainActor func addTask(title: String, description: String) {
        var body = fields(TodoItem(id: "", title: title, description: description, isDone: false))
        body["createdAt"] = ["timestampValue": ISO8601DateFormatter().string(from: Date())]
        run { token in
            _ = try await FirebaseREST.send(self.tasksURL, method: "POST",
                                            json: ["fields": body], token: token)
        }
    }

    // UPDATE
    @MainActor func updateTask(_ task: TodoItem) {
        let mask = "updateMask.fieldPaths=title&updateMask.fieldPaths=description&updateMask.fieldPaths=isDone"
        run { token in
            _ = try await FirebaseREST.send("\(self.tasksURL)/\(task.id)?\(mask)", method: "PATCH",
                                            json: ["fields": self.fields(task)], token: token)
        }
    }

    @MainActor func toggleDone(_ task: TodoItem) {
        var updated = task
        updated.isDone.toggle()
        updateTask(updated)
    }

    // DELETE
    @MainActor func deleteTask(_ task: TodoItem) {
        run { token in
            _ = try await FirebaseREST.send("\(self.tasksURL)/\(task.id)", method: "DELETE", token: token)
        }
    }

    // Runs one write operation, then reloads the list
    @MainActor private func run(_ operation: @escaping (String) async throws -> Void) {
        Task {
            do {
                let token = try await auth.validIdToken()
                try await operation(token)
                await loadTasks()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // TodoItem -> Firestore JSON fields
    private func fields(_ task: TodoItem) -> [String: Any] {
        [
            "title": ["stringValue": task.title],
            "description": ["stringValue": task.description],
            "isDone": ["booleanValue": task.isDone]
        ]
    }

    // Firestore JSON document -> TodoItem
    private func parse(_ document: [String: Any]) -> TodoItem {
        let name = document["name"] as? String ?? ""          // ".../tasks/<id>"
        let f = document["fields"] as? [String: Any] ?? [:]

        func value(_ key: String, _ type: String) -> Any? {
            (f[key] as? [String: Any])?[type]
        }

        return TodoItem(
            id: String(name.split(separator: "/").last ?? ""),
            title: value("title", "stringValue") as? String ?? "",
            description: value("description", "stringValue") as? String ?? "",
            isDone: value("isDone", "booleanValue") as? Bool ?? false,
            createdAt: value("createdAt", "timestampValue") as? String ?? ""
        )
    }
}
