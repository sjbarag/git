#!/bin/sh

test_description='basic clone options'
. ./test-lib.sh

test_expect_success 'setup' '

	mkdir parent &&
	(cd parent && git init &&
	 echo one >file && git add file &&
	 git commit -m one)

'

test_expect_success 'clone -o' '

	git clone -o foo parent clone-o &&
	(cd clone-o && git rev-parse --verify refs/remotes/foo/master)

'

test_expect_success 'rejects invalid -o/--origin' '

	test_expect_code 128 git clone -o "bad...name" parent clone-bad-name 2>err &&
	test_debug "cat err" &&
	test_i18ngrep "'\''bad...name'\'' is not a valid origin name" err

'

test_expect_success 'disallows --bare with --origin' '

	test_expect_code 128 git clone -o foo --bare parent clone-bare-o 2>err &&
	test_debug "cat err" &&
	test_i18ngrep "\-\-bare and --origin foo options are incompatible" err

'

test_expect_success 'disallows --bare with --separate-git-dir' '

	test_expect_code 128 git clone --bare --separate-git-dir dot-git-destiation parent clone-bare-sgd 2>err &&
	test_debug "cat err" &&
	test_i18ngrep "\-\-bare and --separate-git-dir are incompatible" err

'

test_expect_success 'uses "origin" for default remote name' '

	git clone parent clone-default-origin &&
	(cd clone-default-origin && git rev-parse --verify refs/remotes/origin/master)

'

test_expect_success 'prefers config "clone.defaultRemoteName" over default' '

	test_config_global clone.defaultRemoteName upstream &&
	git clone parent clone-config-origin &&
	(cd clone-config-origin && git rev-parse --verify refs/remotes/upstream/master)

'

test_expect_success 'prefers -c config over normal config' '

	test_config_global clone.defaultRemoteName upstream &&
	git clone -c clone.defaultRemoteName=foo parent clone-inline-config-origin &&
	(cd clone-inline-config-origin && git rev-parse --verify refs/remotes/foo/master)

'

test_expect_success 'prefers --origin over config "clone.defaultRemoteName"' '

	git clone -c clone.defaultRemoteName=foo --origin bar parent clone-o-and-config-origin &&
	(cd clone-o-and-config-origin && git rev-parse --verify refs/remotes/bar/master)

'

test_expect_success 'redirected clone does not show progress' '

	git clone "file://$(pwd)/parent" clone-redirected >out 2>err &&
	! grep % err &&
	test_i18ngrep ! "Checking connectivity" err

'

test_expect_success 'redirected clone -v does show progress' '

	git clone --progress "file://$(pwd)/parent" clone-redirected-progress \
		>out 2>err &&
	grep % err

'

test_expect_success 'chooses correct default initial branch name' '
	git init --bare empty &&
	git -c init.defaultBranch=up clone empty whats-up &&
	test refs/heads/up = $(git -C whats-up symbolic-ref HEAD) &&
	test refs/heads/up = $(git -C whats-up config branch.up.merge)
'

test_expect_success 'guesses initial branch name correctly' '
	git init --initial-branch=guess initial-branch &&
	test_commit -C initial-branch no-spoilers &&
	git -C initial-branch branch abc guess &&
	git clone initial-branch is-it &&
	test refs/heads/guess = $(git -C is-it symbolic-ref HEAD) &&

	git -c init.defaultBranch=none init --bare no-head &&
	git -C initial-branch push ../no-head guess abc &&
	git clone no-head is-it2 &&
	test_must_fail git -C is-it2 symbolic-ref refs/remotes/origin/HEAD &&
	git -C no-head update-ref --no-deref HEAD refs/heads/guess &&
	git -c init.defaultBranch=guess clone no-head is-it3 &&
	test refs/remotes/origin/guess = \
		$(git -C is-it3 symbolic-ref refs/remotes/origin/HEAD)
'

test_done
