# Automatic head deletion before release completion

GitHub is configured to delete a pull request head branch automatically when
its merge completes. The user authorized the exact merge and creation of a
recovery ref; that verified recovery ref now preserves the reviewed head. There
is still no branch-deletion authority, provider-setting authority, release
publication authority, or cleanup authority. The project publishes its release
after integration, and publication can become partial or unknown.
