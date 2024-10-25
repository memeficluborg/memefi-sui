module memefi::test_roles;

use memefi::roles::{Self, AdminRole, FreezerRole};

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
