//
//  LessonTableViewController.swift
//  CoreData1
//
//  Created by Gopabandhu on 25/01/20.
//  Copyright © 2020 Gopabandhu. All rights reserved.
//

import UIKit
import CoreData

class LessonTableViewController: UITableViewController {
    
    var moc: NSManagedObjectContext?{
        
        didSet{
            if let moc = moc{
                lessonService = LessonService(moc: moc)
            }
        }
    }
    
    private var lessonService: LessonService?
    private var arrOfStudents = [Student]()
    private var arrOfUpdatedStudents: Student?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        moc = appDelegate?.persistentContainer.viewContext
        
        tableView.delegate = self
        tableView.dataSource = self
        loadStudents()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return arrOfStudents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudentTableViewCell", for: indexPath)
        cell.textLabel?.text = arrOfStudents[indexPath.row].name
        cell.detailTextLabel?.text = arrOfStudents[indexPath.row].lesson?.type
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        arrOfUpdatedStudents = arrOfStudents[indexPath.row]
        present(showAlert(with: "Update"), animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            
            lessonService?.delete(student: arrOfStudents[indexPath.row])
            arrOfStudents.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    @IBAction func btnAdd(_ sender: UIBarButtonItem) {
        
        present(showAlert(with: "Add"), animated: true, completion: nil)
    }
    
    //MARK: - Helper Methods

    private func showAlert(with action: String) -> UIAlertController{
        
        let alert = UIAlertController(title: "Student Details", message: "Student Info", preferredStyle: .alert)
        
        alert.addTextField { [weak self] (textField) in
            textField.placeholder = "Enter name"
            textField.text = self?.arrOfUpdatedStudents == nil ? "" : self?.arrOfUpdatedStudents?.name
        }
        
        alert.addTextField { [weak self] (textField) in
            textField.placeholder = "Enter Lesson"
            textField.text = self?.arrOfUpdatedStudents == nil ? "" : self?.arrOfUpdatedStudents?.lesson?.type
        }
        
        let defaultAction = UIAlertAction(title: action.uppercased(), style: .default) { [weak self] (alertAction) in
            
            guard let studentName = alert.textFields?[0].text, let lesson = alert.textFields?[1].text else{
                return
            }
            
            if action.caseInsensitiveCompare("add") == .orderedSame{
                
                if let lessonType = LessonType(rawValue: lesson.lowercased()){
                    
                    self?.lessonService?.addStudent(name: studentName, for: lessonType, completion: { (success, students) in
                        
                        if success{
                            self?.arrOfStudents = students
                        }
                    })
                }
            }else{
                
                guard let name = alert.textFields?.first?.text, !name.isEmpty,
                    let studentToUpdate = self?.arrOfUpdatedStudents,
                    let lessonType = alert.textFields?[1].text else {return}
                
                self?.lessonService?.update(currentStudent: studentToUpdate, name: name, forLesson: lessonType)
                self?.arrOfUpdatedStudents = nil
            }
            
            DispatchQueue.main.async {
                
                self?.loadStudents()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (alertAction) in
            self?.arrOfUpdatedStudents = nil
        }
        
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    private func loadStudents(){
        
        if let students = lessonService?.getAllStudents(){
            
            arrOfStudents = students
            tableView.reloadData()
        }
    }
}
