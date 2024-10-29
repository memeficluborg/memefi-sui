module memefi::test_airdrop;

use memefi::airdrop::{Self, AirdropRegistry};
use memefi::roles::{Self, AdminRole, FreezerRole, VaultManagerRole};
use memefi::test_memefi::{Self, TEST_MEMEFI};
use memefi::treasury;
use memefi::vault::{Self, Vault};
use std::string;
use sui::coin::{Self, Coin};
use sui::package::Publisher;
use sui::test_scenario::{Self as ts, Scenario};
use sui::test_utils;

const TOTAL_SUPPLY: u64 = 10_000_000_000;
const AIRDROP_AMOUNT: u64 = 1_000;
const USER_ID: vector<u8> = b"123userID";
const USER_ADDR: address = @0x3;

#[test]
fun test_airdrop_registry_initialization() {
    let mut ctx = tx_context::dummy();
    airdrop::test_init(&mut ctx);
}

#[test]
fun test_admin_is_authorized_in_airdrop_registry() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let registry = ts::take_shared<AirdropRegistry>(&ts);

    // Verify that @0x2 is an admin and a freezer
    assert!(registry.roles().is_authorized<AdminRole>(@0x2));
    assert!(registry.roles().is_authorized<FreezerRole>(@0x2));

    test_utils::destroy(registry);
    ts::end(ts);
}

#[test]
fun test_new_airdrop() {
    let mut ts = ts::begin(@0x2);
    test_create_airdrop(&mut ts, @0x2);

    // Check that user actually received a token with value equal to AIRDROP_AMOUNT.
    ts::next_tx(&mut ts, USER_ADDR);
    let user_coin = ts::take_from_sender<Coin<TEST_MEMEFI>>(&ts);
    assert!(user_coin.value() == AIRDROP_AMOUNT);
    ts::return_to_sender(&ts, user_coin);

    // Check that Vault's balance is (TOTAL_SUPPLY - AIRDROP_AMOUNT)
    ts::next_tx(&mut ts, @0x2);
    let vault = ts::take_shared<Vault<TEST_MEMEFI>>(&ts);
    assert!(vault.balance<TEST_MEMEFI>() == TOTAL_SUPPLY - AIRDROP_AMOUNT);

    // Check that user is in denylist after getting the airdrop.
    ts::next_tx(&mut ts, @0x2);
    let registry = ts::take_shared<AirdropRegistry>(&ts);
    assert!(airdrop::is_airdropped(&registry, string::utf8(USER_ID)));

    ts::return_shared(registry);
    ts::return_shared(vault);
    ts::end(ts);
}

#[test, expected_failure(abort_code = ::memefi::airdrop::EAlreadyAirdropped)]
fun airdrop_twice() {
    let mut ts = ts::begin(@0x2);
    test_create_airdrop(&mut ts, @0x2);

    ts::next_tx(&mut ts, @0x2);
    let mut vault = ts::take_shared<Vault<TEST_MEMEFI>>(&ts);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);

    airdrop::new(
        &mut vault,
        AIRDROP_AMOUNT,
        string::utf8(USER_ID),
        USER_ADDR,
        &mut registry,
        ts.ctx(),
    );

    ts::return_shared(registry);
    ts::return_shared(vault);
    ts::end(ts);
}

#[test]
fun test_freeze() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);
    airdrop::freeze_user(&mut registry, string::utf8(USER_ID), ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    assert!(airdrop::is_airdropped(&registry, string::utf8(USER_ID)));

    ts::return_shared(registry);
    ts::end(ts);
}

#[test, expected_failure(abort_code = ::sui::dynamic_field::EFieldAlreadyExists)]
fun test_freeze_twice() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);
    airdrop::freeze_user(&mut registry, string::utf8(USER_ID), ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    airdrop::freeze_user(&mut registry, string::utf8(USER_ID), ts.ctx());

    ts::return_shared(registry);
    ts::end(ts);
}

#[test]
fun test_freeze_unfreeze() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);
    airdrop::freeze_user(&mut registry, string::utf8(USER_ID), ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    assert!(airdrop::is_airdropped(&registry, string::utf8(USER_ID)));

    ts::next_tx(&mut ts, @0x2);
    airdrop::unfreeze_user(&mut registry, string::utf8(USER_ID), ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    assert!(!airdrop::is_airdropped(&registry, string::utf8(USER_ID)));

    ts::return_shared(registry);
    ts::end(ts);
}

#[test]
fun test_freezer_role_can_freeze() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let publisher = ts::take_from_sender<Publisher>(&ts);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);

    airdrop::authorize_freezer(&publisher, &mut registry, @0x5, ts.ctx());

    ts::next_tx(&mut ts, @0x5);
    airdrop::freeze_user(&mut registry, string::utf8(USER_ID), ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    ts::return_shared(registry);
    ts::return_to_sender(&ts, publisher);
    ts::end(ts);
}

#[test, expected_failure(abort_code = ::memefi::roles::EUnauthorizedUser)]
fun test_non_freezer_role_cannot_freeze() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let publisher = ts::take_from_sender<Publisher>(&ts);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);

    airdrop::authorize_admin(&publisher, &mut registry, @0x5, ts.ctx());

    ts::next_tx(&mut ts, @0x5);
    airdrop::freeze_user(&mut registry, string::utf8(USER_ID), ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    ts::return_shared(registry);
    ts::return_to_sender(&ts, publisher);
    ts::end(ts);
}

#[test_only]
public fun test_create_airdrop(ts: &mut Scenario, admin: address) {
    ts::next_tx(ts, admin);
    let mut treasury_cap = test_memefi::create_test_treasury(ts.ctx());
    airdrop::test_init(ts.ctx());

    ts::next_tx(ts, admin);
    let mut vault = vault::new<TEST_MEMEFI>(ts.ctx());
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

    // Mint the total supply of `MEMEFI` tokens and send the whole supply to admin.
    ts::next_tx(ts, admin);
    let balance = treasury_cap.mint_balance(TOTAL_SUPPLY);
    let coin = coin::from_balance(balance, ts.ctx());

    ts::next_tx(ts, admin);
    let mut vault = ts::take_shared<Vault<TEST_MEMEFI>>(ts);
    vault.put<TEST_MEMEFI>(coin, ts.ctx());

    let wrapped_treasury = treasury::wrap(treasury_cap, ts.ctx());

    ts::next_tx(ts, admin);
    let mut registry = ts::take_shared<AirdropRegistry>(ts);

    airdrop::new(
        &mut vault,
        AIRDROP_AMOUNT,
        string::utf8(USER_ID),
        USER_ADDR,
        &mut registry,
        ts.ctx(),
    );

    ts::next_tx(ts, admin);
    ts::return_shared(registry);
    test_utils::destroy(wrapped_treasury);
    ts::return_shared(vault);
}
