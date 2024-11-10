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

use memefi::roles::{Self, Roles, Role, ApiRole};
use memefi::safe::Safe;
use std::string::String;
use sui::coin;
use sui::event;
use sui::package::{Self, Publisher};
use sui::table::{Self, Table};

/// The maximum number of tokens that can be sent in one PTB (10 million * 10^9).
const MAX_TOKEN_LIMIT: u64 = 10_000_000_000_000_000;

/// Cannot airdrop twice to a user.
const EAlreadyAirdropped: u64 = 0;

/// Tries to send tokens with value bigger than the allowed limit in a PTB.
const ETokenLimitExceeded: u64 = 1;

/// Invalid sender attempted to execute an action.
const EInvalidSender: u64 = 2;

/// [Shared] AirdropRegistry is a shared object that manages roles and maintains a
/// record for airdrop actions.
public struct AirdropRegistry has key {
    id: UID,
    roles: Roles,
    record: Table<String, bool>,
}

/// Helper configuration object for managing token limits in a transaction (PTB).
public struct AirdropConfig {
    max_token_limit: u64,
    tokens: u64,
    role: Role<ApiRole>,
}

/// AirdropEvent is emitted when tokens are airdropped to an address.
/// It records the recipient's address and the value of tokens airdropped.
public struct AirdropEvent<phantom T> has copy, drop {
    user_id: String,
    addr: address,
    value: u64,
}

// Define a OTW for claiming the `Publisher` object.
public struct AIRDROP has drop {}

/// Initializes the AirdropRegistry and shares with the network.
fun init(otw: AIRDROP, ctx: &mut TxContext) {
    package::claim_and_keep(otw, ctx);

    // Create the `AirdropRegistry` and share it on the network.
    let registry = AirdropRegistry {
        id: object::new(ctx),
        roles: roles::new(ctx),
        record: table::new(ctx),
    };

    transfer::share_object(registry);
}

// === Public functions ===

/// Initializes an airdrop by temporarily taking the `ApiRole` from the sender to make
/// sure that only one `AirdropConfig` can be created.
/// `AirdropConfig` makes sure that the max token limit is not exceeded in a single
/// transaction.
public fun init_send(registry: &mut AirdropRegistry, ctx: &mut TxContext): AirdropConfig {
    // Ensure the sender is authorized with `ApiRole`.
    registry.roles().assert_has_role<ApiRole>(ctx.sender());

    // Take the sender's role out of the Registry.
    registry.roles_mut().deauthorize<ApiRole>(roles::new_role<ApiRole>(ctx.sender()));

    // Return a hot potato that temporarily wraps the role.
    AirdropConfig {
        max_token_limit: MAX_TOKEN_LIMIT,
        tokens: 0,
        role: roles::new_role<ApiRole>(ctx.sender()),
    }
}

/// Airdrops a specified value of tokens to a user and adds the user's ID to the record.
/// The sender must have the `ApiRole` to execute the airdrop.
/// - Aborts with `sui::balance::ENotEnough` if `value > coin` value.
public fun send_token<T>(
    self: &mut Safe<T>,
    value: u64,
    user_id: String,
    user_addr: address,
    registry: &mut AirdropRegistry,
    config: &mut AirdropConfig,
    ctx: &mut TxContext,
) {
    // Ensure the sender is the same as the address in the role we hold.
    assert!(config.role.addr() == ctx.sender(), EInvalidSender);

    // Ensure the user has not been airdropped already.
    assert!(!registry.is_airdropped(user_id), EAlreadyAirdropped);

    // Accumulate token amount in config.
    config.tokens = config.tokens + value;

    // Withdraw the required balance from the Safe and create a new `Coin<T>`.
    let airdrop_coin = coin::take<T>(self.balance_mut<T>(), value, ctx);
    event::emit(AirdropEvent<T> {
        user_id,
        addr: user_addr,
        value: airdrop_coin.value(),
    });

    // Add the user's ID in the record.
    registry.add_record(user_id, ctx);

    // Transfer the coin to the specified address.
    transfer::public_transfer(airdrop_coin, user_addr);
}

/// Consumes the hot-potato and allows the transaction of `send_tokens` to finalize.
/// The `ApiRole` is granted back to the sender in `AirdropRegistry`.
public fun finalize_send(
    registry: &mut AirdropRegistry,
    config: AirdropConfig,
    ctx: &mut TxContext,
) {
    // Destructure the hot-potato
    let AirdropConfig {
        max_token_limit,
        tokens,
        role,
    } = config;

    // Ensure the max token limit has not been exceeded.
    assert!(tokens <= max_token_limit, ETokenLimitExceeded);

    // Ensure the sender is the same as the address in the role we hold.
    assert!(role.addr() == ctx.sender(), EInvalidSender);

    registry.roles_mut().authorize(role);
}

// --- Authorize / Deauthorize Role functions ---

/// Publisher can authorize an address with the `ApiRole` in the `AirdropRegistry`.
public fun authorize_api(
    self: &mut AirdropRegistry,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().authorize(roles::new_role<ApiRole>(addr));
}

/// Publisher can authorize an address with the `ApiRole` in the `AirdropRegistry`.
public fun deauthorize_api(
    self: &mut AirdropRegistry,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().deauthorize(roles::new_role<ApiRole>(addr));
}

// === Internal functions ===

/// Adds a user_id to the `AirdropRegistry` record.
public(package) fun add_record(
    self: &mut AirdropRegistry,
    user_id: String,
    _ctx: &mut TxContext,
) {
    self.record.add(user_id, true);
}

/// Removes a user_id from the `AirdropRegistry` record.
public(package) fun remove_record(
    self: &mut AirdropRegistry,
    user_id: String,
    _ctx: &mut TxContext,
) {
    self.record.remove(user_id);
}

/// Returns a mutable reference to the `AirdropRegistry` Roles.
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
