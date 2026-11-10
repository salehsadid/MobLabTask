import Foundation
import FirebaseFirestore

// One task. (Named TodoItem because "Task" is already a Swift keyword type)
struct TodoItem: Identifiable {
    var id: String
    var title: String
    var description: String
    var isDone: Bool
}

// CRUD operations on Firestore.
// Data is stored at:  users/{uid}/tasks/{taskId}
class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoItem] = []
    @Published var errorMessage: String = ""

    private let tasksRef: CollectionReference
    private var listener: ListenerRegistration?

    init(uid: String) {
        tasksRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("tasks")
        startListening()
    }

    deinit {
        listener?.remove()
    }

    // READ (real-time: list updates automatically after create/update/delete)
    private func startListening() {
        listener = tasksRef
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.tasks = snapshot?.documents.map { doc in
                    let data = doc.data()
                    return TodoItem(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        isDone: data["isDone"] as? Bool ?? false
                    )
                } ?? []
            }
    }

    // CREATE
    func addTask(title: String, description: String) {
        tasksRef.addDocument(data: [
            "title": title,
            "description": description,
            "isDone": false,
            "createdAt": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error { self?.errorMessage = error.localizedDescription }
        }
    }

    // UPDATE
    func updateTask(_ task: TodoItem) {
        tasksRef.document(task.id).updateData([
            "title": task.title,
            "description": task.description,
            "isDone": task.isDone
        ]) { [weak self] error in
            if let error = error { self?.errorMessage = error.localizedDescription }
        }
    }

    func toggleDone(_ task: TodoItem) {
        var updated = task
        updated.isDone.toggle()
        updateTask(updated)
    }

    // DELETE
    func deleteTask(_ task: TodoItem) {
        tasksRef.document(task.id).delete { [weak self] error in
            if let error = error { self?.errorMessage = error.localizedDescription }
        }
    }
}
