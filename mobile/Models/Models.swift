import Foundation

// MARK: - User Models
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let firstName: String?
    let lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case firstName = "first_name"
        case lastName = "last_name"
    }
    
    var displayName: String {
        if let firstName = firstName, let lastName = lastName, !firstName.isEmpty, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        return username
    }
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
    let email: String
    let firstName: String?
    let lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case username, password, email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct TokenResponse: Codable {
    let access: String
    let refresh: String
}

struct RefreshTokenRequest: Codable {
    let refresh: String
}

struct ChangePasswordRequest: Codable {
    let oldPassword: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case oldPassword = "old_password"
        case newPassword = "new_password"
    }
}

struct MessageResponse: Codable {
    let detail: String
}

// MARK: - Note Models
struct Note: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let createdAt: String
    let updatedAt: String
    let creatorName: String?
    let creatorUsername: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creatorName = "creator_name"
        case creatorUsername = "creator_username"
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    var formattedUpdatedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: updatedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return updatedAt
    }
}

struct CreateNoteRequest: Codable {
    let title: String
    let description: String
}

struct UpdateNoteRequest: Codable {
    let title: String
    let description: String
}

// MARK: - API Response Models
struct PaginatedResponse<T: Codable>: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
    
    // Calculate total pages based on count and page size (6)
    var totalPages: Int {
        return Int(ceil(Double(count) / 6.0))
    }
}

// MARK: - Error Models
struct APIError: Codable, Error {
    let detail: String?
    let message: String?
    
    var localizedDescription: String {
        return detail ?? message ?? "An unknown error occurred"
    }
}

// MARK: - Network Error
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case serverError(Int, String)
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .serverError(let code, let message):
            return message.isEmpty ? "Server error with code: \(code)" : message
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}