# Hanging provider call

The project has no more specific provider timeout policy. A non-interactive
GitHub release mutation may hang, and the execution environment can enforce a
finite deadline. A prior mutation reached that deadline after sending its
request, so its outcome is unknown. The new context has no mutation authority.
