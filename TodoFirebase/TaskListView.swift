import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm: TaskViewModel

    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var editingTask: TodoItem?

    init(uid: String) {
        _vm = StateObject(wrappedValue: TaskViewModel(uid: uid))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("My Tasks").font(.title).bold()
                Spacer()
                Text(auth.email).foregroundColor(.secondary)
                Button("Logout") { auth.signOut() }
            }

            // CREATE form
            GroupBox("New Task") {
                VStack(alignment: .leading) {
                    TextField("Title", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                    TextField("Description", text: $newDescription)
                        .textFieldStyle(.roundedBorder)
                    Button("Add Task") {
                        vm.addTask(title: newTitle, description: newDescription)
                        newTitle = ""
                        newDescription = ""
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(4)
            }

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage).foregroundColor(.red).font(.caption)
            }

            // READ list
            List {
                ForEach(vm.tasks) { task in
                    HStack(alignment: .top) {
                        Button {
                            vm.toggleDone(task)
                        } label: {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.headline)
                                .strikethrough(task.isDone)
                            if !task.description.isEmpty {
                                Text(task.description)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button("Edit") { editingTask = task }     // UPDATE
                        Button("Delete") { vm.deleteTask(task) }  // DELETE
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task) { updated in
                vm.updateTask(updated)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Edit Task").font(.title2).bold()
            TextField("Title", text: $task.title)
                .textFieldStyle(.roundedBorder)
            TextField("Description", text: $task.description)
                .textFieldStyle(.roundedBorder)
            Toggle("Completed", isOn: $task.isDone)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    onSave(task)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 380)
    }
}
