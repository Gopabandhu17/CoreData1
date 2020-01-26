//
//  LessonService.swift
//  CoreData1
//
//  Created by Gopabandhu on 25/01/20.
//  Copyright © 2020 Gopabandhu. All rights reserved.
//

import Foundation
import CoreData

enum LessonType: String{
    case swift, objective_c
}

typealias StudentHandler = (Bool, [Student]) -> ()

class LessonService{
    
    private let moc: NSManagedObjectContext
    private var students = [Student]()
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    //MARK:- Helper Methods
    
    //READ
    func getAllStudents() -> [Student]?{
        
        let sortByLesson = NSSortDescriptor(key: "lesson.type", ascending: true)
        let sortByName = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortByLesson, sortByName]
        
        let request: NSFetchRequest<Student> = Student.fetchRequest()
        request.sortDescriptors = sortDescriptors
        
        do {
            students = try moc.fetch(request)
            return students
        } catch let error {
            print("Error while fetching student \(error.localizedDescription)")
        }
        return nil
    }
    
    //CREATE
    func addStudent(name: String, for lesson: LessonType, completion: StudentHandler){
        
        let student = Student(context: moc)
        student.name = name
        
        if let lesson = lessonExists(lesson){
            register(student, for: lesson)
            students.append(student)
            completion(true, students)
        }
        save()
    }
    
    //UPDATE
    func update(currentStudent student: Student, name: String, forLesson lesson: String){
        
        //Check if student current lesson == new lesson type
        //only have to change name
        if student.lesson?.type?.caseInsensitiveCompare(lesson) == .orderedSame{
            
            let lesson = student.lesson
            let studentList = Array(lesson?.students?.mutableCopy() as! NSSet) as! [Student]
            
            if let index = studentList.firstIndex(where: {$0 == student}){
                
                studentList[index].name = name
                lesson?.students = NSSet(array: studentList)
            }
        }else{
            
            if let lessonType = LessonType(rawValue: lesson),
                let lesson = lessonExists(lessonType){
                
                lesson.removeFromStudents(student)
                
                student.name = name
                register(student, for: lesson)
            }
        }
        
        save()
    }
    
    private func lessonExists(_ type: LessonType) -> Lesson?{
        
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.predicate = NSPredicate(format: "type = %@", type.rawValue)
        var lesson: Lesson?
        do {
            let result = try moc.fetch(request)
            lesson = result.isEmpty ? addNew(lesson: type) : result.first
        } catch let error {
            print("Error while fetching lesson \(error.localizedDescription)")
        }
        return lesson
    }
    
    private func addNew(lesson type: LessonType) -> Lesson{
        
        let lesson = Lesson(context: moc)
        lesson.type = type.rawValue
        
        return lesson
    }
    
    private func register(_ student: Student, for lesson: Lesson){
        
        student.lesson = lesson
    }
    
    private func save(){
        
        do {
            try moc.save()
        } catch let error {
            print("Error while saving \(error.localizedDescription)")
        }
    }
}
