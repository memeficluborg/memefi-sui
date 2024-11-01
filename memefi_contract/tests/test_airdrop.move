module memefi::test_airdrop;

use memefi::airdrop::{Self, AirdropRegistry, AirdropConfig};
use memefi::safe::Safe;
use memefi::test_memefi::{Self, TEST_MEMEFI};
use memefi::test_safe;
use memefi::treasury;
use std::string;
use sui::coin::{Self, Coin};
use sui::package::Publisher;
use sui::test_scenario::{Self as ts, Scenario};
use sui::test_utils;

const TOTAL_SUPPLY: u64 = 10_000_000_000_000_000_000;
const AIRDROP_AMOUNT: u64 = 1_000 * 1_000_000_000;
const USER_ID: vector<u8> = b"123userID";
const USER_ADDR: address = @0x3;

const ECannotAirdrop: u64 = 0;

#[test]
fun test_airdrop_registry_initialization() {
    let mut ctx = tx_context::dummy();
    airdrop::test_init(&mut ctx);
}

#[test]
fun test_new_airdrop() {
    let mut ts = ts::begin(@0x2);
    let airdrop_config = test_create_airdrop(&mut ts, @0x2);

    // Check that user actually received a token with value equal to AIRDROP_AMOUNT.
    ts.next_tx(USER_ADDR);
    let user_coin = ts.take_from_sender<Coin<TEST_MEMEFI>>();
    assert!(user_coin.value() == AIRDROP_AMOUNT);
    ts.return_to_sender(user_coin);

    // Check that Safe's balance is (TOTAL_SUPPLY - AIRDROP_AMOUNT)
    ts.next_tx(@0x2);
    let safe = ts.take_shared<Safe<TEST_MEMEFI>>();
    assert!(safe.balance<TEST_MEMEFI>() == TOTAL_SUPPLY - AIRDROP_AMOUNT);

    // Check that user is recorded after getting the airdrop.
    ts.next_tx(@0x2);
    let mut registry = ts.take_shared<AirdropRegistry>();
    assert!(airdrop::is_airdropped(&registry, string::utf8(USER_ID)));

    airdrop::finalize_send(&mut registry, airdrop_config, ts.ctx());

    ts::return_shared(registry);
    ts::return_shared(safe);
    ts.end();
}

#[test, expected_failure(abort_code = ECannotAirdrop)]
fun test_new_airdrop_without_finalize() {
    let mut ts = ts::begin(@0x2);
    let _airdrop_config = test_create_airdrop(&mut ts, @0x2);

    // Check that user actually received a token with value equal to AIRDROP_AMOUNT.
    ts.next_tx(USER_ADDR);
    let user_coin = ts.take_from_sender<Coin<TEST_MEMEFI>>();
    assert!(user_coin.value() == AIRDROP_AMOUNT);
    ts.return_to_sender(user_coin);

    // Check that Safe's balance is (TOTAL_SUPPLY - AIRDROP_AMOUNT)
    ts.next_tx(@0x2);
    let safe = ts.take_shared<Safe<TEST_MEMEFI>>();
    assert!(safe.balance<TEST_MEMEFI>() == TOTAL_SUPPLY - AIRDROP_AMOUNT);

    // Check that user is recorded after getting the airdrop.
    ts.next_tx(@0x2);
    let registry = ts.take_shared<AirdropRegistry>();
    assert!(airdrop::is_airdropped(&registry, string::utf8(USER_ID)));

    abort 0
}

#[test, expected_failure(abort_code = ::memefi::airdrop::EAlreadyAirdropped)]
fun airdrop_twice() {
    let mut ts = ts::begin(@0x2);
    let mut airdrop_config = test_create_airdrop(&mut ts, @0x2);

    ts.next_tx(@0x2);
    let mut safe = ts.take_shared<Safe<TEST_MEMEFI>>();
    let mut registry = ts.take_shared<AirdropRegistry>();

    airdrop::send_token(
        &mut safe,
        AIRDROP_AMOUNT,
        string::utf8(USER_ID),
        USER_ADDR,
        &mut registry,
        &mut airdrop_config,
        ts.ctx(),
    );

    registry.finalize_send(airdrop_config, ts.ctx());
    ts::return_shared(registry);
    ts::return_shared(safe);
    ts.end();
}

#[test_only]
public fun test_create_airdrop(ts: &mut Scenario, admin: address): AirdropConfig {
    ts.next_tx(admin);
    let mut treasury_cap = test_memefi::create_test_treasury(ts.ctx());
    airdrop::test_init(ts.ctx());

    ts.next_tx(admin);
    test_safe::create_test_safe<TEST_MEMEFI>(ts, admin);
    let publisher = ts.take_from_sender<Publisher>();

    // Mint the total supply of `MEMEFI` tokens and send the whole supply to admin.
    ts.next_tx(admin);
    let balance = treasury_cap.mint_balance(TOTAL_SUPPLY);
    let coin = coin::from_balance(balance, ts.ctx());

    ts.next_tx(admin);
    let mut safe = ts.take_shared<Safe<TEST_MEMEFI>>();
    safe.put<TEST_MEMEFI>(coin, &publisher);

    let wrapped_treasury = treasury::wrap(treasury_cap, ts.ctx());

    ts.next_tx(admin);
    let mut registry = ts.take_shared<AirdropRegistry>();
    registry.authorize_api(&publisher, admin, ts.ctx());

    ts.next_tx(admin);
    let mut airdrop_config = registry.init_send(ts.ctx());

    airdrop::send_token(
        &mut safe,
        AIRDROP_AMOUNT,
        string::utf8(USER_ID),
        USER_ADDR,
        &mut registry,
        &mut airdrop_config,
        ts.ctx(),
    );

    ts.next_tx(admin);
    ts::return_shared(registry);
    ts::return_to_sender(ts, publisher);
    test_utils::destroy(wrapped_treasury);
    ts::return_shared(safe);

    airdrop_config
}
