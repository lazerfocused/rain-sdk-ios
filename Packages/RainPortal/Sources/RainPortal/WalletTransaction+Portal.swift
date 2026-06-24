import Foundation
import PortalSwift
import RainSDK

// Portal → Rain model mapping. Lives with the Portal adapter so core's shared models
// (`WalletTransaction`, `WalletTransactionOrder`) stay vendor-free. Travels with the adapter
// when it moves to the RainPortal package.

extension WalletTransaction {
  /// Maps Portal's `FetchedTransaction` onto the vendor-agnostic `WalletTransaction`.
  init(_ tx: FetchedTransaction) {
    var metadata: WalletTransaction.Metadata?
    if let txMetadata = tx.metadata {
      metadata = WalletTransaction.Metadata(
        blockTimestamp: txMetadata.blockTimestamp
      )
    }

    self.init(
      blockNum: tx.blockNum,
      uniqueId: tx.uniqueId,
      hash: tx.hash,
      from: tx.from,
      to: tx.to,
      value: tx.value,
      erc721TokenId: tx.erc721TokenId,
      erc1155Metadata: tx.erc1155Metadata?.map { meta in
        guard let meta else { return nil }
        return WalletTransaction.Erc1155Metadata(
          tokenId: meta.tokenId,
          value: meta.value
        )
      },
      tokenId: tx.tokenId,
      asset: tx.asset,
      category: tx.category,
      rawContract: tx.rawContract.map {
        WalletTransaction.RawContract(
          value: $0.value,
          address: $0.address,
          decimal: $0.decimal
        )
      },
      metadata: metadata,
      chainId: tx.chainId
    )
  }
}

extension WalletTransactionOrder {
  /// Maps to Portal's `TransactionOrder` for use in the Portal adapter.
  var toPortalOrder: TransactionOrder {
    switch self {
    case .ASC: return .ASC
    case .DESC: return .DESC
    }
  }
}
