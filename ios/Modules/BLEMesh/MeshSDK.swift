//
//  MeshSDK.swift
//  nRFSingleTon
//
//  Created by wuzhengbin on 2019/12/19.
//  Copyright © 2019 wuzhengbin. All rights reserved.
//

import Foundation
import os.log
import nRFMeshProvision
import CoreBluetooth

@objc class MeshSDK: NSObject {
    static let sharedInstance = MeshSDK()
    
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection!
    var centralManager: CBCentralManager!
    var currentNetworkKey: String!
    var currentApplicationKey: String!
    
    typealias CheckPermissionCallback = (String) -> ()
    var checkPermissionCallBack: CheckPermissionCallback!
  
    @objc class func getSharedInstance() -> MeshSDK {
      return self.sharedInstance
    }
    
    @objc public func setup() {
        meshNetworkManager = MeshNetworkManager()
        meshNetworkManager.acknowledgmentTimerInterval = 0.600
        meshNetworkManager.transmissionTimerInteral = 0.600
        meshNetworkManager.retransmissionLimit = 2
        meshNetworkManager.acknowledgmentMessageInterval = 5.0
        // As the interval has been increased, the timeout can be adjusted.
        // The acknowledged message will be repeated after 5 seconds,
        // 15 seconds (5 + 5 * 2), and 35 seconds (5 + 5 * 2 + 5 * 4).
        meshNetworkManager.acknowledgmentMessageTimeout = 40.0
        meshNetworkManager.logger = self
        
        // Try loading the saved configuration
        var loaded = false
        do {
            loaded = try meshNetworkManager.load()
        } catch {
            print(error)
        }
        
        if !loaded {
            createNewMeshNetwork()
        } else {
            meshNetworkDidChange()
        }
        
        // 初始化 CentralManager
        centralManager = CBCentralManager()
    }
    
    private func createNewMeshNetwork() {
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        _ = meshNetworkManager.createNewMeshNetwork(withName: "nRF Mesh Network", by: provisioner)
        _ = meshNetworkManager.save()
        
        meshNetworkDidChange()
    }
    
    private func meshNetworkDidChange() {
        connection?.close()
        
        let meshNetwork = meshNetworkManager.meshNetwork!
        
        // Set up local Elements on the phone.
        let element0 = Element(name: "Primary Element", location: .first, models: [
            Model(sigModelId: 0x1000, delegate: GenericOnOffServerDelegate()),
            Model(sigModelId: 0x1002, delegate: GenericLevelServerDelegate()),
            Model(sigModelId: 0x1001, delegate: GenericOnOffClientDelegate()),
            Model(sigModelId: 0x1003, delegate: GenericLevelClientDelegate())
        ])
        let element1 = Element(name: "Secondary Element", location: .second, models: [
            Model(sigModelId: 0x1000, delegate: GenericOnOffServerDelegate()),
            Model(sigModelId: 0x1002, delegate: GenericLevelServerDelegate()),
            Model(sigModelId: 0x1001, delegate: GenericOnOffClientDelegate()),
            Model(sigModelId: 0x1003, delegate: GenericLevelClientDelegate())
        ])
        meshNetworkManager.localElements = [element0, element1]
        
        connection = NetworkConnection(to: meshNetwork)
        connection!.dataDelegate = meshNetworkManager
        connection!.logger = self
        meshNetworkManager.transmitter = connection
        connection!.open()
    }
    

}

// MARK: - Network Key Components
extension MeshSDK {
    @objc public func getAllNetworkKeys() -> [String] {
        let networkKeys = meshNetworkManager.meshNetwork!.networkKeys
        var stringKeys:[String] = []
        for nw in networkKeys {
            stringKeys.append(nw.key.hex)
        }
        return stringKeys
    }
    
    @objc public func createNetworkKey(key: String) {
        guard let data = Data(hex: key) else { return }
        let network = meshNetworkManager.meshNetwork!
        let index = network.networkKeys.count

        _ = try! network.add(networkKey: data, name: "NetworkKey \(index)")
        if meshNetworkManager.save() {
            
        } else {
            
        }
    }
    
    @objc public func deleteNetworkKey(key: String) {
        let networkKeys = meshNetworkManager.meshNetwork!.networkKeys
        let network = meshNetworkManager.meshNetwork!
        var deleteKey: NetworkKey
        for nw in networkKeys {
            if nw.key.hex == key {
                deleteKey = nw
                _ = try! network.remove(networkKey: deleteKey)
                if meshNetworkManager.save() {
                    
                } else {
                    
                }
            }
        }
    }
    
    @objc public func setCurrentNetworkKey(key: String) {
        for nk in meshNetworkManager.meshNetwork!.networkKeys {
            if nk.key.hex == key {
                currentNetworkKey = nk.key.hex
            }
            UserDefaults.standard.set(key, forKey: "mesh_currentNetworkKey")
            UserDefaults.standard.synchronize()
        }
    }
    
    @objc public func getCurrentNetworkKey() -> String {
        return UserDefaults.standard.string(forKey: "mesh_currentNetworkKey") ?? ""
    }
}

// MARK: - Application Key
extension MeshSDK {
    @objc public func setCurrentApplicationKey(key: String, networkKey: String) {
        for nk in meshNetworkManager.meshNetwork!.networkKeys {
            if nk.key.hex == key {
                
            }
        }
    }
    
    @objc public func getCurrentApplicationKey() -> String {
        return UserDefaults.standard.string(forKey: "mesh_currentApplicationKey") ?? ""
    }
    
    @objc public func createApplicationKey(networkKey: String) {
        let applicationKeyData = Data.random128BitKey()
        let networkKeys = meshNetworkManager.meshNetwork!.networkKeys
        let network = meshNetworkManager.meshNetwork!
        
        let applicationKeyCount = network.applicationKeys.count
        let applicationKey = try! network.add(applicationKey: applicationKeyData, name: String("App Key \(applicationKeyCount+1)"))
        var boundToNetworkKey: NetworkKey
        for nw in networkKeys {
            if nw.key.hex == networkKey {
                boundToNetworkKey = nw
                try? applicationKey.bind(to: boundToNetworkKey)
            }
        }
    }
    
    @objc public func getAllApplicationKey(networkKey: String) -> [String] {
        let applicationKeys = meshNetworkManager.meshNetwork?.applicationKeys
        let networkKeys = meshNetworkManager.meshNetwork?.networkKeys
        guard let boundedNetworkKey = networkKeys?.first(where: { (item) -> Bool in
            return item.key.hex == networkKey
        }) else { return [] }
        let applicationKeysInNetwork = (applicationKeys?.filter({ (item) -> Bool in
            return item.isBound(to: boundedNetworkKey)
        }))!
        var keys:[String] = []
        for applicationKey in applicationKeysInNetwork {
            keys.append(applicationKey.key.hex)
        }
        return keys
    }
    
    @objc public func removeApplicationKey(appKey: String, networkKey: String) {
        let network = meshNetworkManager.meshNetwork!
        var toDeleteAppKey: ApplicationKey
        for ak in network.applicationKeys {
            if ak.key.hex == appKey {
                toDeleteAppKey = ak
                // 进行删除操作
                if toDeleteAppKey.isUsed(in: network) {
                    return
                } else {
                    try? network.remove(applicationKey: toDeleteAppKey)
                    if !meshNetworkManager.save() {
                        // 删除失败
                    }
                }
            }
        }
    }
}

extension MeshSDK: CBCentralManagerDelegate {
    
    @objc public func checkPermission(callback : @escaping CheckPermissionCallback) {
        callback(centralManager.state == CBManagerState.poweredOn ? "GRANTED" : "DENIED")
        // checkPermissionCallBack = callback
        // centralManager.delegate = self
    }
    
    @objc public func startScanning() {
        print("Start Scanning")
    }
    
    @objc public func stopScanning() {
        print("Stop Scanning")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            if let _ = checkPermissionCallBack {
                checkPermissionCallBack("DENIED")
            }
        } else {
            if let _ = checkPermissionCallBack {
                checkPermissionCallBack("GRANTED")
            }

            startScanning()
        }
    }
}

//extension MeshNetworkManager {
//    
//    static var instance: MeshNetworkManager! {
//        return MeshSDK().meshNetworkManager
//    }
//    
//    static var bearer: NetworkConnection! {
//        return MeshSDK().connection
//    }
//}

extension MeshSDK: LoggerDelegate {
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: category.log, type: level.type, message)
        } else {
            NSLog("%@", message)
        }
    }
}

extension LogLevel {
    
    /// Mapping from mesh log levels to system log types.
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
    
}

extension LogCategory {
    
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
    
}
