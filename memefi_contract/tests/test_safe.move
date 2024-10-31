module memefi::test_safe;

use memefi::airdrop;
use memefi::memefi::MEMEFI;
use memefi::safe::{Self, Safe};
use memefi::test_memefi::{Self, TEST_MEMEFI};
use sui::coin;
use sui::package::Publisher;
use sui::test_scenario::{Self as ts, Scenario};
use sui::test_utils;

/// Total supply of MEMEFI for testing.
const TOTAL_SUPPLY: u64 = 1_000_000_000;

#[test]
fun test_safe_init() {
    let mut ts = ts::begin(@0x2);
    let safe = safe::new<MEMEFI>(ts.ctx());
    assert!(safe.balance() == 0);
    test_utils::destroy(safe);
    ts::end(ts);
}

#[test]
fun test_deposit() {
    let mut ts = ts::begin(@0x2);
    setup_test_safe_with_currency(&mut ts, @0x2);

    ts::next_tx(&mut ts, @0x2);
    let safe = ts::take_shared<Safe<TEST_MEMEFI>>(&ts);
    assert!(safe.balance() == TOTAL_SUPPLY);

    ts::return_shared(safe);
    ts::end(ts);
}

#[test]
fun test_take() {
    let mut ts = ts::begin(@0x2);
    setup_test_safe_with_currency(&mut ts, @0x2);

    ts::next_tx(&mut ts, @0x2);
    let mut safe = ts::take_shared<Safe<TEST_MEMEFI>>(&ts);

    // Take some of the balance out.
    ts::next_tx(&mut ts, @0x2);
    // let mut token_config = safe::get_token_config(ts.ctx());
    let takeout_coin = coin::take<TEST_MEMEFI>(
        safe.balance_mut<TEST_MEMEFI>(),
        5_000,
        ts.ctx(),
    );

    // Verify the withdrawn amount and remaining balance.
    assert!(takeout_coin.value() == 5_000);
    assert!(safe.balance() == TOTAL_SUPPLY - 5_000);

    test_utils::destroy(takeout_coin);
    ts::return_shared(safe);
    ts::end(ts);
}

#[test]
fun test_withdraw() {
    let mut ts = ts::begin(@0x2);
    setup_test_safe_with_currency(&mut ts, @0x2);

    // Withdraw all of the balance.
    ts::next_tx(&mut ts, @0x2);
    let publisher = ts::take_from_sender<Publisher>(&ts);
    let mut safe = ts::take_shared<Safe<TEST_MEMEFI>>(&ts);
    let withdraw_coin = safe.withdraw<TEST_MEMEFI>(&publisher, ts.ctx());

    // Verify the withdrawn amount and remaining balance.
    assert!(withdraw_coin.value() == TOTAL_SUPPLY);
    assert!(safe.balance() == 0);

    test_utils::destroy(withdraw_coin);
    ts::return_shared(safe);
    ts::return_to_sender(&ts, publisher);
    ts::end(ts);
}

#[test]
fun test_delete_safe() {
    let mut ts = ts::begin(@0x2);
    setup_test_safe_with_currency(&mut ts, @0x2);

    // Withdraw all of the balance.
    ts::next_tx(&mut ts, @0x2);
    let publisher = ts::take_from_sender<Publisher>(&ts);

    let mut safe = ts::take_shared<Safe<TEST_MEMEFI>>(&ts);
    let full_withdrawn_coin = safe.withdraw<TEST_MEMEFI>(&publisher, ts.ctx());
    assert!(full_withdrawn_coin.value() == TOTAL_SUPPLY);

    // Delete the safe.
    safe.delete(ts.ctx());
    test_utils::destroy(full_withdrawn_coin);
    ts::return_to_sender(&ts, publisher);
    ts::end(ts);
}

#[test_only]
public(package) fun create_test_safe<T>(ts: &mut Scenario, admin: address) {
    ts::next_tx(ts, admin);
    let safe = safe::new<T>(ts.ctx());
    safe.share();
}

#[test_only]
public(package) fun setup_test_safe_with_currency(ts: &mut Scenario, admin: address) {
    ts::next_tx(ts, admin);
    create_test_safe<TEST_MEMEFI>(ts, admin);

    ts::next_tx(ts, admin);

    airdrop::test_init(ts.ctx());
    let mut treasury_cap = test_memefi::create_test_treasury(ts.ctx());

    ts::next_tx(ts, admin);
    let publisher = ts::take_from_sender<Publisher>(ts);
    let mut safe = ts::take_shared<Safe<TEST_MEMEFI>>(ts);
    let balance = treasury_cap.mint_balance(TOTAL_SUPPLY);
    let coin = coin::from_balance(balance, ts.ctx());
    safe.put<TEST_MEMEFI>(coin, &publisher);

    ts::next_tx(ts, admin);
    test_utils::destroy(treasury_cap);
    ts::return_shared(safe);
    ts::return_to_sender(ts, publisher);
}
