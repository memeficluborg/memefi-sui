module memefi::roles;

use std::type_name;
use sui::bag::{Self, Bag};

/// Tries to remove the last admin.
const ECannotRemoveLastAdmin: u64 = 1;
/// Tries to authorize a role that already exists.
const ERoleAlreadyExists: u64 = 2;
/// Tries to authenticate to a role that is not authorized.
const EUnauthorizedUser: u64 = 3;
/// Tries to authenticate a role which is paused.
const ERolePaused: u64 = 4;
/// Tries to pause a role that is already paused.
const EAlreadyPaused: u64 = 5;
/// Tries to unpause a role that is already unpaused.
const EAlreadyUnpaused: u64 = 6;
/// Tries to deauthorize a role that does not exist.
const ERoleNotExists: u64 = 7;
const ECannotPauseAdmin: u64 = 8;

/// The `Roles` struct is generic and uses a `Bag` to store different roles and their
/// configurations. This allows adding more roles in the future without changing the
/// `Roles` struct.
///
/// The `admin_count` field tracks the number of administrators to ensure that the last
/// admin is never removed.
public struct Roles has store {
    data: Bag,
    admin_count: u8,
}

/// The `Role` struct represents a role with a generic type `T`, containing the address
/// that is authorized to perform certain actions.
public struct Role<phantom T> has copy, store, drop {
    addr: address,
}

/// The `Pause` struct is used to indicate that a specific role `T` is paused.
public struct Pause<phantom T>() has copy, store, drop;

/// Core administrative role which can authorize and deauthorize other roles.
public struct AdminRole() has drop;

/// Represents a role responsible for freezing or unfreezing users.
public struct FreezerRole() has drop;

/// Represents a role that can manage a `Vault`.
public struct VaultManagerRole() has drop;

// === Internal functions ===

/// Initializes and returns a new `Roles` struct.
public(package) fun new(ctx: &mut TxContext): Roles {
    Roles { data: bag::new(ctx), admin_count: 0 }
}

/// Creates a new role instance for the specified address.
public(package) fun new_role<T: drop>(addr: address): Role<T> {
    Role { addr }
}

/// Authorizes a new role and stores the corresponding configuration `value`. If the role
/// is `AdminRole`, increments the `admin_count`.
/// Raises `ERoleAlreadyExists` if the role is already authorized.
public(package) fun authorize<T: drop, V: store + drop>(
    roles: &mut Roles,
    role: Role<T>,
    value: V,
) {
    // Prevent the same role (role <> address) from being authorized twice.
    assert!(!roles.data.contains(role), ERoleAlreadyExists);

    if (type_name::get<T>() == type_name::get<AdminRole>()) {
        roles.admin_count = roles.admin_count + 1;
    };

    roles.data.add(role, value)
}

/// Deauthorizes an existing role and returns its configuration. If the role is
/// `AdminRole`, decrements the `admin_count`.
/// Raises `ERoleNotExists` if the role does not exist.
/// Raises `ECannotRemoveLastAdmin` if attempting to remove the last administrator.
public(package) fun deauthorize<T: drop, V: store + drop>(
    roles: &mut Roles,
    role: Role<T>,
): V {
    assert!(roles.data.contains_with_type<_, V>(role), ERoleNotExists);
    if (type_name::get<T>() == type_name::get<AdminRole>()) {
        roles.admin_count = roles.admin_count - 1;
        assert!(roles.admin_count > 0, ECannotRemoveLastAdmin)
    };

    roles.data.remove(role)
}

/// Checks if the given address is authorized for the specified role.
public(package) fun is_authorized<R: drop>(roles: &Roles, addr: address): bool {
    let role = Role<R> { addr };
    roles.data.contains(role)
}

/// Pauses a specified role.
/// Raises `EAlreadyPaused` if the role is already paused.
/// Raises `ECannotPauseAdmin` if attempting to pause the admin role.
public(package) fun pause<R: drop>(roles: &mut Roles) {
    assert!(!roles.is_paused<R>(), EAlreadyPaused);

    // Prevent pausing AdminRole
    assert!(type_name::get<R>() != type_name::get<AdminRole>(), ECannotPauseAdmin);
    roles.data.add(Pause<R>(), true);
}

/// Unpauses a specified role.
/// Raises `EAlreadyUnpaused` if the role is not currently paused.
public(package) fun unpause<R: drop>(roles: &mut Roles) {
    assert!(roles.is_paused<R>(), EAlreadyUnpaused);
    roles.data.remove<_, bool>(Pause<R>());
}

/// Checks if a specified role is paused.
public(package) fun is_paused<R: drop>(roles: &Roles): bool {
    // TODO: Should we allow pausing admin roles? My guess is no!
    roles.data.contains(Pause<R>())
}

/// Returns a reference to the configuration of the specified role.
public(package) fun config<R: drop, V: store + drop>(roles: &Roles, addr: address): &V {
    roles.data.borrow(Role<R> { addr })
}

/// Returns a mutable reference to the configuration of the specified role.
public(package) fun config_mut<R: drop, V: store + drop>(
    roles: &mut Roles,
    addr: address,
): &mut V {
    roles.data.borrow_mut(Role<R> { addr })
}

/// Asserts that the specified address is authorized for a given role.
/// Raises `EUnauthorizedUser` if the address is not authorized.
public(package) fun assert_is_authorized<R: drop>(roles: &Roles, addr: address) {
    assert!(is_authorized<R>(roles, addr), EUnauthorizedUser);
}

/// Asserts that a specified role is not paused.
/// Raises `ERolePaused` if the role is paused.
public(package) fun assert_is_not_paused<T: drop>(roles: &Roles) {
    assert!(!is_paused<T>(roles), ERolePaused);
}

/// Returns the current count of administrators in the system.
public(package) fun admin_count(roles: &Roles): u8 {
    roles.admin_count
}

/// Returns a reference to the underlying `Bag` storing the roles.
public(package) fun data(roles: &Roles): &Bag {
    &roles.data
}

/// Returns the address associated with the given role
public(package) fun addr<R: drop>(role: &Role<R>): address {
    role.addr
}
