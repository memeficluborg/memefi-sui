module memefi::test_vault;

use memefi::memefi::MEMEFI;
use memefi::roles::{Self, AdminRole, VaultManagerRole};
use memefi::test_memefi::{Self, TEST_MEMEFI};
use memefi::vault::{Self, Vault};
use sui::coin;
use sui::test_scenario::{Self as ts, Scenario};
use sui::test_utils;

/// Total supply of MEMEFI for testing.
const TOTAL_SUPPLY: u64 = 1_000_000_000;

/// The maximum limit of tokens that can be taken out of the `Vault` in one transaction.
const MAX_TOKEN_LIMIT: u64 = 50_000;

#[test]
fun test_vault_init() {
    let mut ts = ts::begin(@0x2);
    let vault = vault::new<MEMEFI>(ts.ctx());

    // Verify that the Vault is initialized correctly.
    assert!(vault.balance() == 0);
    assert!(vault.roles().admin_count() == 0);

    test_utils::destroy(vault);
    ts::end(ts);
}

#[test]
fun test_deposit() {
    let mut ts = ts::begin(@0x2);
    setup_test_vault_with_currency(&mut ts, @0x2);

    // Mint the total supply of `MEMEFI` tokens and send the whole supply to admin.
    ts::next_tx(&mut ts, @0x2);
    let vault = ts::take_shared<Vault<TEST_MEMEFI>>(&ts);
    assert!(vault.balance() == TOTAL_SUPPLY);

    ts::return_shared(vault);
    ts::end(ts);
}

#[test]
fun test_take() {
    let mut ts = ts::begin(@0x2);
    setup_test_vault_with_currency(&mut ts, @0x2);

    ts::next_tx(&mut ts, @0x2);
    let mut vault = ts::take_shared<Vault<TEST_MEMEFI>>(&ts);

    // Take some of the balance out.
    ts::next_tx(&mut ts, @0x2);
    let takeout_coin = vault.take<TEST_MEMEFI>(5_000, ts.ctx());

    // Verify the withdrawn amount and remaining balance.
    assert!(takeout_coin.value() == 5_000);
    assert!(vault.balance() == TOTAL_SUPPLY - 5_000);

    test_utils::destroy(takeout_coin);
    ts::return_shared(vault);
    ts::end(ts);
}

#[test, expected_failure(abort_code = ::memefi::vault::EWithdrawNotAllowed)]
fun test_take_more_than_allowed() {
    let mut ts = ts::begin(@0x2);
    setup_test_vault_with_currency(&mut ts, @0x2);

    ts::next_tx(&mut ts, @0x2);
    let mut vault = ts::take_shared<Vault<TEST_MEMEFI>>(&ts);

    // Take some of the balance out.
    ts::next_tx(&mut ts, @0x2);
    let takeout_coin = vault.take<TEST_MEMEFI>(MAX_TOKEN_LIMIT + 1, ts.ctx());

    test_utils::destroy(takeout_coin);
    ts::return_shared(vault);
    ts::end(ts);
}

#[test]
fun test_withdraw() {
    let mut ts = ts::begin(@0x2);
    setup_test_vault_with_currency(&mut ts, @0x2);

    // Withdraw all of the balance.
    ts::next_tx(&mut ts, @0x2);
    let mut vault = ts::take_shared<Vault<TEST_MEMEFI>>(&ts);
    let withdraw_coin = vault.withdraw<TEST_MEMEFI>(ts.ctx());

    // Verify the withdrawn amount and remaining balance.
    assert!(withdraw_coin.value() == TOTAL_SUPPLY);
    assert!(vault.balance() == 0);

    test_utils::destroy(withdraw_coin);
    ts::return_shared(vault);
    ts::end(ts);
}

/// In order to succesfully delete the vault we must expost a way to delete the last admin
/// from the Roles, which we don't want to do that yet.
#[test, expected_failure(abort_code = ::memefi::roles::ECannotRemoveLastAdmin)]
fun test_delete_vault() {
    let mut ts = ts::begin(@0x2);
    setup_test_vault_with_currency(&mut ts, @0x2);

    // Withdraw all of the balance.
    ts::next_tx(&mut ts, @0x2);
    let mut vault = ts::take_shared<Vault<TEST_MEMEFI>>(&ts);
    let full_withdrawn_coin = vault.withdraw<TEST_MEMEFI>(ts.ctx());
    assert!(full_withdrawn_coin.value() == TOTAL_SUPPLY);

    // Deauthorize the roles to make the bag empty.
    vault
        .roles_mut()
        .deauthorize<VaultManagerRole, bool>(
            memefi::roles::new_role<VaultManagerRole>(@0x2),
        );
    vault
        .roles_mut()
        .deauthorize<AdminRole, bool>(
            memefi::roles::new_role<AdminRole>(@0x2),
        );

    // Delete the vault.
    vault.delete(ts.ctx());
    test_utils::destroy(full_withdrawn_coin);
    ts::end(ts);
}

#[test_only]
public(package) fun create_test_vault_with_admin<T>(ts: &mut Scenario, admin: address) {
    ts::next_tx(ts, admin);
    let mut vault = vault::new<T>(ts.ctx());

    vault
        .roles_mut()
        .authorize<AdminRole, _>(
            roles::new_role<AdminRole>(admin),
            true,
        );

    vault
        .roles_mut()
        .authorize<VaultManagerRole, _>(
            roles::new_role<VaultManagerRole>(admin),
            true,
        );

    vault.share();
}

#[test_only]
public(package) fun setup_test_vault_with_currency(ts: &mut Scenario, admin: address) {
    ts::next_tx(ts, admin);
    create_test_vault_with_admin<TEST_MEMEFI>(ts, admin);
    let mut treasury_cap = test_memefi::create_test_treasury(ts.ctx());

    ts::next_tx(ts, admin);
    let mut vault = ts::take_shared<Vault<TEST_MEMEFI>>(ts);
    let balance = treasury_cap.mint_balance(TOTAL_SUPPLY);
    let coin = coin::from_balance(balance, ts.ctx());
    vault.put<TEST_MEMEFI>(coin, ts.ctx());

    test_utils::destroy(treasury_cap);
    ts::return_shared(vault);
}
