module memefi::airdrop;

use memefi::roles::{Self, Roles, AdminRole};
use memefi::safe::Safe;
use std::string::String;
use sui::coin;
use sui::event;
use sui::package::{Self, Publisher};
use sui::table::{Self, Table};

const EAlreadyAirdropped: u64 = 0;
const EWrongPublisher: u64 = 1;

/// [Shared] AirdropRegistry is a shared object that manages roles and maintains a
/// denylist for airdrop actions.
public struct AirdropRegistry has key {
    id: UID,
    roles: Roles,
    denylist: Table<String, bool>,
}

/// [Helper] An empty struct to mock custom configurations per role.
public struct AirdropConfig() has store, drop;

/// AirdropEvent is emitted when tokens are airdropped to an address.
/// It records the recipient's address and the value of tokens airdropped.
public struct AirdropEvent<phantom T> has copy, drop {
    addr: address,
    value: u64,
}

// Define a OTW for claiming the `Publisher` object.
public struct AIRDROP has drop {}

/// Initializes the AirdropRegistry and assigns the sender as the initial admin and
/// freezer. The registry is shared on the network for further actions.
fun init(otw: AIRDROP, ctx: &mut TxContext) {
    package::claim_and_keep(otw, ctx);

    // Create the `AirdropRegistry` and share it on the network.
    let mut airdrop_registry = AirdropRegistry {
        id: object::new(ctx),
        roles: roles::new(ctx),
        denylist: table::new(ctx),
    };

    // Authorize the sender as the first admin of the `AirdropRegistry`.
    airdrop_registry
        .roles_mut()
        .authorize<AdminRole>(
            roles::new_role<AdminRole>(ctx.sender()),
        );

    transfer::share_object(airdrop_registry);
}

// === Public functions ===

/// Airdrops a specified value of tokens to a user and adds the user's ID to the denylist.
/// The sender must have the `AdminRole` to execute the airdrop.
/// Aborts with `sui::balance::ENotEnough` if `value > coin` value.
public fun new<T>(
    self: &mut Safe<T>,
    value: u64,
    user_id: String,
    user_addr: address,
    registry: &mut AirdropRegistry,
    ctx: &mut TxContext,
) {
    // Ensure the sender is authorized with `AdminRole`.
    registry.roles().assert_has_role<AdminRole>(ctx.sender());

    // Ensure the user has not been airdropped already.
    assert_is_not_airdropped(registry, user_id);

    // Withdraw the required balance from the Safe and create a new `Coin<T>`.
    let airdrop_coin = coin::take<T>(self.balance_mut<T>(), value, ctx);
    event::emit(AirdropEvent<T> { addr: user_addr, value: airdrop_coin.value() });

    // Add the user's ID in the denylist.
    registry.denylist_add(user_id, ctx);

    // Transfer the coin to the specified address.
    transfer::public_transfer(airdrop_coin, user_addr);
}

// --- Authorize / Deauthorize Role functions ---

/// Publisher can authorize an address with the `AdminRole` in the `AirdropRegistry`.
public fun authorize_admin(
    pub: &Publisher,
    registry: &mut AirdropRegistry,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<AdminRole>(), EWrongPublisher);

    registry.roles_mut().authorize<AdminRole>(roles::new_role<AdminRole>(addr));
}

/// Publisher can authorize an address with the `AdminRole` in the `AirdropRegistry`.
public fun deauthorize_admin(
    pub: &Publisher,
    registry: &mut AirdropRegistry,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<AdminRole>(), EWrongPublisher);

    registry.roles_mut().deauthorize<AdminRole>(roles::new_role<AdminRole>(addr));
}

// === Internal functions ===

/// [Internal] Adds a user_id to the `AirdropRegistry` denylist.
/// This function is for internal use and does not check for `FreezerRole`.
public(package) fun denylist_add(
    self: &mut AirdropRegistry,
    user_id: String,
    _ctx: &mut TxContext,
) {
    table::add(&mut self.denylist, user_id, true);
}

/// [Internal] Removes a user_id from the `AirdropRegistry` denylist.
/// This function is for internal use and does not check for `FreezerRole`.
public(package) fun denylist_remove(
    self: &mut AirdropRegistry,
    user_id: String,
    _ctx: &mut TxContext,
) {
    table::remove(&mut self.denylist, user_id);
}

/// Returns a mutable reference to the `AirdropRegistry` Roles for internal modifications.
public(package) fun roles_mut(self: &mut AirdropRegistry): &mut Roles {
    &mut self.roles
}

/// Returns a read-only reference to the `AirdropRegistry` Roles.
public(package) fun roles(self: &AirdropRegistry): &Roles {
    &self.roles
}

public(package) fun assert_is_not_airdropped(self: &AirdropRegistry, user_id: String) {
    assert!(self.is_airdropped(user_id) == false, EAlreadyAirdropped);
}

// === Accessors ===

/// Checks if a user_id is present in the `AirdropRegistry` denylist.
/// Returns `true` if the user_id is found, otherwise `false`.
public fun is_airdropped(self: &AirdropRegistry, user_id: String): bool {
    table::contains(&self.denylist, user_id)
}

#[test_only]
public(package) fun test_init(ctx: &mut TxContext) {
    init(AIRDROP {}, ctx);
}
