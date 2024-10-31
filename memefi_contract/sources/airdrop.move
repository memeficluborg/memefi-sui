/// This module handles controlled token airdrops for MEMEFI.
/// It allows a designated administrator to distribute tokens to selected users, recording
/// airdropped users in an internal registry record to prevent duplicate distributions.
///
/// Key Components:
/// - AirdropRegistry: A shared object managing authorized roles and maintaining a
///   record of users who have already received an airdrop. The registry restricts
/// multiple
///   airdrops to the same user and stores administrator roles with flexible
/// configuration.
/// - Roles: The module leverages a role-based system to ensure that only authorized
///   administrators can perform airdrop operations.
module memefi::airdrop;

use memefi::roles::{Self, Roles, AdminRole};
use memefi::safe::{Safe, TokenConfig};
use std::string::String;
use sui::coin;
use sui::event;
use sui::package::{Self, Publisher};
use sui::table::{Self, Table};

/// Cannot airdrop twice to a user.
const EAlreadyAirdropped: u64 = 0;

/// Tries to send tokens with value bigger than the allowed limit in a PTB.
const ETokenLimitExceeded: u64 = 1;

/// [Shared] AirdropRegistry is a shared object that manages roles and maintains a
/// record for airdrop actions.
public struct AirdropRegistry has key {
    id: UID,
    roles: Roles,
    record: Table<String, bool>,
}

/// AirdropEvent is emitted when tokens are airdropped to an address.
/// It records the recipient's address and the value of tokens airdropped.
public struct AirdropEvent<phantom T> has copy, drop {
    addr: address,
    value: u64,
}

// Define a OTW for claiming the `Publisher` object.
public struct AIRDROP has drop {}

/// Initializes the AirdropRegistry and assigns the sender as the initial admin.
/// The registry is shared on the network for further actions.
fun init(otw: AIRDROP, ctx: &mut TxContext) {
    package::claim_and_keep(otw, ctx);

    // Create the `AirdropRegistry` and share it on the network.
    let mut airdrop_registry = AirdropRegistry {
        id: object::new(ctx),
        roles: roles::new(ctx),
        record: table::new(ctx),
    };

    // Authorize the sender as the first admin of the `AirdropRegistry`.
    airdrop_registry.roles_mut().authorize(roles::new_role<AdminRole>(ctx.sender()));

    transfer::share_object(airdrop_registry);
}

// === Public functions ===

/// Airdrops a specified value of tokens to a user and adds the user's ID to the record.
/// The sender must have the `AdminRole` to execute the airdrop.
/// Aborts with `sui::balance::ENotEnough` if `value > coin` value.
public fun send_token<T>(
    self: &mut Safe<T>,
    value: u64,
    user_id: String,
    user_addr: address,
    registry: &mut AirdropRegistry,
    config: &mut TokenConfig,
    ctx: &mut TxContext,
) {
    // Ensure the sender is authorized with `AdminRole`.
    registry.roles().assert_has_role<AdminRole>(ctx.sender());

    // Ensure the user has not been airdropped already.
    assert!(registry.is_airdropped(user_id) == false, EAlreadyAirdropped);

    // Accumulate token amount in config and check max limit.
    config.update_token_config_amount(value);
    assert!(
        config.token_config_amount() <= config.token_config_max_limit(),
        ETokenLimitExceeded,
    );

    // Withdraw the required balance from the Safe and create a new `Coin<T>`.
    let airdrop_coin = coin::take<T>(self.balance_mut<T>(), value, ctx);
    event::emit(AirdropEvent<T> { addr: user_addr, value: airdrop_coin.value() });

    // Add the user's ID in the record.
    registry.add_record(user_id, ctx);

    // Transfer the coin to the specified address.
    transfer::public_transfer(airdrop_coin, user_addr);
}

// --- Authorize / Deauthorize Role functions ---

/// Publisher can authorize an address with the `AdminRole` in the `AirdropRegistry`.
public fun authorize_admin(
    self: &mut AirdropRegistry,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().authorize(roles::new_role<AdminRole>(addr));
}

/// Publisher can authorize an address with the `AdminRole` in the `AirdropRegistry`.
public fun deauthorize_admin(
    self: &mut AirdropRegistry,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().deauthorize(roles::new_role<AdminRole>(addr));
}

// === Internal functions ===

/// [Internal] Adds a user_id to the `AirdropRegistry` record.
public(package) fun add_record(
    self: &mut AirdropRegistry,
    user_id: String,
    _ctx: &mut TxContext,
) {
    self.record.add(user_id, true);
}

/// [Internal] Removes a user_id from the `AirdropRegistry` record.
public(package) fun remove_record(
    self: &mut AirdropRegistry,
    user_id: String,
    _ctx: &mut TxContext,
) {
    self.record.remove(user_id);
}

/// Returns a mutable reference to the `AirdropRegistry` Roles for internal modifications.
public(package) fun roles_mut(self: &mut AirdropRegistry): &mut Roles {
    &mut self.roles
}

/// Returns a read-only reference to the `AirdropRegistry` Roles.
public(package) fun roles(self: &AirdropRegistry): &Roles {
    &self.roles
}

// === Accessors ===

/// Checks if a user_id is present in the `AirdropRegistry` record.
/// Returns `true` if the user_id is found, otherwise `false`.
public fun is_airdropped(self: &AirdropRegistry, user_id: String): bool {
    self.record.contains(user_id)
}

#[test_only]
public(package) fun test_init(ctx: &mut TxContext) {
    init(AIRDROP {}, ctx);
}
