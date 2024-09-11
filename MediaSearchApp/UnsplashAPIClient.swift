import Foundation

// MARK: - Search Result Model
struct SearchResult: Codable {
    let results: [Photo]
}

// MARK: - Photo Model
struct Photo: Codable {
    let id: String
    let description: String?
    let urls: PhotoURLs
    let user: User
    
    var author: String {
        return user.name
    }
}

// MARK: - Photo URLs Model
struct PhotoURLs: Codable {
    let small: String
    let regular: String
}

// MARK: - User Model
struct User: Codable {
    let name: String
}

// MARK: - UnsplashAPIClient

struct UnsplashAPIClient {
    private let accessKey = "m9Rt6aY2G_jMImnpVYbbMD_kJBInYQ3F4LIikHdygqU"
    private let limit = 30

    // MARK: - Search Photos Method
    func searchPhotos(query: String, page: Int = 1, sort: String = "relevant", width: Int = 400, height: Int = 300, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let urlString = "https://api.unsplash.com/search/photos?query=\(query)&order_by=\(sort)&per_page=\(limit)&client_id=\(accessKey)&w=\(width)&h=\(height)"
        
        guard let url = URL(string: urlString) else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                return
            }

            do {
                let result = try JSONDecoder().decode(SearchResult.self, from: data)
                completion(.success(result.results))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
