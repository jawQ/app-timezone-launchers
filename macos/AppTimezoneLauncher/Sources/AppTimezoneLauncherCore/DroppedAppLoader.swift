import Foundation
import UniformTypeIdentifiers

public enum DroppedAppLoader {
  @discardableResult
  public static func load(
    from providers: [NSItemProvider],
    onURL: @escaping @MainActor @Sendable (URL) -> Void
  ) -> Bool {
    let fileProviders = providers.filter {
      $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
    }

    for provider in fileProviders {
      provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
        guard let url = fileURL(from: item) else { return }
        Task { @MainActor in
          onURL(url)
        }
      }
    }

    return !fileProviders.isEmpty
  }

  private static func fileURL(from item: NSSecureCoding?) -> URL? {
    if let url = item as? URL {
      return url
    }
    if let data = item as? Data,
      let string = String(data: data, encoding: .utf8)
    {
      return URL(string: string)
    }
    if let string = item as? String {
      return URL(string: string)
    }
    return nil
  }
}
