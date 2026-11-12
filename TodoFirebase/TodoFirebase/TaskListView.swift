import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm: TaskViewModel

    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var editingTask: TodoItem?

    init(authModel: AuthViewModel, uid: String) {
        _vm = StateObject(wrappedValue: TaskViewModel(auth: authModel, uid: uid))
    }

    var body: some View {
        NavigationView {
            List {
                // CREATE form
                Section(header: Text("New Task")) {
                    TextField("Title", text: $newTitle)
                    TextField("Description", text: $newDescription)
                    Button("Add Task") {
                        vm.addTask(title: newTitle, description: newDescription)
                        newTitle = ""
                        newDescription = ""
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage).foregroundColor(.red).font(.caption)
                }

                if vm.isLoading {
                    ProgressView()
                }

                // READ list
                Section(header: Text("My Tasks (\(auth.email))")) {
                    ForEach(vm.tasks) { task in
                        HStack(alignment: .top) {
                            // Toggle done (UPDATE)
                            Button {
                                vm.toggleDone(task)
                            } label: {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderless)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.headline)
                                    .strikethrough(task.isDone)
                                if !task.description.isEmpty {
                                    Text(task.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // Edit (UPDATE)
                            Button {
                                editingTask = task
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)

                            // DELETE
                            Button {
                                vm.deleteTask(task)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Todo List")
            .task { await vm.loadTasks() }          // load tasks when screen opens
            .refreshable { await vm.loadTasks() }   // pull down to reload
            .toolbar {
                Button("Logout") { auth.signOut() }
            }
            .sheet(item: $editingTask) { task in
                EditTaskView(task: task) { updated in
                    vm.updateTask(updated)
                }
            }
        }
    }
}

// Popup sheet for editing a task
struct EditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @State var task: TodoItem
    var onSave: (TodoItem) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $task.title)
                TextField("Description", text: $task.description)
                Toggle("Completed", isOn: $task.isDone)
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(task)
                        dismiss()
                    }
                }
            }
        }
    }
}
