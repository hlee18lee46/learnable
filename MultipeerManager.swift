//
//  MultipeerManager.swift
//  learnable
//
//  Created by Han Lee on 12/5/24.
//


import Foundation
import MultipeerConnectivity

class MultipeerManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedData: String = ""

    private let peerID = MCPeerID(displayName: UIDevice.current.name)
    private let serviceType = "quiz-battle"
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser

    override init() {
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()

        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
    }

    func startHosting() {
        advertiser.startAdvertisingPeer()
    }

    func joinSession() {
        browser.startBrowsingForPeers()
    }

    func stopSession() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }

    func send(data: String) {
        guard !session.connectedPeers.isEmpty, let dataToSend = data.data(using: .utf8) else { return }

        do {
            try session.send(dataToSend, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }

    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedData = message
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    // MARK: - MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    // MARK: - MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
