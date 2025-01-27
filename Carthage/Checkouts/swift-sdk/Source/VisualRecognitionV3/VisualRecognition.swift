/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/
// swiftlint:disable file_length

import Foundation
import RestKit

/**
 The IBM Watson&trade; Visual Recognition service uses deep learning algorithms to identify scenes, objects, and faces
 in images you upload to the service. You can create and train a custom classifier to identify subjects that suit your
 needs.
 */
public class VisualRecognition {

    /// The base URL to use when contacting the service.
    public var serviceURL = "https://gateway.watsonplatform.net/visual-recognition/api"

    /// The default HTTP headers for all requests to the service.
    public var defaultHeaders = [String: String]()

    var session = URLSession(configuration: URLSessionConfiguration.default)
    var authMethod: AuthenticationMethod
    let version: String

    /**
     Create a `VisualRecognition` object.

     - parameter version: The release date of the version of the API to use. Specify the date
       in "YYYY-MM-DD" format.
     - parameter apiKey: An API key for IAM that can be used to obtain access tokens for the service.
     - parameter iamUrl: The URL for the IAM service.
     */
    public init(version: String, apiKey: String, iamUrl: String? = nil) {
        self.authMethod = Shared.getAuthMethod(apiKey: apiKey, iamURL: iamUrl)
        self.version = version
        Shared.configureRestRequest()
    }

    /**
     Create a `VisualRecognition` object.

     - parameter version: The release date of the version of the API to use. Specify the date
       in "YYYY-MM-DD" format.
     - parameter accessToken: An access token for the service.
     */
    public init(version: String, accessToken: String) {
        self.authMethod = IAMAccessToken(accessToken: accessToken)
        self.version = version
        Shared.configureRestRequest()
    }

    public func accessToken(_ newToken: String) {
        if self.authMethod is IAMAccessToken {
            self.authMethod = IAMAccessToken(accessToken: newToken)
        }
    }

    /**
     Use the HTTP response and data received by the Visual Recognition service to extract
     information about the error that occurred.

     - parameter data: Raw data returned by the service that may represent an error.
     - parameter response: the URL response returned by the service.
     */
    func errorResponseDecoder(data: Data, response: HTTPURLResponse) -> WatsonError {

        let statusCode = response.statusCode
        var errorMessage: String?
        var metadata = [String: Any]()

        do {
            let json = try JSONDecoder().decode([String: JSON].self, from: data)
            metadata = [:]
            switch statusCode {
            case 403:
                // ErrorAuthentication
                if case let .some(.string(status)) = json["status"],
                    case let .some(.string(statusInfo)) = json["statusInfo"] {
                    errorMessage = statusInfo
                    metadata["status"] = status
                    metadata["statusInfo"] = statusInfo
                }
            case 404:
                // "error": ErrorInfo
                if case let .some(.object(errorObj)) = json["error"],
                    case let .some(.string(message)) = errorObj["description"],
                    case let .some(.string(errorID)) = errorObj["error_id"] {
                    errorMessage = message
                    metadata["description"] = message
                    metadata["errorID"] = errorID
                }
            case 413:
                // ErrorHTML
                if case let .some(.string(message)) = json["Error"] {
                    errorMessage = message
                }
            default:
                // ErrorResponse
                if case let .some(.string(message)) = json["error"] {
                    errorMessage = message
                }
            }
            // If metadata is empty, it should show up as nil in the WatsonError
            return WatsonError.http(statusCode: statusCode, message: errorMessage, metadata: !metadata.isEmpty ? metadata : nil)
        } catch {
            return WatsonError.http(statusCode: statusCode, message: nil, metadata: nil)
        }
    }

    /**
     Classify images.

     Classify images with built-in or custom classifiers.

     - parameter imagesFile: An image file (.jpg, .png) or .zip file with images. Maximum image size is 10 MB. Include
       no more than 20 images and limit the .zip file to 100 MB. Encode the image and .zip file names in UTF-8 if they
       contain non-ASCII characters. The service assumes UTF-8 encoding if it encounters non-ASCII characters.
       You can also include an image with the **url** parameter.
     - parameter acceptLanguage: The language of the output class names. The full set of languages is supported for
       the built-in classifier IDs: `default`, `food`, and `explicit`. The class names of custom classifiers are not
       translated.
       The response might not be in the specified language when the requested language is not supported or when there is
       no translation for the class name.
     - parameter url: The URL of an image to analyze. Must be in .jpg, or .png format. The minimum recommended pixel
       density is 32X32 pixels per inch, and the maximum image size is 10 MB.
       You can also include images with the **images_file** parameter.
     - parameter threshold: The minimum score a class must have to be displayed in the response. Set the threshold to
       `0.0` to ignore the classification score and return all values.
     - parameter owners: The categories of classifiers to apply. Use `IBM` to classify against the `default` general
       classifier, and use `me` to classify against your custom classifiers. To analyze the image against both
       classifier categories, set the value to both `IBM` and `me`.
       The built-in `default` classifier is used if both **classifier_ids** and **owners** parameters are empty.
       The **classifier_ids** parameter overrides **owners**, so make sure that **classifier_ids** is empty.
     - parameter classifierIDs: Which classifiers to apply. Overrides the **owners** parameter. You can specify both
       custom and built-in classifier IDs. The built-in `default` classifier is used if both **classifier_ids** and
       **owners** parameters are empty.
       The following built-in classifier IDs require no training:
       - `default`: Returns classes from thousands of general tags.
       - `food`: Enhances specificity and accuracy for images of food items.
       - `explicit`: Evaluates whether the image might be pornographic.
     - parameter imagesFileContentType: The content type of imagesFile.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func classify(
        imagesFile: URL? = nil,
        acceptLanguage: String? = nil,
        url: String? = nil,
        threshold: Double? = nil,
        owners: [String]? = nil,
        classifierIDs: [String]? = nil,
        imagesFileContentType: String? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<ClassifiedImages>?, WatsonError?) -> Void)
    {
        // construct body
        let multipartFormData = MultipartFormData()
        if let imagesFile = imagesFile {
            do {
                try multipartFormData.append(file: imagesFile, withName: "images_file")
            } catch {
                completionHandler(nil, WatsonError.serialization(values: "file \(imagesFile.path)"))
                return
            }
        }
        if let url = url {
            if let urlData = url.data(using: .utf8) {
                multipartFormData.append(urlData, withName: "url")
            }
        }
        if let threshold = threshold {
            if let thresholdData = "\(threshold)".data(using: .utf8) {
                multipartFormData.append(thresholdData, withName: "threshold")
            }
        }
        if let owners = owners {
            if let ownersData = owners.joined(separator: ",").data(using: .utf8) {
                multipartFormData.append(ownersData, withName: "owners")
            }
        }
        if let classifierIDs = classifierIDs {
            if let classifierIDsData = classifierIDs.joined(separator: ",").data(using: .utf8) {
                multipartFormData.append(classifierIDsData, withName: "classifier_ids")
            }
        }
        guard let body = try? multipartFormData.toData() else {
            completionHandler(nil, WatsonError.serialization(values: "request multipart form data"))
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = multipartFormData.contentType
        if let acceptLanguage = acceptLanguage {
            headerParameters["Accept-Language"] = acceptLanguage
        }

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + "/v3/classify",
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Detect faces in images.

     **Important:** On April 2, 2018, the identity information in the response to calls to the Face model was removed.
     The identity information refers to the `name` of the person, `score`, and `type_hierarchy` knowledge graph. For
     details about the enhanced Face model, see the [Release
     notes](https://cloud.ibm.com/docs/services/visual-recognition/release-notes.html#2april2018).
     Analyze and get data about faces in images. Responses can include estimated age and gender. This feature uses a
     built-in model, so no training is necessary. The Detect faces method does not support general biometric facial
     recognition.
     Supported image formats include .gif, .jpg, .png, and .tif. The maximum image size is 10 MB. The minimum
     recommended pixel density is 32X32 pixels per inch.

     - parameter imagesFile: An image file (gif, .jpg, .png, .tif.) or .zip file with images. Limit the .zip file to
       100 MB. You can include a maximum of 15 images in a request.
       Encode the image and .zip file names in UTF-8 if they contain non-ASCII characters. The service assumes UTF-8
       encoding if it encounters non-ASCII characters.
       You can also include an image with the **url** parameter.
     - parameter url: The URL of an image to analyze. Must be in .gif, .jpg, .png, or .tif format. The minimum
       recommended pixel density is 32X32 pixels per inch, and the maximum image size is 10 MB. Redirects are followed,
       so you can use a shortened URL.
       You can also include images with the **images_file** parameter.
     - parameter imagesFileContentType: The content type of imagesFile.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func detectFaces(
        imagesFile: URL? = nil,
        url: String? = nil,
        imagesFileContentType: String? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<DetectedFaces>?, WatsonError?) -> Void)
    {
        // construct body
        let multipartFormData = MultipartFormData()
        if let imagesFile = imagesFile {
            do {
                try multipartFormData.append(file: imagesFile, withName: "images_file")
            } catch {
                completionHandler(nil, WatsonError.serialization(values: "file \(imagesFile.path)"))
                return
            }
        }
        if let url = url {
            if let urlData = url.data(using: .utf8) {
                multipartFormData.append(urlData, withName: "url")
            }
        }
        guard let body = try? multipartFormData.toData() else {
            completionHandler(nil, WatsonError.serialization(values: "request multipart form data"))
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = multipartFormData.contentType

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + "/v3/detect_faces",
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Create a classifier.

     Train a new multi-faceted classifier on the uploaded image data. Create your custom classifier with positive or
     negative examples. Include at least two sets of examples, either two positive example files or one positive and one
     negative file. You can upload a maximum of 256 MB per call.
     Encode all names in UTF-8 if they contain non-ASCII characters (.zip and image file names, and classifier and class
     names). The service assumes UTF-8 encoding if it encounters non-ASCII characters.

     - parameter name: The name of the new classifier. Encode special characters in UTF-8.
     - parameter positiveExamples: A dictionary that contains the value for each classname. The value are a .zip file
       of images that depict the visual subject of a class in the new classifier. You can include more than one positive
       example file in a call.
       Specify the parameter name by appending `_positive_examples` to the class name. For example,
       `goldenretriever_positive_examples` creates the class **goldenretriever**.
       Include at least 10 images in .jpg or .png format. The minimum recommended image resolution is 32X32 pixels. The
       maximum number of images is 10,000 images or 100 MB per .zip file.
       Encode special characters in the file name in UTF-8.
     - parameter negativeExamples: A .zip file of images that do not depict the visual subject of any of the classes
       of the new classifier. Must contain a minimum of 10 images.
       Encode special characters in the file name in UTF-8.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createClassifier(
        name: String,
        positiveExamples: [String: URL],
        negativeExamples: URL? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Classifier>?, WatsonError?) -> Void)
    {
        // construct body
        let multipartFormData = MultipartFormData()
        if let nameData = name.data(using: .utf8) {
            multipartFormData.append(nameData, withName: "name")
        }
        positiveExamples.forEach { (classname, value) in
            let partName = "\(classname)_positive_examples"
            do {
                try multipartFormData.append(file: value, withName: partName)
            } catch {
                completionHandler(nil, WatsonError.serialization(values: "file \(value)"))
                return
            }
        }
        if let negativeExamples = negativeExamples {
            do {
                try multipartFormData.append(file: negativeExamples, withName: "negative_examples")
            } catch {
                completionHandler(nil, WatsonError.serialization(values: "file \(negativeExamples.path)"))
                return
            }
        }
        guard let body = try? multipartFormData.toData() else {
            completionHandler(nil, WatsonError.serialization(values: "request multipart form data"))
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = multipartFormData.contentType

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + "/v3/classifiers",
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Retrieve a list of classifiers.

     - parameter verbose: Specify `true` to return details about the classifiers. Omit this parameter to return a
       brief list of classifiers.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listClassifiers(
        verbose: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Classifiers>?, WatsonError?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let verbose = verbose {
            let queryParameter = URLQueryItem(name: "verbose", value: "\(verbose)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + "/v3/classifiers",
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Retrieve classifier details.

     Retrieve information about a custom classifier.

     - parameter classifierID: The ID of the classifier.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getClassifier(
        classifierID: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Classifier>?, WatsonError?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v3/classifiers/\(classifierID)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, WatsonError.urlEncoding(path: path))
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update a classifier.

     Update a custom classifier by adding new positive or negative classes (examples) or by adding new images to
     existing classes. You must supply at least one set of positive or negative examples. For details, see [Updating
     custom
     classifiers](https://cloud.ibm.com/docs/services/visual-recognition/customizing.html#updating-custom-classifiers).
     Encode all names in UTF-8 if they contain non-ASCII characters (.zip and image file names, and classifier and class
     names). The service assumes UTF-8 encoding if it encounters non-ASCII characters.
     **Tip:** Don't make retraining calls on a classifier until the status is ready. When you submit retraining requests
     in parallel, the last request overwrites the previous requests. The retrained property shows the last time the
     classifier retraining finished.

     - parameter classifierID: The ID of the classifier.
     - parameter positiveExamples: A dictionary that contains the value for each classname. The value are a .zip file
       of images that depict the visual subject of a class in the classifier. The positive examples create or update
       classes in the classifier. You can include more than one positive example file in a call.
       Specify the parameter name by appending `_positive_examples` to the class name. For example,
       `goldenretriever_positive_examples` creates the class `goldenretriever`.
       Include at least 10 images in .jpg or .png format. The minimum recommended image resolution is 32X32 pixels. The
       maximum number of images is 10,000 images or 100 MB per .zip file.
       Encode special characters in the file name in UTF-8.
     - parameter negativeExamples: A .zip file of images that do not depict the visual subject of any of the classes
       of the new classifier. Must contain a minimum of 10 images.
       Encode special characters in the file name in UTF-8.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateClassifier(
        classifierID: String,
        positiveExamples: [String: URL]? = nil,
        negativeExamples: URL? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Classifier>?, WatsonError?) -> Void)
    {
        // construct body
        let multipartFormData = MultipartFormData()
        if let positiveExamples = positiveExamples {
            positiveExamples.forEach { (classname, value) in
                let partName = "\(classname)_positive_examples"
                do {
                    try multipartFormData.append(file: value, withName: partName)
                } catch {
                    completionHandler(nil, WatsonError.serialization(values: "file \(value)"))
                    return
                }
            }
        }
        if let negativeExamples = negativeExamples {
            do {
                try multipartFormData.append(file: negativeExamples, withName: "negative_examples")
            } catch {
                completionHandler(nil, WatsonError.serialization(values: "file \(negativeExamples.path)"))
                return
            }
        }
        guard let body = try? multipartFormData.toData() else {
            completionHandler(nil, WatsonError.serialization(values: "request multipart form data"))
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = multipartFormData.contentType

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v3/classifiers/\(classifierID)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, WatsonError.urlEncoding(path: path))
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete a classifier.

     - parameter classifierID: The ID of the classifier.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteClassifier(
        classifierID: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, WatsonError?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v3/classifiers/\(classifierID)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, WatsonError.urlEncoding(path: path))
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     Retrieve a Core ML model of a classifier.

     Download a Core ML model file (.mlmodel) of a custom classifier that returns <tt>\"core_ml_enabled\": true</tt> in
     the classifier details.

     - parameter classifierID: The ID of the classifier.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getCoreMLModel(
        classifierID: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Data>?, WatsonError?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/octet-stream"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v3/classifiers/\(classifierID)/core_ml_model"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, WatsonError.urlEncoding(path: path))
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     Delete labeled data.

     Deletes all data associated with a specified customer ID. The method has no effect if no data is associated with
     the customer ID.
     You associate a customer ID with data by passing the `X-Watson-Metadata` header with a request that passes data.
     For more information about personal data and customer IDs, see [Information
     security](https://cloud.ibm.com/docs/services/visual-recognition/information-security.html).

     - parameter customerID: The customer ID for which all data is to be deleted.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteUserData(
        customerID: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, WatsonError?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        queryParameters.append(URLQueryItem(name: "customer_id", value: customerID))

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + "/v3/user_data",
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

}
