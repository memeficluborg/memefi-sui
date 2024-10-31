module memefi::test_treasury;

use memefi::test_memefi;
use memefi::treasury;
use sui::test_utils;

#[test]
fun test_wrapped_treasury() {
    let mut ctx = tx_context::dummy();
    let wrapped_treasury = test_memefi::create_wrapped_test_treasury(&mut ctx);
    test_utils::destroy(wrapped_treasury);
}

#[test]
fun test_total_supply() {
    let mut ctx = tx_context::dummy();
    let wrapped_treasury = test_memefi::create_wrapped_test_treasury(&mut ctx);
    treasury::total_supply(&wrapped_treasury);
    test_utils::destroy(wrapped_treasury);
}
