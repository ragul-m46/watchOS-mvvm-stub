//
//  NetworkManager.swift
//  Gallery Watch App
//
//  Created by Mac-OBS-18 on 25/01/23.
//

import Foundation

enum Gallery {
    static var appName = "Gallery"
    static let baseURL = URL(string: "https://api.sampleapis.com")!
}

// MARK: - ErrorStatusResponse
struct ErrorStatusResponse: Codable {
    
    let status: Int?
    let msg: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case msg
    }
}

struct ErrorResponse: Codable {
    let message: String?
    let status: ErrorStatusResponse?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
    }
}



extension String {
    static let formUrlencodedAllowedCharacters =  CharacterSet(charactersIn: "0123456789" + "abcdefghijklmnopqrstuvwxyz" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "-._* ")
    public func formUrlencoded() -> String {
        let encoded = addingPercentEncoding(withAllowedCharacters: String.formUrlencodedAllowedCharacters)
        return encoded?.replacingOccurrences(of: " ", with: "+") ?? ""
    }}



/// Authendication used to manage access token for webservice
///
/// - required: Access token will be added in header as Authendication
///
/// - never: Access token will not be added in header

public enum Authendication {
    case required
    case never
}

/// Network Request Error used to manage error status
///
/// - error: Error debug description will be shown here
///
/// - errorCode: Error code will be displayed (Ex: 200 - Success, 500 - Internal server)
///
/// - httpErrorCode: Http Status Error code will be displayed (Ex: 200 - Success, 500 - Internal server)
///
/// - description: Error description in detail will be shown

public struct NetworkRequestError: Error {
    var error: String?
    var errorCode: Int?
    var httpErrorCode: Int?
    var description: String!
}

/// Encode Type used to manage different mode of encode
///
/// - encodedURL: This mode used to encode with base URL
///
/// - encodedJSON: This mode used to encode the parameters in JSON format

public enum EncodeType {
    case encodedURL
    case encodedJSON
}

/// HTTP Utils used to form url to be encoded with separator

class HTTPUtils {
    public class func formUrlencode(_ values: Parameter) -> String {
        return values.map { key, value in
            return "\(key.formUrlencoded())=\(value.formUrlencoded())"
        }.joined(separator: "&")
    }
}

/// Network Manager is used to handle network session
///
/// - Discussion: This value will be appended to the `Content-Type` header field
///
/// - Important: This value will be appended if, and only if `contentType` is non-nil

class NetworkManager {

    public typealias CancellationHandler = () -> Void

    /// Method that execute an network request
    ///
    /// - Parameters:
    ///   - request: Network request object which contains path, mode and URLQueryItems
    ///   - responseType: Response model with valid value and key format
    /// - Returns: Result (Response model, Network request error)

    private static func setupURLPath(request: NetworkRequest) -> URL {

        /// Construct the base url to make request with path details
        ///
        /// - directURL: Both baseURL and path will be appended together with timestamp
        ///
        /// - formedURL: Both baseURL and path will be appended together to form request URL

        switch request.pathType {
        case .directURL:
            let fullPath = String(format: "%@%@", Gallery.baseURL as CVarArg, request.path)
            let fullPathSTR = fullPath.replacingOccurrences(of: "%20+0000", with: "")
            return URL(string: fullPathSTR)!

        default:
            return request.constructURL(baseURL: Gallery.baseURL, additionalURLQueryItems: [])

        }

    }

    private static func setupURLRequest(request: NetworkRequest) -> URLRequest {

        var networkRequest = URLRequest(url: setupURLPath(request: request))
        networkRequest.httpMethod = request.HTTPMethod.rawValue
        networkRequest.cachePolicy = .reloadIgnoringCacheData
        networkRequest.timeoutInterval = 60
        networkRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        /// Httpbody data will be added with parameterData and parameter
        ///
        /// - parameterData: It will be encoded and converted into Data.
        /// Due to that it will directly assigned to httpBody
        ///
        /// - parameter: Request parameter will be converted in below format
        ///     - encodedURL: This mode used to encode with base URL
        ///     - encodedJSON: This mode used to encode the parameters in JSON format
        ///

        if let paramData = request.parameterData {
            networkRequest.httpBody = paramData
        }

        if let params = request.parameter {

            switch request.mode {
            case .encodedURL:
                networkRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let body = HTTPUtils.formUrlencode(params)
                networkRequest.httpBody = Data(body.utf8)

            default:
                if let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []) {
                    networkRequest.httpBody = jsonData
                }

            }

        }

        /// Authorization Requirement will be used to make the request as secured
        ///
        /// - required: Access token will be added in header as Authendication
        ///
        /// - never: Access token will not be added in header
        ///

        if request.authorizationRequirement == .required {

            if let token = UserDefaults.standard.object(forKey: "token") as? String {
                let tokenStr = String(format: "bearer %@", token)
                print("token ==\(tokenStr)")
                networkRequest.setValue(tokenStr, forHTTPHeaderField: "Authorization")
            }

        }

        return networkRequest

    }

    static func execute<T: Decodable>(request: NetworkRequest,
                                      responseType: T.Type,
                                      completionHandler: @escaping (Result<T, NetworkRequestError>) -> Void) {

        /// Validate reachability for network connection

                if !Reachability.isConnectedToNetwork() {
                    let error = NetworkRequestError(error: "Invalid",
                                                    errorCode: 1,
                                                    httpErrorCode: 300,
                                                    description: "Please check your internet connection !!!")
                    DispatchQueue.main.async {
                        completionHandler(.failure(error))
                    }
                }

        /// URLRequest created with custom configuration

        let networkRequest = setupURLRequest(request: request)

        print("Request === \(networkRequest)")
        if networkRequest.url.debugDescription.contains("geteventremainder") {
            print("detect")
        }

        URLSession.shared.dataTask(with: networkRequest) { (data, response, error) in

            if let data = data, let httpStatus = response as? HTTPURLResponse {

                /// Http Status code will be used to manage the success and error status of the request
                /// - 200: Http status as success
                ///
                /// - 401: Invalid or expired Access token
                ///
                /// - 500: Internal server error
                ///
                /// - other: Unknown error
                ///

                switch httpStatus.statusCode {
                case 200:
                    do {
                        let dataObj = try JSONDecoder().decode(T.self, from: data)
                        DispatchQueue.main.async {
                            completionHandler(.success(dataObj))
                        }
                    } catch {

                        /// Unknown error response will be returned with response

                        let error = NetworkRequestError(error: "Invalid",
                                                        errorCode: 1,
                                                        httpErrorCode: 300,
                                                        description: "Unknown Error")
                        DispatchQueue.main.async {
                            completionHandler(.failure(error))
                        }
                    }

                case 401:
                    /// Access token expired error will be returned with 401 http status error code
                    let error = NetworkRequestError(error: "Invalid",
                                                    errorCode: 1,
                                                    httpErrorCode: 401,
                                                    description: "Access token expired !!!")
                    DispatchQueue.main.async {
                        completionHandler(.failure(error))
                        //UserManager.shared.logout()
                    }

                default:
                    do {
                        /// Unknown error will be returned with respective http status error code

                        let dataObj = try JSONDecoder().decode(ErrorResponse.self, from: data)

                        let error = NetworkRequestError(error: "Unknown Error",
                                                        errorCode: dataObj.status?.status ?? 201,
                                                        httpErrorCode: httpStatus.statusCode,
                                                        description: dataObj.status?.msg ?? "Unknown Error")
                        DispatchQueue.main.async {
                            completionHandler(.failure(error))
                        }
                    } catch {
                        let error = NetworkRequestError(error: "Invalid",
                                                        errorCode: 1,
                                                        httpErrorCode: httpStatus.statusCode,
                                                        description: "Unknown Error")
                        DispatchQueue.main.async {
                            completionHandler(.failure(error))
                        }
                    }

                }

            } else {

                let error = NetworkRequestError(error: "Invalid",
                                                errorCode: 1,
                                                httpErrorCode: 300,
                                                description: "Unknown Error")
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }

        }.resume()

    }
    
}


