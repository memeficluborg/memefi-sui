module memefi::test_memefi;

use memefi::treasury::{Self, WrappedTreasury};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::pay;
use sui::test_scenario as ts;
use sui::test_utils;

const TOTAL_SUPPLY: u64 = 10_000_000_000;

public struct TEST_MEMEFI has drop {}

#[test]
fun test_mint_memefi() {
    let mut ts = ts::begin(@0x2);
    let mut treasury_cap = create_test_treasury(ts.ctx());

    ts::next_tx(&mut ts, @0x2);

    // Mint the total supply of `MEMEFI` tokens and send the whole supply to @0x2.
    let balance = treasury_cap.mint_balance(TOTAL_SUPPLY);
    let coin = coin::from_balance(balance, ts.ctx());
    pay::keep(coin, ts.ctx());

    // Confirm that @0x2 has received the MEMEFI coin and the value is equal to
    // TOTAL_SUPPLY.
    ts::next_tx(&mut ts, @0x2);
    let coin = ts::take_from_sender<Coin<TEST_MEMEFI>>(&ts);
    assert!(coin.value() == TOTAL_SUPPLY);

    ts::next_tx(&mut ts, @0x2);
    ts::return_to_sender(&ts, coin);

    test_utils::destroy(treasury_cap);
    ts::end(ts);
}

#[test_only]
public fun create_test_treasury(ctx: &mut TxContext): TreasuryCap<TEST_MEMEFI> {
    let (treasury_cap, coin_metadata) = coin::create_currency(
        TEST_MEMEFI {},
        6,
        vector[],
        vector[],
        vector[],
        option::none(),
        ctx,
    );

    transfer::public_share_object(coin_metadata);
    treasury_cap
}

#[test_only]
public fun create_wrapped_test_treasury(
    ctx: &mut TxContext,
): WrappedTreasury<TEST_MEMEFI> {
    let (treasury_cap, coin_metadata) = coin::create_currency(
        TEST_MEMEFI {},
        6,
        vector[],
        vector[],
        vector[],
        option::none(),
        ctx,
    );

    transfer::public_share_object(coin_metadata);
    treasury::wrap(treasury_cap, ctx)
}
