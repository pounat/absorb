import Foundation
import Security

/// Client certificate for native iOS networking.
///
/// Playback builds an `AVURLAsset`, which answers its own authentication
/// challenges and consults no delegate of ours, so a default credential for the
/// server's protection space is the only hook there. `background_downloader`
/// owns its `URLSession` and is not covered; Dart's HTTP goes through
/// `HttpOverrides`.
final class MtlsIdentityStore {
  static let shared = MtlsIdentityStore()

  private let bundleFileName = "mtls_client.p12"
  private let hostKey = "absorb_mtls_host"
  private let portKey = "absorb_mtls_port"
  private let keychainService = "com.barnabas.absorb.mtls"
  private let keychainAccount = "bundle-password"

  private var identity: SecIdentity?
  private var chain: [SecCertificate] = []
  private var protectionSpace: URLProtectionSpace?

  private var bundleURL: URL {
    let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return dir.appendingPathComponent(bundleFileName)
  }

  /// Imports and activates a PKCS#12 bundle. False when it or the password is
  /// unusable.
  func setCertificate(bundle: Data, password: String, host: String, port: Int) -> Bool {
    // No host means no protection space to register against, so say so rather
    // than let playback go without the identity.
    guard !host.isEmpty else {
      NSLog("[AbsorbMtls] No server host for the client certificate")
      return false
    }
    guard load(bundle: bundle, password: password) else { return false }
    register(host: host, port: port)
    do {
      // Application Support is not guaranteed to exist yet.
      try FileManager.default.createDirectory(
        at: bundleURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      // Not .completeFileProtection: a background start reads this while the
      // device is locked.
      try bundle.write(to: bundleURL, options: .completeFileProtectionUntilFirstUserAuthentication)
      // A private key does not travel to another device.
      var url = bundleURL
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try url.setResourceValues(values)
      store(password: password)
      UserDefaults.standard.set(host, forKey: hostKey)
      UserDefaults.standard.set(port, forKey: portKey)
    } catch {
      NSLog("[AbsorbMtls] Could not persist the client certificate: \(error)")
      // Still active for this session.
    }
    return true
  }

  /// Removes every client-certificate credential, not just this session's: an
  /// earlier host would otherwise keep being offered the deleted identity. The
  /// tracked space goes first, since `allCredentials` is not documented to
  /// enumerate session-only ones.
  func clearCertificate() {
    if let space = protectionSpace,
       let credential = URLCredentialStorage.shared.defaultCredential(for: space) {
      URLCredentialStorage.shared.remove(credential, for: space)
    }
    for (space, credentials) in URLCredentialStorage.shared.allCredentials
    where space.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
      for credential in credentials.values {
        URLCredentialStorage.shared.remove(credential, for: space)
      }
    }
    identity = nil
    chain = []
    protectionSpace = nil
    try? FileManager.default.removeItem(at: bundleURL)
    deletePassword()
    [hostKey, portKey].forEach(UserDefaults.standard.removeObject(forKey:))
  }

  /// Re-loads a stored certificate. Call once at launch: the credential is
  /// session-only, and a UI-less start may reach the network before Dart runs.
  func restore() {
    guard let data = try? Data(contentsOf: bundleURL) else { return }
    guard load(bundle: data, password: loadPassword()) else {
      NSLog("[AbsorbMtls] Stored client certificate is unusable")
      return
    }
    let port = UserDefaults.standard.integer(forKey: portKey)
    register(host: UserDefaults.standard.string(forKey: hostKey) ?? "",
             port: port == 0 ? 443 : port)
  }

  private func load(bundle: Data, password: String) -> Bool {
    var rawItems: CFArray?
    let options = [kSecImportExportPassphrase as String: password] as CFDictionary
    let status = SecPKCS12Import(bundle as CFData, options, &rawItems)
    guard status == errSecSuccess,
          let items = rawItems as? [[String: Any]],
          let first = items.first,
          let imported = first[kSecImportItemIdentity as String] else {
      NSLog("[AbsorbMtls] Client certificate bundle rejected (status \(status))")
      return false
    }
    guard CFGetTypeID(imported as CFTypeRef) == SecIdentityGetTypeID() else {
      NSLog("[AbsorbMtls] Client certificate bundle has no usable identity")
      return false
    }
    identity = (imported as! SecIdentity)
    chain = (first[kSecImportItemCertChain as String] as? [SecCertificate]) ?? []
    return true
  }

  /// Publishes the identity for [host], dropping any host registered before it.
  private func register(host: String, port: Int) {
    guard let identity = identity, !host.isEmpty else { return }
    if let previous = protectionSpace,
       let credential = URLCredentialStorage.shared.defaultCredential(for: previous) {
      URLCredentialStorage.shared.remove(credential, for: previous)
    }
    let space = URLProtectionSpace(host: host,
                                   port: port,
                                   protocol: "https",
                                   realm: nil,
                                   authenticationMethod: NSURLAuthenticationMethodClientCertificate)
    protectionSpace = space
    URLCredentialStorage.shared.setDefaultCredential(
      URLCredential(identity: identity, certificates: chain, persistence: .forSession), for: space)
  }

  // MARK: - Password

  /// Keychain rather than UserDefaults, since this passphrase decrypts a private
  /// key. Dart keeps a second copy in shared_preferences, which it needs to
  /// rebuild the `SecurityContext` at every start. `AfterFirstUnlock` for
  /// background starts, `ThisDeviceOnly` to keep it out of backups.
  private func store(password: String) {
    var attributes = passwordQuery()
    attributes[kSecValueData as String] = Data(password.utf8)
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    SecItemDelete(passwordQuery() as CFDictionary)
    let status = SecItemAdd(attributes as CFDictionary, nil)
    if status != errSecSuccess {
      NSLog("[AbsorbMtls] Could not store the certificate password (status \(status))")
    }
  }

  private func loadPassword() -> String {
    var query = passwordQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data else {
      return ""
    }
    return String(data: data, encoding: .utf8) ?? ""
  }

  private func deletePassword() {
    SecItemDelete(passwordQuery() as CFDictionary)
  }

  private func passwordQuery() -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount,
    ]
  }
}
