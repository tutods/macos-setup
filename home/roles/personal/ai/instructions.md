## Personal Tools

| Use | Instead of | Why |
|-----|-----------|-----|
| `doppler` | `.env` files | Type-safe secrets management, no plaintext env vars |

- Use `doppler run -- <command>` to inject secrets into processes
- Use `doppler setup` to configure project secrets

## AI Privacy Guard (Personal Role)

To prevent accidental data leakage and maintain a high privacy posture:

- **Forbidden Commands**: NEVER use `env`, `printenv`, or `set` to dump the environment. This often leaks session tokens and private keys.
- **Secret Access**: Only use `doppler` to verify the existence of keys or run commands. NEVER use `doppler` to read or print the actual secret values; only the keys are to be surfaces.
- **DLP (Data Leakage Prevention)**: 
  - Never log the output of any command containing a secret.
  - Avoid reading files in `~/Documents` or `~/Downloads` unless specifically requested for the current task.
- **Verification**: Always scrub the output of any generated script for plaintext secrets before presenting it to the user.
