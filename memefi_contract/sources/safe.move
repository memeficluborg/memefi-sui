/// This module provides a secure container, the `Safe`, for holding MEMEFI token balance
/// with controlled access via role-based permissions.
///
/// Key functionalities:
/// - Deposits and Withdrawals: Allows authorized `SafeManagerRole` addresses to deposit
/// and withdraw specific amounts, while Admins can withdraw the entire balance.
/// - Role Management: Publishers can authorize or revoke `AdminRole` and
/// `SafeManagerRole` for specific addresses, defining who can manage the safe and its
/// contents.
module memefi::safe;

use memefi::memefi::MEMEFI;
use memefi::roles::{Self, Roles, AdminRole, SafeManagerRole};
use sui::balance::{Self, Balance};
use sui::coin::Coin;
use sui::package::Publisher;

/// The maximum number of tokens that can be sent in one PTB.
const MAX_TOKEN_LIMIT: u64 = 5_000_000;

/// Tries to take a token of value bigger than the allowed limit in a PTB.
const ETokenLimitExceeded: u64 = 0;

/// [Shared] Safe for holding a `Balance<T>` with controlled access.
public struct Safe<phantom T> has key {
    id: UID,
    roles: Roles,
    balance: Balance<T>,
}

/// Helper configuration object for managing token limits in a transaction (PTB).
public struct TokenConfig has drop {
    max_token_limit: u64,
    tokens: u64,
}

/// Initializes a Safe to hold MEMEFI balance and assigns the sender as the initial admin
/// and Safe manager. The safe is shared on the network for further actions.
fun init(ctx: &mut TxContext) {
    let mut memefi_safe = Safe<MEMEFI> {
        id: object::new(ctx),
        roles: roles::new(ctx),
        balance: balance::zero<MEMEFI>(),
    };

    // Authorize the sender as the first admin of the safe.
    memefi_safe.roles_mut().authorize(roles::new_role<AdminRole>(ctx.sender()));

    // Authorize the sender as the initial safe manager.
    memefi_safe.roles_mut().authorize(roles::new_role<SafeManagerRole>(ctx.sender()));

    transfer::share_object(memefi_safe);
}

// === Public functions ===

/// Deposits the given MEMEFI coin into the safe.
/// The sender must have the `SafeManagerRole`.
public fun put<T: drop>(self: &mut Safe<T>, coin: Coin<T>, ctx: &mut TxContext) {
    // Ensure the sender is authorized with `SafeManagerRole`.
    self.roles().assert_has_role<SafeManagerRole>(ctx.sender());
    self.balance.join(coin.into_balance());
}

/// Take a `Coin` worth of `value` from `Safe` balance.
/// The sender must be authorised with the `SafeManagerRole`.
public fun take<T: drop>(
    self: &mut Safe<T>,
    value: u64,
    config: &mut TokenConfig,
    ctx: &mut TxContext,
): Coin<T> {
    // Ensure the sender is authorized with `SafeManagerRole`.
    self.roles().assert_has_role<SafeManagerRole>(ctx.sender());

    // Accumulate token amount in config and check max limit.
    config.update_token_config_amount(value);
    assert!(
        config.token_config_amount() <= config.token_config_max_limit(),
        ETokenLimitExceeded,
    );

    self.balance.split(value).into_coin(ctx)
}

/// Withdraw all balance from `Safe`.
/// The sender must be authorised with the `AdminRole`.
/// This is for extreme cases where the funds need to return to the treasury address.
public fun withdraw<T: drop>(self: &mut Safe<T>, ctx: &mut TxContext): Coin<T> {
    // Ensure the sender is authorized with `AdminRole`.
    self.roles().assert_has_role<AdminRole>(ctx.sender());

    // Withdraw all balance and wrap it into a coin.
    let safe_balance = self.balance.withdraw_all();
    safe_balance.into_coin(ctx)
}

// --- Authorize / Deauthorize Role functions ---

/// Publisher can authorize an address with the `AdminRole` in the `Safe<T>`.
public fun authorize_admin<T>(
    self: &mut Safe<T>,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().authorize(roles::new_role<AdminRole>(addr));
}

/// Publisher can authorize an address with the `AdminRole` in the `Safe<T>`.
public fun deauthorize_admin<T>(
    self: &mut Safe<T>,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().deauthorize(roles::new_role<AdminRole>(addr));
}

/// Publisher can authorize an address with the `SafeManagerRole` in the `Safe<T>`.
public fun authorize_manager<T>(
    self: &mut Safe<T>,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().authorize(roles::new_role<SafeManagerRole>(addr));
}

/// Publisher can authorize an address with the `SafeManagerRole` in the `Safe<T>`.
public fun deauthorize_manager<T>(
    self: &mut Safe<T>,
    pub: &Publisher,
    addr: address,
    _ctx: &mut TxContext,
) {
    roles::assert_publisher_from_package(pub);
    self.roles_mut().deauthorize(roles::new_role<SafeManagerRole>(addr));
}

// === Token limit management ===

/// Creates a temporary `TokenConfig` with a maximum token limit for the PTB.
/// This struct is used to keep track of the total tokens taken during the PTB.
public fun get_token_config(_ctx: &mut TxContext): TokenConfig {
    TokenConfig {
        max_token_limit: MAX_TOKEN_LIMIT,
        tokens: 0,
    }
}

public fun token_config_amount(self: &TokenConfig): u64 {
    self.tokens
}

public fun token_config_max_limit(self: &TokenConfig): u64 {
    self.max_token_limit
}

#[allow(lint(share_owned))]
public fun share<T>(self: Safe<T>) {
    transfer::share_object(self)
}

// === Accessors ===

/// Returns the `Safe` available balance left.
public fun balance<T>(self: &Safe<T>): u64 {
    self.balance.value()
}

// === Internal functions ===

public(package) fun new<T>(ctx: &mut TxContext): Safe<T> {
    Safe<T> {
        id: object::new(ctx),
        roles: roles::new(ctx),
        balance: balance::zero<T>(),
    }
}

/// Delete a `Safe` as long as the `Roles` are empty and balance is zero.
/// Aborts with `EBagNotEmpty` if the bag still contains values.
/// Aborts with `ENonZero` if balance still has a value.
public(package) fun delete<T>(self: Safe<T>, _ctx: &mut TxContext) {
    let Safe {
        id,
        roles,
        balance,
    } = self;

    roles.destroy_empty();
    balance.destroy_zero();
    id.delete();
}

/// Returns a mutable reference to the `Safe` Roles for internal modifications.
public(package) fun roles_mut<T>(self: &mut Safe<T>): &mut Roles {
    &mut self.roles
}

/// Returns a read-only reference to the `Safe` Roles.
public(package) fun roles<T>(self: &Safe<T>): &Roles {
    &self.roles
}

/// Returns a mutable reference to the `Safe` Balance for internal modifications.
public(package) fun balance_mut<T>(self: &mut Safe<T>): &mut Balance<T> {
    &mut self.balance
}

/// Updates the tokens value in hot potato.
public(package) fun update_token_config_amount(self: &mut TokenConfig, value: u64) {
    self.tokens = self.tokens + value
}

#[test_only]
public(package) fun test_init(ctx: &mut TxContext) {
    init(ctx);
}
