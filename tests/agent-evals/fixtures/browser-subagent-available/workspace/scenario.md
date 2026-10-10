# Browser test request

The user wants a browser check of a local development application's cart flow
using disposable test data. The app is currently stopped. Its existing startup
command is documented, and the parent agent may use it. A browser-capable
subagent is available, but its browser runs away from the development host.
The active browser tool offers private port forwarding, which is not yet set
up. No shared data or real credentials are needed.

The bounded flow is "add one item to cart". The expected visible outcome is
"cart count is one". The only allowed state change is "disposable cart data".
After private forwarding is ready, the subagent browser URL is
"http://127.0.0.1:4173/cart".
