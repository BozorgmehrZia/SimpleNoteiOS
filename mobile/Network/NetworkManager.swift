import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:8000/api" // Update this to match your backend URL
    private let session = URLSession.shared
    var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Generic Request Method
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = body
        }
        
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
            .decode(type: T.self, decoder: JSONDecoder())
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
    
    // MARK: - Notes API
    func getNotes(page: Int = 1) -> AnyPublisher<PaginatedResponse<Note>, NetworkError> {
        return request(
            endpoint: "/notes/?page=\(page)",
            method: .GET,
            headers: getAuthHeaders(),
            responseType: PaginatedResponse<Note>.self
        )
    }
    
    func getNote(id: Int) -> AnyPublisher<Note, NetworkError> {
        return request(
            endpoint: "/notes/\(id)/",
            method: .GET,
            headers: getAuthHeaders(),
            responseType: Note.self
        )
    }
    
    func createNote(_ note: CreateNoteRequest) -> AnyPublisher<Note, NetworkError> {
        guard let body = try? JSONEncoder().encode(note) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/notes/",
            method: .POST,
            body: body,
            headers: getAuthHeaders(),
            responseType: Note.self
        )
    }
    
    func updateNote(id: Int, _ note: UpdateNoteRequest) -> AnyPublisher<Note, NetworkError> {
        guard let body = try? JSONEncoder().encode(note) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/notes/\(id)/",
            method: .PUT,
            body: body,
            headers: getAuthHeaders(),
            responseType: Note.self
        )
    }
    
    func deleteNote(id: Int) -> AnyPublisher<MessageResponse, NetworkError> {
        guard let url = URL(string: baseURL + "/notes/\(id)/") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth headers
        let authHeaders = getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
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
                
                // Handle empty response (204 No Content) for successful deletion
                if data.isEmpty {
                    return MessageResponse(detail: "Note deleted successfully")
                }
                
                // Try to decode the response if it's not empty
                return try JSONDecoder().decode(MessageResponse.self, from: data)
            }
            .mapError { error in
                print("Delete Note Error: \(error)")
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
    
    func bulkCreateNotes(_ notes: [CreateNoteRequest]) -> AnyPublisher<[Note], NetworkError> {
        guard let body = try? JSONEncoder().encode(notes) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/notes/bulk",
            method: .POST,
            body: body,
            headers: getAuthHeaders(),
            responseType: [Note].self
        )
    }
    
    func filterNotes(title: String? = nil, page: Int = 1) -> AnyPublisher<PaginatedResponse<Note>, NetworkError> {
        var endpoint = "/notes/filter?page=\(page)"
        if let title = title, !title.isEmpty {
            endpoint += "&title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        return request(
            endpoint: endpoint,
            method: .GET,
            headers: getAuthHeaders(),
            responseType: PaginatedResponse<Note>.self
        )
    }
    
    func searchNotes(query: String, page: Int = 1) -> AnyPublisher<PaginatedResponse<Note>, NetworkError> {
        var endpoint = "/notes/search?page=\(page)"
        if !query.isEmpty {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            endpoint += "&q=\(encodedQuery)"
        }
        
        return request(
            endpoint: endpoint,
            method: .GET,
            headers: getAuthHeaders(),
            responseType: PaginatedResponse<Note>.self
        )
    }
    
    // MARK: - Helper Methods
    private func getAuthHeaders() -> [String: String] {
        guard let token = AuthManager.shared.accessToken else {
            return [:]
        }
        return ["Authorization": "Bearer \(token)"]
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}