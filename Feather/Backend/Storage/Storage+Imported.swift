import CoreData

// MARK: - Class extension: Imported Apps
extension Storage {
	func addImported(
		uuid: String,
		source: URL? = nil,
		
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		
		completion: @escaping (Error?) -> Void
	) {
		
		DispatchQueue.main.async {
			let new = Imported(context: self.context)
			
			new.uuid = uuid
			new.source = source
			new.date = Date()
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
					AppLogManager.shared.success("Successfully added imported app to database: \(appName ?? "Unknown")", category: "Storage")
					completion(nil)
				} catch {
					AppLogManager.shared.error("Failed to save imported app to database: \(error.localizedDescription)", category: "Storage")
					completion(error)
				}
			} else {
				HapticsManager.shared.impact()
				AppLogManager.shared.success("Added imported app to database (no changes): \(appName ?? "Unknown")", category: "Storage")
				completion(nil)
			}
		}
	}
	
	func getLatestImportedApp() -> Imported? {
		let fetchRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
		fetchRequest.fetchLimit = 1
		return (try? context.fetch(fetchRequest))?.first
	}
}
