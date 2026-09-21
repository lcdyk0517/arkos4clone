
	Linux firmware
	==============

  <http://git.kernel.org/?p=linux/kernel/git/firmware/linux-firmware.git>

  git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git

This repository contains all these firmware images which have been
extracted from older drivers, as well various new firmware images which
we were never permitted to include in a GPL'd work, but which we _have_
been permitted to redistribute under separate cover.

To submit firmware to this repository, please send either a git binary
diff or preferably a git pull request to:
      linux-firmware@kernel.org
and also cc: to related mailing lists.

If your commit adds new firmware, it must update the WHENCE file to
clearly state the license under which the firmware is available, and
that it is redistributable. Being redistributable includes ensuring
the firmware license provided includes an implicit or explicit
patent grant to end users to ensure full functionality of device
operation with the firmware. If the license is long and involved, it's
permitted to include it in a separate file and refer to it from the
WHENCE file ('See LICENSE.foo for details.').
And if it were possible, a changelog of the firmware itself.

Run 'make check' to check that WHENCE is consistent with the
repository contents.

Ideally, your commit should contain a Signed-Off-By: from someone
authoritative on the licensing of the firmware in question (i.e. from
within the company that owns the code).


WARNING:
=======

Don't send any "CONFIDENTIALITY STATEMENT" in your e-mail, patch or
request. Otherwise your firmware _will never be accepted_.

Maintainers are really busy, so don't expect a prompt reply.
