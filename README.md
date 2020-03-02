# Api with enum management Demo

## Api Protocol
```
protocol ApiKey {
    var keys: [String] { get }
    var parametersForKeys: [Any?] { get }
    var httpMethod: HTTPMethod { get }
    var contentType: ContentType { get }
    var apiVersion: String { get }
}
```

## How to manage
```
enum CustomApiKey: ApiKey {
	case customApi(parameter1: Any, parameter2: Any)
    
    init(_ apiKey: ApiKeySearch) {
        self = apiKey
    }
    
    var keys: [String] {
        switch self {
        case .customApi: return ["key1","key2"]
            
        }
    }
    
    var parametersForKeys: [Any?] {
        switch self {
        case .customApi(let parameter1, let parameter2): return [parameter1, parameter2]
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .customApi: return .get
        }
    }
    
    var contentType: ContentType {
        switch self {
        case .customApi: return .query
        }
    }
    
    var apiVersion: String { return "v1" }
}
```

#### API URL
Url: Domain/v1/key1/parameter1/key2/parameter2



# How to use request

If using GET mehtod, parameter will be convert to query string
```
let apiKey = CustomApiKey(.customApi(parameter1: "1", parameter2: "2"))

var parameter: [String: Any] = [:]
parameter["para"] = "para"
```

Using decodable model
```
Request.shared.api(from: apiKey, parameter: parameter, model: DecodableModel.self).subscribe(onNext: { [weak self] (result) in
    guard let self = self else { return }
    switch result {
    case .success(let model): print(model)
    case .failure(let error): print(error)
    }
}).disposed(by: disposeBag)
```

Default model is NSDictionary
```
Request.shared.api(from: apiKey, parameter: parameter).subscribe(onNext: { [weak self] (result) in
    guard let self = self else { return }
    switch result {
    case .success(let model): print(model)
    case .failure(let error): print(error)
    }
}).disposed(by: disposeBag)
```

# Result

Result is also managed by enum

```
enum ResponseState<T> {
    case success(T)
    case failure(NetworkingError) //all error message
}
```

Success part return decodable model from generic input

Failure part return NetworkingError(also enum) Type

## Api response handler

```
func handleResponse<T: Decodable>(with responseContent: responseContent, model: T.Type, completionHandler: ResultCompletionHandler<T>?) -> ResponseState<T>
```

```
handleResponseDictionary(with responseContent: responseContent) -> ResponseState<NSDictionary>
```

Handler will decode and classify success or failure

## Decodable Model

CustomDecodable model must adopt Decodable protocol


#### Any type in Decodable

JsonValue is a type for any type in Decodable

```
public enum JSONValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON"))
        }
    }
    
    var stringValue: String? {
        switch self {
        case .string(let string): return string
        default: return nil
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let int): return int
        default: return nil
        }
    }
    
    var dictionValue: Dictionary<String, JSONValue>? {
        switch self {
        case .object(let object): return object
        default: return nil
        }
    }
    
    var values: AnyObject {
        switch self {
        case let .array(xs):
            return xs.map { $0.values } as AnyObject
        case let .object(xs):
            return xs.mapValues { $0.values } as AnyObject
        case let .double(n):
            return n as AnyObject
        case let .string(s):
            return s as AnyObject
        case let .bool(b):
            return b as AnyObject
        case let .int(i):
            return i as AnyObject
        }
    }
}
```

How to get value from JsonValue

```
JsonValue.stringValue
JsonValue.intValue
JsonValue.dictionValue
JsonValue.values
```

To convert any type when in use
