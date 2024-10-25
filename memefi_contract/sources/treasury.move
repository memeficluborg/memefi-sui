module memefi::treasury;

use sui::coin::TreasuryCap;
use sui::dynamic_object_field as dof;

/// [Shared] Wrap the `TreasuryCap` in an object to stop mutation of the supply.
public struct WrappedTreasury<phantom T> has key {
    id: UID,
}

/// Save the `TreasuryCap` as a DOF, to maintain discoverability.
public struct TreasuryCapKey() has copy, store, drop;

/// Wrap a `TreasuryCap<T>` in a `WrappedTreasury<T>` object.
/// `WrappedTreasury<T>` must be shared.
public(package) fun wrap<T>(
    treasury_cap: TreasuryCap<T>,
    ctx: &mut TxContext,
): WrappedTreasury<T> {
    let mut id = object::new(ctx);
    dof::add(&mut id, TreasuryCapKey(), treasury_cap);

    WrappedTreasury { id }
}

/// Return the total number of tokens in circulation.
public fun total_supply<T>(self: &WrappedTreasury<T>): u64 {
    let immut_cap = dof::borrow<TreasuryCapKey, TreasuryCap<T>>(
        &self.id,
        TreasuryCapKey(),
    );

    immut_cap.total_supply()
}

#[allow(lint(share_owned))]
public fun share<T>(treasury: WrappedTreasury<T>) {
    transfer::share_object(treasury)
}
