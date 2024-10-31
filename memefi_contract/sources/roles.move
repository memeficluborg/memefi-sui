/// This module defines a role-based permission system for the MemeFi project. It allows
/// for flexible and dynamic role assignment. Each role can have specific permissions,
/// managed through a `Roles` struct that stores active roles.
///
/// Key points:
/// - ApiRole: Core role responsible for token distribution and management.
/// - Role Authorization: Roles can be assigned to specific addresses. `Publisher` can
/// authorize or deauthorize roles as needed. Roles can only be active or inactive,
/// managed directly through authorization.
module memefi::roles;

use memefi::memefi::MEMEFI;
use sui::bag::{Self, Bag};
use sui::package::Publisher;

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
public struct Roles has store {
    data: Bag,
}

/// The `Role` struct represents a role with a generic type `T`, containing the address
/// that is authorized to perform certain actions.
public struct Role<phantom T> has copy, store, drop {
    addr: address,
}

/// `ApiRole` is the main role to be given at a trusted service.
public struct ApiRole {}

// === Internal functions ===

/// Initializes and returns a new `Roles` struct.
public(package) fun new(ctx: &mut TxContext): Roles {
    Roles { data: bag::new(ctx) }
}

/// Creates a new role instance for the specified address.
public(package) fun new_role<T>(addr: address): Role<T> {
    Role { addr }
}

/// Authorizes a new role.
/// - Raises `ERoleAlreadyExists` if the role is already authorized.
public(package) fun authorize<T>(roles: &mut Roles, role: Role<T>) {
    // Prevent the same role (role <> address) from being authorized twice.
    assert!(!roles.data.contains(role), ERoleAlreadyExists);
    roles.data.add(role, true);
}

/// Deauthorizes an existing role.
/// - Raises `ERoleNotExists` if the role does not exist.
public(package) fun deauthorize<T>(roles: &mut Roles, role: Role<T>): bool {
    assert!(roles.data.contains(role), ERoleNotExists);
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
/// - Raises `EUnauthorizedUser` if the address is not authorized.
public(package) fun assert_has_role<R>(roles: &Roles, addr: address) {
    assert!(is_authorized<R>(roles, addr), EUnauthorizedUser);
}

/// Asserts that the given `Publisher` is indeed coming from current package.
public(package) fun assert_publisher_from_package(self: &Publisher) {
    assert!(self.from_package<MEMEFI>(), EWrongPublisher);
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
