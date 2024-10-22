//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

final class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private let storageManager = StorageManager.shared
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.title
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        
        sortTasks()
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        let newIndex = indexPath.section == 0 ? IndexPath(row: completedTasks.count, section: 1) : IndexPath(row: currentTasks.count, section: 0)
            
        
        let deleteSwipe = UIContextualAction(style: .destructive, title: "Delete") {[unowned self] _, _, _ in
            storageManager.delete(task: task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        
        let doneSwipe = UIContextualAction(style: .normal, title: "Done") {[unowned self] _, _, isDone in
            isDone(true)
            storageManager.done(task: task)
            sortTasks()
            tableView.moveRow(at: indexPath, to: newIndex)  
            print("move at \(indexPath) to \(newIndex)")
        }
        
        doneSwipe.backgroundColor = task.isComplete ? .green : .gray
        
        accessibilityHint = "Mark task as done"
        return UISwipeActionsConfiguration(actions: [doneSwipe, deleteSwipe])
        
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        content.text = task.title
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        showAlert(with: task){
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }

}

extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
        let alertBuilder = AlertControllerBuilder(
            title: task != nil ? "Edit Task" : "New Task",
            message: "What do you want to do?"
        )
        
        alertBuilder
            .setTextField(withPlaceholder: "Task Title", andText: task?.title)
            .setTextField(withPlaceholder: "Note Title", andText: task?.note)
            .addAction(
                title: task != nil ? "Update Task" : "Save Task",
                style: .default
            ) { [unowned self] taskTitle, taskNote in
                if let task, let completion {
                    // TODO: - edit task
                    storageManager.edit(task, setNewTitle: taskTitle, andNewNote: taskNote)
                    completion()
                } else {
                    createTask(withTitle: taskTitle, andNote: taskNote)
                }
            }
            .addAction(title: "Cancel", style: .destructive)
        
        let alertController = alertBuilder.build()
        present(alertController, animated: true)
    }
    
    private func sortTasks() {
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete= true")
        print("cu: \(currentTasks.count), co: \(completedTasks.count)")
    }
    
    private func createTask(withTitle title: String, andNote note: String) {
        storageManager.save(title, withNote: note, to: taskList) { task in
            let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
}
