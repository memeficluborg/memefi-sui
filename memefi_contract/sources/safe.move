/// This module provides a secure container, the `Safe`, for holding MEMEFI token balance
/// Allows `Publisher` to deposit and withdraw tokens.
module memefi::safe;

use memefi::memefi::MEMEFI;
use memefi::roles;
use sui::balance::{Self, Balance};
use sui::coin::Coin;
use sui::package::Publisher;

/// [Shared] Safe for holding a `Balance<T>` with controlled access.
public struct Safe<phantom T> has key {
    id: UID,
    balance: Balance<T>,
}

/// Initializes a Safe to hold MEMEFI balance. The safe is shared on the network for
/// further actions.
fun init(ctx: &mut TxContext) {
    let memefi_safe = Safe<MEMEFI> {
        id: object::new(ctx),
        balance: balance::zero<MEMEFI>(),
    };

    transfer::share_object(memefi_safe);
}

// === Public functions ===

/// Deposits the given MEMEFI coin into the safe.
public fun put<T: drop>(self: &mut Safe<T>, coin: Coin<T>, pub: &Publisher) {
    // Ensure the sender holds a valid `Publisher`.
    roles::assert_publisher_from_package(pub);
    self.balance.join(coin.into_balance());
}

/// Withdraw all balance from `Safe`.
/// This is for extreme cases where the funds need to return to the treasury address.
public fun withdraw<T: drop>(
    self: &mut Safe<T>,
    pub: &Publisher,
    ctx: &mut TxContext,
): Coin<T> {
    // Ensure the sender holds a valid `Publisher`.
    roles::assert_publisher_from_package(pub);

    // Withdraw all balance and wrap it into a coin.
    self.balance.withdraw_all().into_coin(ctx)
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
        balance: balance::zero<T>(),
    }
}

/// Delete a `Safe` as long as the balance is zero.
/// - Aborts with `ENonZero` if balance still has a value.
public(package) fun delete<T>(self: Safe<T>, _ctx: &mut TxContext) {
    let Safe {
        id,
        balance,
    } = self;

    balance.destroy_zero();
    id.delete();
}

/// Returns a mutable reference to the `Safe` Balance for internal modifications.
public(package) fun balance_mut<T>(self: &mut Safe<T>): &mut Balance<T> {
    &mut self.balance
}

#[test_only]
public(package) fun test_init(ctx: &mut TxContext) {
    init(ctx);
}
