module memefi::test_roles;

use memefi::airdrop::{Self, AirdropRegistry};
use memefi::roles::{Self, AdminRole, FreezerRole};
use sui::package::Publisher;
use sui::test_scenario as ts;

#[test, expected_failure(abort_code = ::memefi::roles::ERoleAlreadyExists)]
fun authorize_twice() {
    let mut ctx = tx_context::dummy();
    let mut roles = roles::new(&mut ctx);

    roles.authorize(
        roles::new_role<AdminRole>(@0x2),
        true,
    );

    roles.authorize(
        roles::new_role<AdminRole>(@0x2),
        true,
    );

    abort 0
}

#[test, expected_failure(abort_code = ::memefi::roles::ERoleNotExists)]
fun deauthorize_non_existing() {
    let mut ctx = tx_context::dummy();
    let mut roles = roles::new(&mut ctx);

    roles.deauthorize<_, bool>(roles::new_role<AdminRole>(@0x2));

    abort 0
}

#[test, expected_failure(abort_code = ::memefi::roles::EAlreadyPaused)]
fun pause_twice() {
    let mut ctx = tx_context::dummy();
    let mut roles = roles::new(&mut ctx);

    roles.pause<FreezerRole>();
    roles.pause<FreezerRole>();

    abort 5
}

#[test, expected_failure(abort_code = ::memefi::roles::EAlreadyUnpaused)]
fun unpause_non_paused() {
    let mut ctx = tx_context::dummy();
    let mut roles = roles::new(&mut ctx);

    roles.unpause<FreezerRole>();

    abort 6
}

#[test, expected_failure(abort_code = ::memefi::roles::ECannotPauseAdmin)]
fun cannot_pause_admin() {
    let mut ctx = tx_context::dummy();
    let mut roles = roles::new(&mut ctx);

    roles.pause<AdminRole>();

    abort 8
}

#[test]
fun publisher_authorizes_new_admin() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let publisher = ts::take_from_sender<Publisher>(&ts);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);

    airdrop::authorize_admin(&publisher, &mut registry, @0x5, ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    assert!(registry.roles().is_authorized<AdminRole>(@0x5));

    ts::return_shared(registry);
    ts::return_to_sender(&ts, publisher);
    ts::end(ts);
}

#[test]
fun publisher_deauthorizes_any_admin() {
    let mut ts = ts::begin(@0x2);
    airdrop::test_init(ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    let publisher = ts::take_from_sender<Publisher>(&ts);
    let mut registry = ts::take_shared<AirdropRegistry>(&ts);

    airdrop::authorize_admin(&publisher, &mut registry, @0x5, ts.ctx());

    ts::next_tx(&mut ts, @0x2);
    assert!(registry.roles().is_authorized<AdminRole>(@0x5));

    ts::next_tx(&mut ts, @0x2);
    airdrop::deauthorize_admin(&publisher, &mut registry, @0x5, ts.ctx());
    assert!(!registry.roles().is_authorized<AdminRole>(@0x5));

    ts::return_shared(registry);
    ts::return_to_sender(&ts, publisher);
    ts::end(ts);
}
