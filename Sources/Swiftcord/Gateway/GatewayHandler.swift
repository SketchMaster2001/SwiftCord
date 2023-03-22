//
//  GatewayHandler.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation
import NIOCore

/// Gateway Handler
extension Shard {

    /**
     Handles all gateway events (except op: 0)
     - parameter payload: Payload sent with event
     */
    func handleGateway(_ payload: Payload) async {

        guard let op = OP(rawValue: payload.op) else {
            self.swiftcord.log(
                "Received unknown gateway\nOP: \(payload.op)\nData: \(payload.d)"
            )
            return
        }

        switch op {

        /// OP: 1
        case .heartbeat:
            self.send(self.heartbeatPayload.encode())

        /// OP: 11
        case .heartbeatACK:
            self.heartbeatQueue.sync { self.acksMissed = 0 }

        /// OP: 10
        case .hello:
            self.heartbeat(at: .milliseconds((payload.d as! [String: Any])["heartbeat_interval"] as! Int64))
            
            guard !self.isReconnecting else {
                self.isReconnecting = false
                let data: [String: Any] = [
                    "token": self.swiftcord.token,
                    "session_id": self.sessionId!,
                    "seq": self.lastSeq ?? NSNull()
                ]

                let payload = Payload(op: .resume, data: data)
                self.send(payload.encode())
                return
            }

            self.identify()

        /// OP: 9
        case .invalidSession:
            self.isReconnecting = payload.d as! Bool
            await self.reconnect()

        /// OP: 7
        case .reconnect:
            self.isReconnecting = true
            await self.reconnect()

        /// Others
        default:
            break
        }

    }

}
