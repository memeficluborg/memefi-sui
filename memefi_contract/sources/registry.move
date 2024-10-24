module memefi::registry;

use std::string::String;
use sui::package::{Self, Publisher};
use sui::table::{Self, Table};

// === Errors ===
const EWrongPublisher: u64 = 0;
const EAlreadyAuthorized: u64 = 1;
const EAddressNotAuthorized: u64 = 2;

// === Structs ===

/// Define a one-time-witness for the `Publisher` object.
public struct REGISTRY has drop {}

/// [Shared] Store settings and manage actions through this object.
public struct Registry has key {
    id: UID,
    auth: vector<address>,
    denylist: Table<String, bool>,
}

/// [Helper] Witness type for authorizating an address to manage `Registry`.
public struct RegistryAuthorizedCaps has copy, drop, store {}

fun init(otw: REGISTRY, ctx: &mut TxContext) {
    // Claim the `Publisher` object
    package::claim_and_keep(otw, ctx);

    // Create the `Registry` and share it on the network.
    let registry = Registry {
        id: object::new(ctx),
        auth: vector::empty(),
        denylist: table::new(ctx),
    };

    transfer::share_object(registry);
}

// --- Registry authorization / deauthorization ---

/// This function is used to authorize a new address in `Registry`.
/// A `Publisher` object is required.
public fun authorize(
    pub: &Publisher,
    registry: &mut Registry,
    account: address,
    _ctx: &mut TxContext,
) {
    // Make sure the `Publisher` originates from this package.
    assert!(pub.from_package<Registry>(), EWrongPublisher);

    // Check if address is already authorized to avoid duplicate entries.
    assert!(registry.auth.contains(&account), EAlreadyAuthorized);

    // Authorize given address.
    vector::push_back(&mut registry.auth, account);
}

/// This function is used to deauthorize an address in `Registry`.
/// A `Publisher` object is required.
public fun deauthorize(
    pub: &Publisher,
    registry: &mut Registry,
    account: address,
    _ctx: &mut TxContext,
) {
    // Make sure the `Publisher` originates from this package.
    assert!(pub.from_package<Registry>(), EWrongPublisher);

    // Retrieve the address from `Registry`.
    let (account_exists, account_index) = vector::index_of(&registry.auth, &account);

    // Abort if address is not listed as authorized.
    assert!(account_exists, EAddressNotAuthorized);

    // Remove given address from the `Registry` authorized vector.
    vector::remove(&mut registry.auth, account_index);
}

/// Clear out ALL authorized addresses in `Registry`.
/// A `Publisher` object is required.
public fun reset(pub: &Publisher, registry: &mut Registry, _ctx: &mut TxContext) {
    // Make sure the `Publisher` originates from this package.
    assert!(pub.from_package<Registry>(), EWrongPublisher);

    // Use the `destroy` macro to clear out the authorized vector.
    vector::destroy!(registry.auth, |_addr| {});
}
