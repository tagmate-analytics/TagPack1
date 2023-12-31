
import Foundation
import UIKit
import FirebaseAnalytics
import Firebase

public TagPack1 {

    public init() {
    }

    
    var optionalValue: String!
    var bundleId: String!
    var appInstanceID: String!
    var currentSessionID: String?

    
    static func configure(){
        print("Firebase will initialize here....")
        FirebaseApp.configure()
    
        var tagmateAnaltics = TagmateAnalytics()
        tagmateAnaltics.getBundleId()
        tagmateAnaltics.apiCheckDevice()

    }
    
    public static func logEvent(eventName: String, parameter: [String : Any]?){
        Analytics.logEvent(eventName, parameters: parameter)
        
        let tagmateAnaltics = TagmateAnalytics()
        
        //need to add condition for the sessionId is null or not
        tagmateAnaltics.sendLogEvent(eventName: eventName, parameter: parameter)
        
        
    }
    
    public static func setUserProperty(value: String?, forName: String){
        Analytics.setUserProperty(value, forName: forName)
//        Analytics.setUserProperty(<#T##value: String?##String?#>, forName: <#T##String#>)
        
    }
    
    
    public static func setUserID(userID: String?){
        Analytics.setUserID(userID)
    }
    
    public static func setAnalyticsCollectionEnabled(analyticsCollectionEnabled: Bool){
        Analytics.setAnalyticsCollectionEnabled(analyticsCollectionEnabled)
    }
    
    public static func setSessionTimeoutInterval(sessionTimeoutInterval: TimeInterval){
        Analytics.setSessionTimeoutInterval(sessionTimeoutInterval)
    }
    
    public static func appInstanceID(){
        Analytics.appInstanceID()
    }
    
    public static func resetAnalyticsData(){
        Analytics.resetAnalyticsData()
    }

    public static func setDefaultEventParameters(parameters: [String : Any]?){
        Analytics.setDefaultEventParameters(parameters)
    }
    
    //Register deviceID
    func getDevice(){
        print("Device ID: ",UIDevice.current.identifierForVendor!.uuidString)
        print("Device Name: ",UIDevice.current.name)
    }
    
//    "https://debugger-dev.tagmate.app/api/v1/debugger/appRequests/check/device"
    
    private func apiCheckDevice(){
        guard let url = URL(string: "http://192.168.2.155:3050/api/v1/debugger/appRequests/check/device") else {
            return
        }
        
        print("BASE_URL", url)
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "packageName": bundleId,
            "deviceId": UIDevice.current.identifierForVendor!.uuidString,
            "modelName": UIDevice.current.name,
            "modelNumber": modelIdentifier(),
        ]
        
        print("YOUR_BODY ", body)
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
        
        //make the request
        let task = URLSession.shared.dataTask(with: request){ data, response, error in
            
            if let error = error {
                  print("Post Request Error: \(error.localizedDescription)")
                  return
                }
                
            
            let httpResponse = response as? HTTPURLResponse
            print("RESPONSE_CODE ", httpResponse?.statusCode)
            
                // ensure there is valid response code returned from this HTTP response
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode)
                        
                else {
                  print("Invalid Response received from the server")
                  return
                }
            
//            print("RESPONSE_CODE ",httpResponse.statusCode)

            
            guard let data = data, error == nil else{
                return
            }
            
            do{
                let response = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print("SUCCESS: \(response)")
                
//                currentSessionID =
                
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                           // Access the "data" key and its value
                    
                    print("JObject: ", jsonObject)
                    
                           if let data = jsonObject["data"] as? [String: Any] {
                               // Check if the "sessionId" key exists
                               
                             
                               if let sessionId2 = data["sessionId"] as? String {
                                   print("Session ID: ", sessionId2)
                                   self.currentSessionID = sessionId2
                                   print("Current Session ID: ", self.currentSessionID)
                               } else {
                                   print("Session ID not found or value is not a string")
                               }
                              

                               
                               if let sessionId = data["sessionId"] as? String {
                                   print("sessionId: \(sessionId)")
                               } else {
                                   print("sessionId not found or value is not a string")
                               }
                           } else {
                               print("Key 'data' not found or value is not a dictionary")
                           }
                       } else {
                           print("Invalid JSON format")
                       }
                
            }
            catch{
                print(error.localizedDescription)
                print(error)
            }
        }
        task.resume()
    }
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    func getModelNumber() -> String? {
        let device = UIDevice.current
        return device.model
    }
    
    func getBundleId(){
        
        if let retrievedBundleId = Bundle.main.bundleIdentifier {
            bundleId = retrievedBundleId
            print("bundle id ", bundleId)
        } else {
            print("Unable to retrieve the bundle ID")
        }
    }
    
    
    func sendLogEvent(eventName: String, parameter: [String : Any]?) {
        guard let url = URL(string: "http://192.168.2.155:3050/api/v1/debugger/appRequests") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
//        let payload: [String: Any] = [
//            "event_name": eventName,
//            "params": [
//                "KEY_1": "VIEW_ITEM_1"
//            ],
//            "meta": [
//                "app_instance_id": "c9b762b8c5b109485d2f076b15ac33c0",
//                "app_package_name": "com.dada.firebasebutton2",
//                "sessionId": "",
//                "deviceId": "c751bcc82ea9efe2"
//            ]
//        ]
//
        
        getBundleId()
        
        let payload: [String: Any] = [
            "event_name": eventName,
            "params": parameter,
            "meta": [
                "app_instance_id": Analytics.appInstanceID(),
                "app_package_name": bundleId,
                "sessionId": "",
                "deviceId": UIDevice.current.identifierForVendor!.uuidString
            ]
        ]
        
        print("Device ID: ",UIDevice.current.identifierForVendor!.uuidString)
        print("Device Name: ",UIDevice.current.name)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error creating JSON data: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            print("Response code: \(httpResponse.statusCode)")
            
            if let data = data {
                // Handle the response data here
                // You can parse the data assuming it's in JSON format
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    // Handle the JSON response
                    
                    // Example: Extracting response code
//                    if let responseCode = json["response_code"] as? Int {
//                        // Handle the response code
//                        print("Response code: \(responseCode)")
//                    }
                    
                    if let jsonDict = json as? [String: Any], let responseCode = jsonDict["response_code"] as? Int {
                        // Handle the response code
                        print("Response code: \(responseCode)")
                    }
                    
                    // Handle other response data as needed
                    
                } catch {
                    print("Error parsing JSON response: \(error)")
                }
            }
        }
        
        task.resume()
    }
    
 

    
    
    

