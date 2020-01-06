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

enum DeviceConfigurationPhase {
    case provisoning
    case identifying
    case none
}

@objc class MeshSDK: NSObject {
    static let sharedInstance = MeshSDK()
    
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection!
    var centralManager: CBCentralManager!
    var currentNetworkKey: String!
    var currentApplicationKey: String!
    
    var phase: DeviceConfigurationPhase!
    
    var discoveredPeripherals = [(device: UnprovisionedDevice, peripheral: CBPeripheral, rssi: Int)]()
    var disposedDiscoveredDevices = [(identifier: String, rssi: Int, name: String)]()
    var provisioningManager: ProvisioningManager!
    var capabilitiesReceived = false
    var unprovisionedDevice: UnprovisionedDevice!
    var bearer: ProvisioningBearer!
    var currentNode: Node!
    
    private var provisioningNetworkKey: String!
    private var publicKey: PublicKey?
    private var authenticationMethod: AuthenticationMethod?
    
    typealias CheckPermissionCallback = (String, Bool) -> ()
    typealias ScanResultCallback = ([(device: UnprovisionedDevice, peripheral: CBPeripheral, rssi: Int)]) -> ()
    
    typealias DisposedScanResultCallback = ([(identifier: String, rssi: Int, name: String)]) -> ()
    typealias LocalProvisionedResultCallback = ([Node]) -> () // 暂定
    typealias GenericOnOffStatusCallback = (Bool) -> ()
    
    
    var checkPermissionCallBack: CheckPermissionCallback!
    var scanResultCallback: ScanResultCallback!
    var disposedScanResultCallback: DisposedScanResultCallback!
    var localProvisionedResultCallback: LocalProvisionedResultCallback!
    var genericOnOffStatusCallback: GenericOnOffStatusCallback!
    
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
            print("添加 key 成功")
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
            if nk.key.hex == networkKey {
                UserDefaults.standard.set(key, forKey: "mesh_currentAppKey")
                UserDefaults.standard.synchronize()
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
        if meshNetworkManager.save() {
            print("这回总该有 application key 了吧")
        } else {
            
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

// MARK: - Load Local Provisioned Node
extension MeshSDK {
    public func getProvisionedNodes(callback: @escaping LocalProvisionedResultCallback) {
        self.localProvisionedResultCallback = callback
        let network = meshNetworkManager.meshNetwork!
        let unConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
        self.localProvisionedResultCallback(unConfiguredNodes)
    }
    
    public func getCompositionData(node: Node) {
        let message = ConfigCompositionDataGet()
        meshNetworkManager.delegate = self
        currentNode = node
        _ = try? meshNetworkManager.send(message, to: currentNode)
        
    }
    
    public func getTtl(node: Node) {
        let message = ConfigDefaultTtlGet()
        
        _ = try? meshNetworkManager.send(message, to: node)
    }
}

// MARK: - 对设备发送控制指令
extension MeshSDK {    
    @objc public func setGenericOnOff(uuid: String, isOn: Bool, callback: @escaping GenericOnOffStatusCallback) {
        meshNetworkManager.delegate = self
        genericOnOffStatusCallback = callback
        let message = GenericOnOffSet(isOn)
        let network = meshNetworkManager.meshNetwork!
        guard let node = network.nodes.first(where: { $0.uuid.uuidString == uuid } ) else {
            return
        }
        currentNode = node
        let model: Model = node.elements[0].models.first(where: { $0.name == "Generic OnOff Server"} )!
        _ = try? meshNetworkManager.send(message, to: model)
    }
}

// MARK: - 添加 ApplicaitonKey
extension MeshSDK {
    public func bindApplicationKeyForNode(appKey: String, node: Node) {
        let network = meshNetworkManager.meshNetwork!
        meshNetworkManager.delegate = self
        if let applicationKey: ApplicationKey = network.applicationKeys.first(where: { $0.key.hex == appKey }) {
            _ = try? meshNetworkManager.send(ConfigAppKeyAdd(applicationKey: applicationKey), to: node)
        }
    }
    
    public func bindApplicationKeyForBaseModel(appKey: String, node: Node) {
        let network = meshNetworkManager.meshNetwork!
        let element = node.elements.first
        let models = element?.models
        let model = models![2]
        meshNetworkManager.delegate = self
        if let applicationKey: ApplicationKey = network.applicationKeys.first(where: { $0.key.hex == appKey }) {
            let message = ConfigModelAppBind(applicationKey: applicationKey, to: model)!
            _ = try? meshNetworkManager.send(message, to: model)
        }
        
       
    }
}

extension MeshSDK: MeshNetworkDelegate {
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address) {
        guard currentNode.unicastAddress == source else {
            return
        }
        
        switch message {
        case is GenericOnOffStatus:
            if let callback = genericOnOffStatusCallback {
                callback(true)
                genericOnOffStatusCallback = nil
            }
        case is ConfigCompositionDataStatus:
            print("配置组成数据状态")
            self.getTtl(node: currentNode)
        case is ConfigDefaultTtlStatus:
            print("配置默认TTL状态")
        case is ConfigNodeResetStatus:
            print("配置重置节点状态")
        case is ConfigAppKeyStatus:
            print("配置 ApplicationKey 状态")
        case is ConfigModelAppStatus:
            print("Model 配置 ApplicationKey 的状态")
        default:
            print("我也不知道这是什么")
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
    }
}

// MARK: - Provision
extension MeshSDK: ProvisioningDelegate {
    public func provision(identifier: String) {
        let indexOfDevice = self.disposedDiscoveredDevices.firstIndex { $0.identifier == identifier }!
        unprovisionedDevice = discoveredPeripherals[indexOfDevice].device
        bearer = PBGattBearer(target: discoveredPeripherals[indexOfDevice].peripheral)
        
        bearer.delegate = self
        bearer.open()
        phase = .identifying

    }
    
    public func provision(identifier: String, networkKey: String) {
        let indexOfDevice = self.disposedDiscoveredDevices.firstIndex { $0.identifier == identifier }!
        unprovisionedDevice = discoveredPeripherals[indexOfDevice].device
        bearer = PBGattBearer(target: discoveredPeripherals[indexOfDevice].peripheral)
        
        bearer.delegate = self
        bearer.open()
        phase = .identifying
        provisioningNetworkKey = networkKey
    }
    
    private func setupProvisionManager(unprovisionDevice: UnprovisionedDevice, bearer: ProvisioningBearer) {
        let network = meshNetworkManager.meshNetwork!
        self.bearer = bearer
        self.bearer.delegate = self
        provisioningManager = network.provision(unprovisionedDevice: unprovisionDevice, over: self.bearer)
        provisioningManager.delegate = self
        
        do {
            try self.provisioningManager.identify(andAttractFor: 5)
        } catch {
            self.abort(bearer: bearer)
        }
    }
    
    func abort(bearer: ProvisioningBearer) {
        bearer.close()
    }
    
    public func authenticationActionRequired(_ action: AuthAction) {
        
    }
    
    public func inputComplete() {
        print("inputComplete\nProvisioning...")
    }
    
    public func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisionigState) {
        switch state {
        case .requestingCapabilities:
            print("Identifying...")
        case .capabilitiesReceived(let capabilities):
            print("ElementCount \(capabilities.numberOfElements)")
            print("SupportedAlgorithms \(capabilities.algorithms)")
            print("PublicKeyType \(capabilities.publicKeyType)")
            print("StaticOobType \(capabilities.staticOobType)")
            print("ouputOobSize \(capabilities.outputOobSize)")
            print("outputOobActions \(capabilities.outputOobActions)")
            print("inputOobSize \(capabilities.inputOobSize)")
            print("inputOobActions \(capabilities.inputOobActions)")
            
            let addressValid = self.provisioningManager.isUnicastAddressValid == true
            if !addressValid {
                self.provisioningManager.unicastAddress = nil
            }
            print(self.provisioningManager.unicastAddress?.asString() ?? "No address available")
            
            let capabilitiesWereAlreadyReceived = self.capabilitiesReceived
            self.capabilitiesReceived = true
            
            let deviceSupported = self.provisioningManager.isDeviceSupported == true
            if deviceSupported && addressValid {
                if capabilitiesWereAlreadyReceived {
                    print("You are able to start provision.")
                }
            } else {
                if !deviceSupported {
                    print("Selected device is not supported.")
                } else {
                    print("No available Unicast Address in Provisioner's range.")
                }
            }
            
            startProvisioning(networkKey: self.provisioningNetworkKey)
        case .complete:
            print("complete")
            self.bearer.close()
        case let .fail(error):
            print(error)
        default:
            break
        }
    }
    
    func startProvisioning(networkKey: String) {
        guard let capabilities = provisioningManager.provisioningCapabilities else {
            // TODO: 给出一个失败的回调
            return
        }
        
        let publicKeyNotAvailble = capabilities.publicKeyType.isEmpty
        guard publicKeyNotAvailble || publicKey != nil else {
            // TODO: 给出一个失败的回调
            return
        }
        
        publicKey = publicKey ?? .noOobPublicKey
        
        let staticOobNotSupported = capabilities.staticOobType.isEmpty
        let outputOobNotSupported = capabilities.outputOobActions.isEmpty
        let inputOobNotSupported  = capabilities.inputOobActions.isEmpty
        
        guard (staticOobNotSupported && outputOobNotSupported && inputOobNotSupported) || authenticationMethod != nil else {
            // TODO: 给出一个失败的回调
            return
        }
        
        if authenticationMethod == nil {
            authenticationMethod = .noOob
        }
        
        if let provisioningNetworkKey: NetworkKey = meshNetworkManager.meshNetwork!.networkKeys.first(where: { $0.key.hex == networkKey }) {
            self.provisioningManager.networkKey = provisioningNetworkKey
            do {
                try self.provisioningManager.provision(usingAlgorithm: .fipsP256EllipticCurve,
                                                       publicKey: self.publicKey!,
                                                       authenticationMethod: self.authenticationMethod!)
            } catch {
                self.abort(bearer: self.bearer)
            }

        }
    }
}

extension MeshNetwork {
    
    func provision(unprovisionedDevice: UnprovisionedDevice, over bearer: ProvisioningBearer) -> ProvisioningManager {
        return ProvisioningManager(for: unprovisionedDevice, over: bearer, in: self)
    }
}

extension MeshSDK: GattBearerDelegate {
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        if case .complete = provisioningManager.state {
            if meshNetworkManager.save() {
                print("设备真正的添加完成")
            } else {
                
            }
        }
    }
    
    func bearerDidOpen(_ bearer: Bearer) {
        self.bearer = bearer as? ProvisioningBearer
        setupProvisionManager(unprovisionDevice: unprovisionedDevice, bearer: self.bearer)
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        print("Initializing...")
    }
    
    func bearerDidConnect(_ bearer: Bearer) {
        print("Discovering services...")
    }
}

extension MeshSDK: CBCentralManagerDelegate {
    
    @objc public func checkPermission(callback : @escaping CheckPermissionCallback) {
        checkPermissionCallBack = callback
        centralManager.delegate = self
        if centralManager.state == .poweredOn {
            callback("GRANTED", true)
        } else {
            callback("DENIED", false)
        }
    }
    
    public func startScan(type: String, callback: @escaping ScanResultCallback, disposedCallback: @escaping DisposedScanResultCallback) {
        
        centralManager.delegate = self
        scanResultCallback = callback
        disposedScanResultCallback = disposedCallback
        centralManager.scanForPeripherals(withServices: [MeshProvisioningService.uuid], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        
    }
    
    public func stopScan() {
        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.peripheral == peripheral }) {
            if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
                discoveredPeripherals.append((unprovisionedDevice, peripheral, RSSI.intValue))
                scanResultCallback(discoveredPeripherals)
                //
                disposedDiscoveredDevices.append((unprovisionedDevice.uuid.uuidString, RSSI.intValue, peripheral.name ?? "Unknown Device"))
                disposedScanResultCallback(disposedDiscoveredDevices)
            } else {
                if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                    print(index)
                }
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            if let _ = checkPermissionCallBack {
                checkPermissionCallBack("DENIED", false)
            }
        } else {
            if let _ = checkPermissionCallBack {
                checkPermissionCallBack("GRANTED", true)
            }
            
//            if central.state == .poweredOn {
//                startScan(type: "")
//            }
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
