module memefi::vault;

use memefi::memefi::MEMEFI;
use memefi::roles::{Self, Roles, AdminRole, VaultManagerRole};
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::package::Publisher;

const EWrongPublisher: u64 = 1;

/// [Shared] Vault for holding a `Balance<T>` with controlled access.
public struct Vault<phantom T> has key {
    id: UID,
    roles: Roles,
    balance: Balance<T>,
}

/// Initializes a Vault to hold MEMEFI balance and assigns the sender as the initial admin
/// and Vault manager. The vault is shared on the network for further actions.
fun init(ctx: &mut TxContext) {
    let mut memefi_vault = Vault<MEMEFI> {
        id: object::new(ctx),
        roles: roles::new(ctx),
        balance: balance::zero<MEMEFI>(),
    };

    // Authorize the sender as the first admin of the vault.
    memefi_vault
        .roles_mut()
        .authorize<AdminRole, _>(
            roles::new_role<AdminRole>(ctx.sender()),
            true,
        );

    // Authorize the sender as the initial vault manager.
    memefi_vault
        .roles_mut()
        .authorize<VaultManagerRole, _>(
            roles::new_role<VaultManagerRole>(ctx.sender()),
            true,
        );

    transfer::share_object(memefi_vault);
}

// === Public functions ===

/// Deposits the given MEMEFI coin into the vault.
/// The sender must have the `VaultManagerRole`.
public fun put<T: drop>(self: &mut Vault<T>, coin: Coin<T>, ctx: &mut TxContext) {
    // Ensure the sender is authorized with `VaultManagerRole`.
    self.roles().assert_is_authorized<VaultManagerRole>(ctx.sender());

    coin::put<T>(&mut self.balance, coin);
}

/// Take a `Coin` worth of `value` from `Vault` balance.
/// The sender must be authorised with the `VaultManagerRole`.
public fun take<T: drop>(self: &mut Vault<T>, value: u64, ctx: &mut TxContext): Coin<T> {
    // Ensure the sender is authorized with `VaultManagerRole`.
    self.roles().assert_is_authorized<VaultManagerRole>(ctx.sender());

    coin::take<T>(&mut self.balance, value, ctx)
}

// --- Authorize / Deauthorize Role functions ---

/// Publisher can authorize an address with the `AdminRole` in the `AirdropRegistry`.
public fun authorize_admin<T>(
    pub: &Publisher,
    vault: &mut Vault<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<AdminRole>(), EWrongPublisher);

    vault
        .roles_mut()
        .authorize<AdminRole, _>(
            roles::new_role<AdminRole>(addr),
            true,
        );
}

/// Publisher can authorize an address with the `AdminRole` in the `Vault<T>`.
public fun deauthorize_admin<T>(
    pub: &Publisher,
    vault: &mut Vault<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<AdminRole>(), EWrongPublisher);

    vault
        .roles_mut()
        .deauthorize<AdminRole, bool>(
            roles::new_role<AdminRole>(addr),
        );
}

/// Publisher can authorize an address with the `VaultManagerRole` in the `Vault<T>`.
public fun authorize_manager<T>(
    pub: &Publisher,
    vault: &mut Vault<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<VaultManagerRole>(), EWrongPublisher);

    vault
        .roles_mut()
        .authorize<VaultManagerRole, _>(
            roles::new_role<VaultManagerRole>(addr),
            true,
        );
}

/// Publisher can authorize an address with the `VaultManagerRole` in the
/// `AirdropRegistry`.
public fun deauthorize_manager<T>(
    pub: &Publisher,
    vault: &mut Vault<T>,
    addr: address,
    _ctx: &mut TxContext,
) {
    assert!(pub.from_package<VaultManagerRole>(), EWrongPublisher);

    vault
        .roles_mut()
        .deauthorize<VaultManagerRole, bool>(
            roles::new_role<VaultManagerRole>(addr),
        );
}

#[allow(lint(share_owned))]
public fun share<T>(self: Vault<T>) {
    transfer::share_object(self)
}

// === Accessors ===

/// Returns the `Vault` available balance left.
public fun balance<T>(self: &Vault<T>): u64 {
    self.balance.value()
}

// === Internal functions ===

public(package) fun new<T>(ctx: &mut TxContext): Vault<T> {
    Vault<T> {
        id: object::new(ctx),
        roles: roles::new(ctx),
        balance: balance::zero<T>(),
    }
}

/// Returns a mutable reference to the `Vault` Roles for internal modifications.
public(package) fun roles_mut<T>(self: &mut Vault<T>): &mut Roles {
    &mut self.roles
}

/// Returns a read-only reference to the `Vault` Roles.
public(package) fun roles<T>(self: &Vault<T>): &Roles {
    &self.roles
}

/// Returns a mutable reference to the `Vault` Balance for internal modifications.
public(package) fun balance_mut<T>(self: &mut Vault<T>): &mut Balance<T> {
    &mut self.balance
}

#[test_only]
public(package) fun test_init(ctx: &mut TxContext) {
    init(ctx);
}
