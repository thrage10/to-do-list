//
//  ContentView.swift
//  to do list
//
//  Created by Gareth Hill on 4/5/25.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var tasks: [ToDoTask] = []  // Renamed here to ToDoTask
    @State private var newTaskName: String = ""
    @State private var currentUser: User? = nil
    @State private var isLoggedIn: Bool = false
    
    // Create a Supabase instance
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://zqyidgygoylzsyrdtzoh.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxeWlkZ3lnb3lsenN5cmR0em9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4ODQ1OTksImV4cCI6MjA1OTQ2MDU5OX0.2rgSHScD5LOmRIuTzh-1gMJRI8FYZOpFgqAm8AOqbms"
    )
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoggedIn {
                    List {
                        ForEach(tasks) { task in
                            Text(task.name)
                        }
                        .onDelete(perform: deleteTask)
                    }
                    
                    HStack {
                        TextField("New task", text: $newTaskName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addTask) {
                            Image(systemName: "plus")
                                .padding()
                        }
                        .disabled(newTaskName.isEmpty)
                    }
                    .padding()
                    
                    Button("Log Out") {
                        logout()
                    }
                    .padding()
                } else {
                    VStack {
                        TextField("Email", text: $newTaskName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        SecureField("Password", text: $newTaskName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Log In") {
                            login()
                        }
                        .padding()
                        
                        Button("Sign Up") {
                            signUp()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(isLoggedIn ? "To-Do List" : "Log In / Sign Up")
            .onAppear {
                checkLoggedInUser()
            }
        }
    }
    
    func checkLoggedInUser() {
        Task {
            // Use try? with await to safely attempt fetching the user
            if let user = try? await supabase.auth.user() {
                self.currentUser = user
                self.isLoggedIn = true
                await fetchTasks()  // Calling fetchTasks asynchronously
            } else {
                self.currentUser = nil
                self.isLoggedIn = false
            }
        }
    }
    
    func login() {
        Task {
            do {
                let response = try await supabase.auth.signIn(email: newTaskName, password: "password")
                self.currentUser = response.user
                self.isLoggedIn = true
                await fetchTasks()
            } catch {
                print("Error logging in: \(error)")
            }
        }
    }
    
    func signUp() {
        Task {
            do {
                let response = try await supabase.auth.signUp(email: newTaskName, password: "password")
                self.currentUser = response.user
                self.isLoggedIn = true
                await fetchTasks()
            } catch {
                print("Error signing up: \(error)")
            }
        }
    }
    
    func logout() {
        Task {
            do {
                try await supabase.auth.signOut()
                self.isLoggedIn = false
                self.tasks = []
            } catch {
                print("Error logging out: \(error)")
            }
        }
    }
    
    func addTask() {
        Task {
            // Make sure the block is asynchronous
            await addTaskAsync()
        }
    }
    
    func addTaskAsync() async {
        guard let userIdString = currentUser?.id else { return }
        
        // userIdString should already be a string, but if it's a UUID, convert it to a string
        let userId = userIdString.uuidString // Ensures the userId is in string format
        
        let task = ToDoTask(id: UUID(), name: newTaskName)
        
        do {
            // Insert task to Supabase (user_id is passed as a String)
            _ = try await supabase.from("tasks").insert([
                ["name": task.name, "user_id": userId]  // Pass UUID as string
            ]).execute()
            
            tasks.append(task)
            newTaskName = ""  // Clear the input field
        } catch {
            print("Error adding task: \(error)")
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let task = tasks[index]
                
                do {
                    // Delete task from Supabase
                    _ = try await supabase.from("tasks").delete().eq("id", value: task.id.uuidString).execute()
                } catch {
                    print("Error deleting task: \(error)")
                }
            }
            tasks.remove(atOffsets: offsets)
        }
    }
    
    func fetchTasks() async {
        guard let userId = currentUser?.id else { return }

        do {
            // Fetch tasks from Supabase
            let response = try await supabase.from("tasks")
                .select()
                .eq("user_id", value: userId)
                .execute()

            // Directly decode the response data into TaskResponse objects
            let taskResponses = try JSONDecoder().decode([TaskResponse].self, from: response.data)

            // Map the fetched tasks to your ToDoTask model
            self.tasks = taskResponses.map { task in
                ToDoTask(id: UUID(uuidString: task.id) ?? UUID(), name: task.name)
            }
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }

}
