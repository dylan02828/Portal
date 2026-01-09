import CoreData

// MARK: - Class extension: Signed Apps
extension Storage {
	func addSigned(
		uuid: String,
		source: URL? = nil,
		certificate: CertificatePair? = nil,
		
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		
		completion: @escaping (Error?) -> Void
	) {
		
		DispatchQueue.main.async {
			let new = Signed(context: self.context)
			
			new.uuid = uuid
			new.source = source
			new.date = Date()
			// if nil, we assume adhoc or certificate was deleted afterwards
			new.certificate = certificate
			// Provide default values for optional fields
			new.identifier = appIdentifier ?? ""
			new.name = appName ?? "Unknown"
			new.icon = appIcon
			new.version = appVersion ?? ""
			
			// Save context synchronously on main queue
			if self.context.hasChanges {
				do {
					try self.context.save()
					HapticsManager.shared.impact()
					AppLogManager.shared.success("Successfully added signed app to database: \(appName ?? "Unknown")", category: "Storage")
					completion(nil)
				} catch {
					AppLogManager.shared.error("Failed to save signed app to database: \(error.localizedDescription)", category: "Storage")
					completion(error)
				}
			} else {
				HapticsManager.shared.impact()
				AppLogManager.shared.success("Added signed app to database (no changes): \(appName ?? "Unknown")", category: "Storage")
				completion(nil)
			}
		}
	}
	
	func getSignedApps() -> [Signed] {
		let request: NSFetchRequest<Signed> = Signed.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]
		return (try? context.fetch(request)) ?? []
	}
}
