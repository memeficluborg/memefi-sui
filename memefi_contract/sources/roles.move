/// This module defines a role-based permission system for the MemeFi project. It allows
/// for flexible and dynamic role assignment, supporting multiple roles such as admins and
/// managers. Each role can have specific permissions, managed through a `Roles` struct
/// that stores active roles and tracks the number of admins.
///
/// Key points:
/// - AdminRole: Core role responsible for managing other roles. At least one
/// administrator must always be present.
/// - Role Authorization: Roles can be assigned to specific addresses. Admins can
/// authorize or deauthorize roles as needed. Roles can only be active or inactive,
/// managed directly through authorization.
module memefi::roles;

use std::type_name;
use sui::bag::{Self, Bag};
use sui::package::Publisher;

/// Tries to remove the last admin.
const ECannotRemoveLastAdmin: u64 = 1;
/// Tries to authorize a role that already exists.
const ERoleAlreadyExists: u64 = 2;
/// Tries to authenticate to a role that is not authorized.
const EUnauthorizedUser: u64 = 3;
/// Tries to deauthorize a role that does not exist.
const ERoleNotExists: u64 = 4;
/// Publisher is not originating from this package.
const EWrongPublisher: u64 = 5;

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

/// `AdminRole` is the top-level administrative role, managing other roles and authorizing
/// high-impact actions.
public struct AdminRole {}

/// `SafeManagerRole` focuses on managing the `Safe`, with permissions to perform balance
/// adjustments or routine transfers.
public struct SafeManagerRole {}

// === Internal functions ===

/// Initializes and returns a new `Roles` struct.
public(package) fun new(ctx: &mut TxContext): Roles {
    Roles { data: bag::new(ctx), admin_count: 0 }
}

/// Creates a new role instance for the specified address.
public(package) fun new_role<T>(addr: address): Role<T> {
    Role { addr }
}

/// Authorizes a new role. If the role is `AdminRole`, increments the `admin_count`.
/// - Raises `ERoleAlreadyExists` if the role is already authorized.
public(package) fun authorize<T>(roles: &mut Roles, role: Role<T>) {
    // Prevent the same role (role <> address) from being authorized twice.
    assert!(!roles.data.contains(role), ERoleAlreadyExists);

    if (type_name::get<T>() == type_name::get<AdminRole>()) {
        roles.admin_count = roles.admin_count + 1;
    };

    roles.data.add(role, true);
}

/// Deauthorizes an existing role. If the role is `AdminRole`, decrements the
/// `admin_count`.
/// - Raises `ERoleNotExists` if the role does not exist.
/// - Raises `ECannotRemoveLastAdmin` if attempting to remove the last administrator.
public(package) fun deauthorize<T>(roles: &mut Roles, role: Role<T>): bool {
    assert!(roles.data.contains(role), ERoleNotExists);

    if (type_name::get<T>() == type_name::get<AdminRole>()) {
        roles.admin_count = roles.admin_count - 1;
        assert!(roles.admin_count > 0, ECannotRemoveLastAdmin)
    };

    roles.data.remove(role)
}

/// Checks if the given address is authorized for a specific role.
public(package) fun is_authorized<R>(roles: &Roles, addr: address): bool {
    let role = Role<R> { addr };
    roles.data.contains(role)
}

/// Returns a reference to the configuration of the specified role.
public(package) fun config<R, V: store + drop>(roles: &Roles, addr: address): &V {
    roles.data.borrow(Role<R> { addr })
}

/// Asserts that the specified address is authorized for a given role.
/// Raises `EUnauthorizedUser` if the address is not authorized.
public(package) fun assert_has_role<R>(roles: &Roles, addr: address) {
    assert!(is_authorized<R>(roles, addr), EUnauthorizedUser);
}

/// Asserts that the given `Publisher` is indeed coming from current package.
public(package) fun assert_publisher_from_package(self: &Publisher) {
    assert!(self.from_package<AdminRole>(), EWrongPublisher);
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
public(package) fun addr<R>(role: &Role<R>): address {
    role.addr
}

/// Destroy the `Roles` bag if it's empty.
public(package) fun destroy_empty(roles: Roles) {
    let Roles { data, .. } = roles;
    data.destroy_empty()
}
