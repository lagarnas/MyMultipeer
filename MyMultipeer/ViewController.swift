//
//  ViewController.swift
//  MyMultipeer
//
//  Created by Анастасия Леонтьева on 27.08.2024.
//

import MultipeerConnectivity
import UIKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var sendMessageButton: UIButton!
    
    // MARK: - Private constants
    
    private let serviceType = "mctest"
    
    // MARK: - Private properties
    
    private var multipeerSession: MCSession?
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var peerID = MCPeerID(displayName: UIDevice.current.name)
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        multipeerSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        multipeerSession?.delegate = self
        startBrowser()
    }
    
    // MARK: - Actions
    
    @IBAction func didTapConnectButton(_ sender: UIButton) {
        stopBrowsingAndAdvertising()
        startAdvertiser()
    }
    
    @IBAction func didTapDisconnectButton(_ sender: UIButton) {
        multipeerSession?.connectedPeers.forEach {
            multipeerSession?.cancelConnectPeer($0)
        }
        stopBrowsingAndAdvertising()
        startBrowser()
    }
    
    @IBAction func didTapSendMessageButton(_ sender: UIButton) {
        send(message: "Hello from \(peerID.displayName)")
    }
    
    // MARK: Private methods
    
    func startAdvertiser() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    func startBrowser() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func stopBrowsingAndAdvertising() {
        if let browser = browser {
            browser.stopBrowsingForPeers()
        }
        
        if let advertiser = advertiser {
            advertiser.stopAdvertisingPeer()
        }
        
        multipeerSession?.disconnect()
    }
    
    func send(message: String) {
        guard let connectedPeers = multipeerSession?.connectedPeers,
              let messageData = try? JSONEncoder().encode(message) else { return }
        do {
            try multipeerSession?.send(messageData, toPeers: connectedPeers, with: .reliable)
        } catch {}
    }
}

// MARK: - MCSessionDelegate

extension ViewController: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            DispatchQueue.main.async {
                self.statusLabel.text = "Not connected"
            }
        case .connecting:
            DispatchQueue.main.async {
                self.statusLabel.text = "Connecting"
            }
        case .connected:
            DispatchQueue.main.async {
                self.statusLabel.text = "Connected"
            }
        @unknown default:
            DispatchQueue.main.async {
                self.statusLabel.text = "Fatal error"
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            guard let message = try? JSONDecoder().decode(String.self, from: data) else { return }
            let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, multipeerSession)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ViewController: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let multipeerSession = multipeerSession else { return }
        browser.invitePeer(peerID, to: multipeerSession, withContext: nil, timeout: 10.0)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
