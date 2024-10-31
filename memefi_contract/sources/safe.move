module memefi::safe;

use memefi::memefi::MEMEFI;
use memefi::roles::{Self, Roles, AdminRole, SafeManagerRole};
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::package::Publisher;

/// The maximum limit of tokens that can be taken out of the `Safe` in one transaction.
const MAX_TOKEN_LIMIT: u64 = 50_000;

const EWrongPublisher: u64 = 1;
const EWithdrawNotAllowed: u64 = 2;

/// [Shared] Safe for holding a `Balance<T>` with controlled access.
public struct Safe<phantom T> has key {
    id: UID,
    roles: Roles,
    balance: Balance<T>,
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
    memefi_safe
        .roles_mut()
        .authorize<AdminRole>(roles::new_role<AdminRole>(ctx.sender()));

    // Authorize the sender as the initial safe manager.
    memefi_safe
        .roles_mut()
        .authorize<SafeManagerRole>(roles::new_role<SafeManagerRole>(ctx.sender()));

    transfer::share_object(memefi_safe);
}

// === Public functions ===

/// Deposits the given MEMEFI coin into the safe.
/// The sender must have the `SafeManagerRole`.
public fun put<T: drop>(self: &mut Safe<T>, coin: Coin<T>, ctx: &mut TxContext) {
    // Ensure the sender is authorized with `SafeManagerRole`.
    self.roles().assert_has_role<SafeManagerRole>(ctx.sender());

    coin::put<T>(&mut self.balance, coin);
}

/// Take a `Coin` worth of `value` from `Safe` balance.
/// The sender must be authorised with the `SafeManagerRole`.
public fun take<T: drop>(self: &mut Safe<T>, value: u64, ctx: &mut TxContext): Coin<T> {
    // Ensure the sender is authorized with `SafeManagerRole`.
    self.roles().assert_has_role<SafeManagerRole>(ctx.sender());

    // Abort if the value is greater than the allowed `MAX_TOKEN_LIMIT`.
    assert!(value <= MAX_TOKEN_LIMIT, EWithdrawNotAllowed);

    coin::take<T>(&mut self.balance, value, ctx)
}

/// Withdraw all balance from `Safe`.
/// The sender must be authorised with the `AdminRole`.
/// This is for extreme cases where the funds need to return to the treasury address.
public fun withdraw<T: drop>(self: &mut Safe<T>, ctx: &mut TxContext): Coin<T> {
    // Ensure the sender is authorized with `AdminRole`.
    self.roles().assert_has_role<AdminRole>(ctx.sender());

    // Withdraw all balance and wrap it into a coin.
    let safe_balance = self.balance.withdraw_all();
    coin::from_balance<T>(safe_balance, ctx)
}

// --- Authorize / Deauthorize Role functions ---

/// Publisher can authorize an address with the `AdminRole` in the `AirdropRegistry`.
public fun authorize_admin<T>(
    pub: &Publisher,
    safe: &mut Safe<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<AdminRole>(), EWrongPublisher);

    safe.roles_mut().authorize<AdminRole>(roles::new_role<AdminRole>(addr));
}

/// Publisher can authorize an address with the `AdminRole` in the `Safe<T>`.
public fun deauthorize_admin<T>(
    pub: &Publisher,
    safe: &mut Safe<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<AdminRole>(), EWrongPublisher);

    safe.roles_mut().deauthorize<AdminRole>(roles::new_role<AdminRole>(addr));
}

/// Publisher can authorize an address with the `SafeManagerRole` in the `Safe<T>`.
public fun authorize_manager<T>(
    pub: &Publisher,
    safe: &mut Safe<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<SafeManagerRole>(), EWrongPublisher);

    safe.roles_mut().authorize<SafeManagerRole>(roles::new_role<SafeManagerRole>(addr));
}

/// Publisher can authorize an address with the `SafeManagerRole` in the
/// `AirdropRegistry`.
public fun deauthorize_manager<T>(
    pub: &Publisher,
    safe: &mut Safe<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<SafeManagerRole>(), EWrongPublisher);

    safe.roles_mut().deauthorize<SafeManagerRole>(roles::new_role<SafeManagerRole>(addr));
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

#[test_only]
public(package) fun test_init(ctx: &mut TxContext) {
    init(ctx);
}
