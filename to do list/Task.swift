//
//  Task 2.swift
//  to do list
//
//  Created by Gareth Hill on 4/5/25.
//

import Foundation
import Supabase

// Rename Task to ToDoTask to avoid conflict with the concurrency Task type
struct ToDoTask: Identifiable, Codable {
    var id: UUID
    var name: String
}

// Task response from Supabase (for decoding the returned data)
struct TaskResponse: Codable {
    var id: String  // ID from Supabase, stored as String
    var name: String
}
