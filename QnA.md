# Q&A

## `blink.cmp` error: `invalid ELF header` / missing `.sha256`

### Symptoms
When starting AstroNvim (for example via `av`), you may see messages like:

- `error loading module 'blink_cmp_fuzzy' ... /lib64/libc.so: invalid ELF header`
- `Pre-built binary checksum verification failed`
- `ENOENT ... libblink_cmp_fuzzy.so.sha256`

### Why this happens
`blink.cmp` detects your Linux target libc by running `cc -dumpmachine`.
If your `cc` points to a toolchain like Zig/clang targeting **musl**, blink may fetch/build a musl binary, while your system is **glibc**.
That mismatch causes the `invalid ELF header` error.

### Fix
1. Ensure Rust is installed (if needed):

```bash
mise use -g rust@stable
```

2. Build `blink-cmp-fuzzy` with GCC (not Zig `cc`):

```bash
cd ~/.local/share/astronvim/lazy/blink.cmp
CC=gcc CXX=g++ cargo build --release -p blink-cmp-fuzzy
```

3. Mark build as local and remove stale checksum file:

```bash
git rev-parse HEAD > target/release/version
rm -f target/release/libblink_cmp_fuzzy.so.sha256
```

4. If you use an `av` wrapper script, force system PATH and gcc there:

```bash
exec env PATH=/usr/bin:/bin:$PATH CC=gcc CXX=g++ NVIM_APPNAME=astronvim nvim "$@"
```

5. Restart `av`.

### Verify
You can check that the built library links to glibc correctly:

```bash
readelf -d ~/.local/share/astronvim/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.so | rg NEEDED
```

Expected to include `libc.so.6` (good), not `libc.so`.
