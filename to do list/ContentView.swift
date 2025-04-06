//
//  ContentView.swift
//  to do list
//
//  Created by Gareth Hill on 4/5/25.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var tasks: [ToDoTask] = []
    @State private var newTaskName: String = ""
    @State private var username: String = ""  // For username input
    @State private var currentUser: User? = nil
    @State private var isLoggedIn: Bool = false
    
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
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Log In / Sign Up") {
                            loginOrSignUp()
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
            // Check if there's a logged-in user already
            if let user = try? await supabase.auth.user() {
                self.currentUser = user
                self.isLoggedIn = true
                await fetchTasks()
            } else {
                self.currentUser = nil
                self.isLoggedIn = false
            }
        }
    }
    
    func loginOrSignUp() {
        Task {
            // Here you will just sign in or create the user using the username (no password needed)
            if username.isEmpty {
                print("Username cannot be empty")
                return
            }
            
            do {
                // Try signing in or creating a user based on the username
                let response = try await supabase.auth.signIn(email: username, password: "password") // Use "password" since you're not using it
                self.currentUser = response.user
                self.isLoggedIn = true
                await fetchTasks()
            } catch {
                // If the user doesn't exist, sign them up
                do {
                    let response = try await supabase.auth.signUp(email: username, password: "password") // Again, using "password"
                    self.currentUser = response.user
                    self.isLoggedIn = true
                    await fetchTasks()
                } catch {
                    print("Error logging in or signing up: \(error)")
                }
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
            await addTaskAsync()
        }
    }
    
    func addTaskAsync() async {
        guard let userIdString = currentUser?.id else { return }
        let userId = userIdString.uuidString
        
        let task = ToDoTask(id: UUID(), name: newTaskName)
        
        do {
            _ = try await supabase.from("tasks").insert([
                ["name": task.name, "user_id": userId]
            ]).execute()
            
            tasks.append(task)
            newTaskName = ""
        } catch {
            print("Error adding task: \(error)")
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let task = tasks[index]
                
                do {
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
            let response = try await supabase.from("tasks")
                .select()
                .eq("user_id", value: userId)
                .execute()

            let taskResponses = try JSONDecoder().decode([TaskResponse].self, from: response.data)
            self.tasks = taskResponses.map { task in
                ToDoTask(id: UUID(uuidString: task.id) ?? UUID(), name: task.name)
            }
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
}
