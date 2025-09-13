import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let baseURL = "http://localhost:8000/api" // Update this to match your backend URL
    private let session = URLSession.shared
    var cancellables = Set<AnyCancellable>()
    
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessTokenKey) }
        set { 
            UserDefaults.standard.set(newValue, forKey: accessTokenKey)
            isAuthenticated = newValue != nil
        }
    }
    
    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshTokenKey) }
    }
    
    private init() {
        // Check if user is already authenticated
        if accessToken != nil {
            isAuthenticated = true
            loadUserInfo()
        }
    }
    
    // MARK: - Authentication Methods
    func login(username: String, password: String) -> AnyPublisher<TokenResponse, NetworkError> {
        let loginRequest = LoginRequest(username: username, password: password)
        
        guard let body = try? JSONEncoder().encode(loginRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: baseURL + "/auth/token/") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                    throw NetworkError.serverError(httpResponse.statusCode, "")
                }
                
                return data
            }
            .decode(type: TokenResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map { [weak self] tokenResponse in
                self?.accessToken = tokenResponse.access
                self?.refreshToken = tokenResponse.refresh
                self?.isAuthenticated = true
                self?.loadUserInfo()
                return tokenResponse
            }
            .mapError { error in
                print("Network Error: \(error)")
                if error is DecodingError {
                    return NetworkError.decodingError
                } else if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.networkUnavailable
                }
            }
            .eraseToAnyPublisher()
    }
    
    func register(_ registerRequest: RegisterRequest) -> AnyPublisher<User, NetworkError> {
        guard let body = try? JSONEncoder().encode(registerRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: baseURL + "/auth/register/") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                    throw NetworkError.serverError(httpResponse.statusCode, "")
                }
                
                return data
            }
            .decode(type: User.self, decoder: JSONDecoder())
            .mapError { error in
                print("Network Error: \(error)")
                if error is DecodingError {
                    return NetworkError.decodingError
                } else if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.networkUnavailable
                }
            }
            .eraseToAnyPublisher()
    }
    
    func refreshAccessToken() -> AnyPublisher<TokenResponse, NetworkError> {
        guard let refreshToken = refreshToken else {
            return Fail(error: NetworkError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        let refreshRequest = RefreshTokenRequest(refresh: refreshToken)
        
        guard let body = try? JSONEncoder().encode(refreshRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: baseURL + "/auth/token/refresh/") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TokenResponse.self, decoder: JSONDecoder())
            .map { [weak self] tokenResponse in
                self?.accessToken = tokenResponse.access
                self?.refreshToken = tokenResponse.refresh
                return tokenResponse
            }
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError
                } else {
                    return NetworkError.networkUnavailable
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getUserInfo() -> AnyPublisher<User, NetworkError> {
        guard let accessToken = accessToken else {
            return Fail(error: NetworkError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: baseURL + "/auth/userinfo/") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map { [weak self] user in
                self?.currentUser = user
                return user
            }
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError
                } else {
                    return NetworkError.networkUnavailable
                }
            }
            .eraseToAnyPublisher()
    }
    
    func changePassword(_ changePasswordRequest: ChangePasswordRequest) -> AnyPublisher<MessageResponse, NetworkError> {
        guard let accessToken = accessToken else {
            return Fail(error: NetworkError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        guard let body = try? JSONEncoder().encode(changePasswordRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: baseURL + "/auth/change-password/") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    // Success - decode as MessageResponse
                    return try JSONDecoder().decode(MessageResponse.self, from: data)
                case 400...499:
                    // Client error - try to extract error message from response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errors = errorData["errors"] as? [[String: Any]],
                       let firstError = errors.first,
                       let detail = firstError["detail"] as? String {
                        throw NetworkError.serverError(httpResponse.statusCode, detail)
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode, "Bad request")
                    }
                case 500...599:
                    throw NetworkError.serverError(httpResponse.statusCode, "Server error")
                default:
                    throw NetworkError.invalidResponse
                }
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.networkUnavailable
                }
            }
            .eraseToAnyPublisher()
    }
    
    func logout() {
        DispatchQueue.main.async { [weak self] in
            self?.accessToken = nil
            self?.refreshToken = nil
            self?.currentUser = nil
            self?.isAuthenticated = false
        }
    }
    
    // MARK: - Private Methods
    private func loadUserInfo() {
        getUserInfo()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}