module memefi::test_vault;

use memefi::test_memefi::{Self, TEST_MEMEFI};
use memefi::vault;

#[test]
fun test_vault_initialization() {
    let mut ctx = tx_context::dummy();
    vault::test_init(&mut ctx);
}
