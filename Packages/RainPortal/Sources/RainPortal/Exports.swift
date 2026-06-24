// Re-export PortalSwift so that `import RainPortal` also brings Portal's types into scope.
// Clients using the Portal adapter (e.g. backup/recovery flows) get `Portal` and friends without
// adding a separate PortalSwift package dependency to their app target.
@_exported import PortalSwift
