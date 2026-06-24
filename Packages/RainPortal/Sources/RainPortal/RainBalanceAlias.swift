// `Balance` is ambiguous inside RainPortal: this package re-exports PortalSwift (which also
// defines a `Balance`), and `RainSDK.Balance` can't be written because the module name collides
// with the `RainSDK` protocol. A scoped import pins `Balance` to the Rain model — a scoped import
// outranks the wildcard/re-exported ones in name lookup — so the alias is unambiguous. The Portal
// adapter uses `RainBalance` wherever it names the type.
import struct RainSDK.Balance

public typealias RainBalance = Balance
