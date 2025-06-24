import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let serviceName = "xray-ios"
        guard let resPtr = StartNodeService(serviceName) else {
            completionHandler(NSError(domain: "Xray", code: 1, userInfo: [NSLocalizedDescriptionKey: "start failed"]))
            return
        }
        let result = String(cString: resPtr)
        FreeCString(resPtr)
        if result == "success" {
            completionHandler(nil)
        } else {
            completionHandler(NSError(domain: "Xray", code: 2, userInfo: [NSLocalizedDescriptionKey: result]))
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        let serviceName = "xray-ios"
        if let resPtr = StopNodeService(serviceName) {
            FreeCString(resPtr)
        }
        completionHandler()
    }
}
