//
//  ContentView.swift
//  Shared
//
//  Created by Jimmy Leu on 1/15/21.
//

import SwiftUI

// Model
enum PasswordStatus {
    case empty
    case notStrongEnough
    case repeatPasswordWrong
    case valid
}

import Combine
class FormViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var passwordAgain = ""
    
    @Published var inlineErrorForPassword = ""
    
    @Published var isValid = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private let predicate = NSPredicate(format: "SELF MATCHES %@", "(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{6,}")
    
    private var isUsernameVaildPublisher: AnyPublisher<Bool, Never>{
        $username
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map {$0.count >= 3 }
            .eraseToAnyPublisher()
            
            
    }
    
    private var isPaasswordEmptyPublisher: AnyPublisher<Bool, Never>{
        $password
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map {$0.isEmpty }
            .eraseToAnyPublisher()
            
            
    }
    
    private var isPasswordEqualPublisher: AnyPublisher<Bool, Never>{
        Publishers.CombineLatest($password,$passwordAgain)
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .map{ $0 == $1 }
            .eraseToAnyPublisher()
            
            
    }
    
    private var isPasswordStrongPublisher:AnyPublisher<Bool,Never>{
        $password
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map {
                self.predicate.evaluate(with: $0)
                
            }
            .eraseToAnyPublisher()
    }
    
    
    private var isPasswordValidPublisher:AnyPublisher<PasswordStatus, Never>{
        Publishers.CombineLatest3(isPasswordEqualPublisher,isPasswordStrongPublisher, isPasswordEqualPublisher)
            .map {
                if $0 {return PasswordStatus.empty}
                if !$1 {return PasswordStatus.notStrongEnough}
                if !$2 {return PasswordStatus.repeatPasswordWrong}
                
                return PasswordStatus.valid
            }
            .eraseToAnyPublisher()
    }
    
    private var isFormVaildPublisher:AnyPublisher<Bool, Never>{
        Publishers.CombineLatest(isPasswordValidPublisher, isUsernameVaildPublisher)
            .map {
                $0 == PasswordStatus.valid && $1
            }
            .eraseToAnyPublisher()
        
    }
    
    init() {
        isFormVaildPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValid, on: self)
            .store(in: &cancellables)
        
        isPasswordValidPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .map { passwordStatus in 
                switch passwordStatus{
                case .empty:
                    return "Password cannot be empty"
                case .notStrongEnough:
                    return "Password is too weak"
                case .repeatPasswordWrong:
                    return "Passwords do not match"
                case .valid:
                    return ""
                }
            }
            .assign(to: \.inlineErrorForPassword, on:self )
            .store(in: &cancellables)
        
    }
}

struct ContentView: View {
    @StateObject private var formViewModel = FormViewModel()
    
    var body: some View {
        NavigationView{
            VStack{
                Form{
                    Section(header: Text("USERNAME")) {
                        TextField("Username", text:$formViewModel.username)
                            .autocapitalization(.none)
                        
                    }
                    Section(header: Text("PASSWORD"), footer:Text(formViewModel.inlineErrorForPassword)
                                .foregroundColor(.red)) {
                        SecureField("Password", text:$formViewModel.password)
                        
                        TextField("Password again", text:$formViewModel.passwordAgain)
                            
                        
                    }
        
                }
                Button(action:{
                    
                }){
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height:60)
                        .overlay(
                            Text("Continue")
                            .foregroundColor(.white)
                        )
                }.padding().disabled(!formViewModel.isValid)
            }.navigationTitle("Sign Up")
        }
       
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
