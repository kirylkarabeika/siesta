//
//  Networking-Alamofire.swift
//  Siesta
//
//  Created by Paul on 2015/6/26.
//  Copyright © 2016 Bust Out Solutions. All rights reserved.
//

import Foundation
#if !COCOAPODS
    import Siesta
#endif
import Alamofire

/**
  Uses [Alamofire](https://github.com/Alamofire/Alamofire) for networking.

  You can create instances of this provider with a custom
  [Alamofire.Manager](http://cocoadocs.org/docsets/Alamofire/1.3.0/Classes/Manager.html)
  in order to control caching, certificate validation rules, etc. For example, here is a `Service` that will
  not use the cell network:

      class MyAPI: Service {
          init() {
              let configuration = URLSessionConfiguration.ephemeral
              configuration.allowsCellularAccess = false
              super.init(
                  baseURL: "http://foo.bar/v1",
                  networking: AlamofireProvider(configuration: configuration))
          }
      }
*/
public struct AlamofireProvider: NetworkingProvider
    {
    public let session: Alamofire.Session

    public init(session: Alamofire.Session = Session.default)
        { self.session = session }

    public init(configuration: URLSessionConfiguration)
        { self.init(session: Alamofire.Session(configuration: configuration)) }

    public func startRequest(
            _ request: URLRequest,
            completion: @escaping RequestNetworkingCompletionCallback)
        -> RequestNetworking
        {
        AlamofireRequestNetworking(
            session: session,
            request: session.request(request)
                .response { completion($0.response, $0.data, $0.error) })
        }
    }

internal struct AlamofireRequestNetworking: RequestNetworking, SessionTaskContainer
    {
    let session: Alamofire.Session
    let alamofireRequest: Alamofire.Request

    init(session: Alamofire.Session, request alamofireRequest: Alamofire.Request)
        {
        self.session = session
        self.alamofireRequest = alamofireRequest
        }

    var task: URLSessionTask
        {
        session.rootQueue.sync
            {
            let requestTask = alamofireRequest.task!
            if requestTask.state == .suspended
                { alamofireRequest.resume() }   // in case session.startRequestsImmediately is false
            return requestTask
            }
        }

    func cancel()
        { alamofireRequest.cancel() }
    }

extension Alamofire.Session: NetworkingProviderConvertible
    {
    /// You can pass an `AlamoFire.Manager` when creating a `Service`.
    public var siestaNetworkingProvider: NetworkingProvider
        { return AlamofireProvider(session: self) }
    }
