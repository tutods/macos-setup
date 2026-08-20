## Personal Tools

Secrets live in `doppler`, never in `.env` files: `doppler run -- <command>`
to inject them into a process, `doppler setup` to configure a project.

Use `doppler` only to check that a key exists or to run a command with it,
never to read or print a secret's value, and never log the output of a command
that contains one. Scrub generated scripts for plaintext secrets before
showing them.

Don't read files in `~/Documents` or `~/Downloads` unless the current task
specifically calls for it.
