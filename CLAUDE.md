# cov-rs: The Philosophy

## Vision

**Coverage should be effortless, not enterprise.**

Every great tool solves a real problem with ruthless simplicity. cov-rs exists because developers deserve code coverage that just works—no configuration files, no third-party services, no complexity tax.

We believe in:
- **One-line installation**: `curl | bash` isn't just convenience—it's a statement that tools should meet developers where they are
- **Native performance**: LLVM instrumentation is built into Rust. Why add another layer?
- **Workspace-native**: Monorepos are how real projects work. Coverage should understand them
- **CI-first design**: If it doesn't integrate seamlessly with GitHub Actions, it doesn't ship

## Design Principles

### 1. Simplicity is the Ultimate Sophistication

Every feature must justify its existence. This isn't a framework—it's a sharp knife that does one thing perfectly. We optimize for:
- Zero configuration for the common case
- Sensible defaults over customization
- Clear error messages over debug modes
- Progressive disclosure: simple usage is simple, complex usage is possible

### 2. Security as a Foundation

Coverage data touches your entire codebase. Trust isn't optional:
- No eval of untrusted data
- All network operations must be explicit and auditable
- Dependencies are scrutinized, not accumulated
- Shell scripts follow defensive programming practices

### 3. Platform Humility

We support Linux, macOS, and Windows because developers use all three. Platform-specific code is a bug, not a feature. When the OS matters, we handle it gracefully.

### 4. Developer Experience is the Feature

The best tools feel like they read your mind:
- HTML reports open automatically (when possible)
- PR comments show coverage where discussions happen
- Error messages suggest fixes, not just problems
- Progress is visible, not mysterious

### 5. Performance Matters

LLVM's instrumentation is fast. We stay out of the way:
- Minimal overhead over raw LLVM tools
- No redundant compilation
- No temporary file sprawl
- Cache-friendly by default

## What We're Not

This isn't:
- **A coverage service**: We generate reports. You decide where they live.
- **A quality gate**: We provide data. You set standards.
- **A test framework**: We measure what you already test.
- **Feature-complete**: Perfection means knowing what to exclude.

## Architecture Philosophy

### The Script is the Interface

`cov.sh` is 150 lines of bash because:
- Every developer understands bash
- No build step to run a build tool
- Transparency over abstraction
- Fork-friendly by design

### LLVM is the Engine

We're a thin wrapper around `llvm-cov` and `llvm-profdata` because:
- Rust already ships these tools
- They're battle-tested by LLVM
- We inherit their performance
- Updates are upstream's problem

### Cargo is the Source of Truth

We ask `cargo metadata` for project structure because:
- It never lies about workspace configuration
- It handles edge cases we'd never think of
- It means our code stays simple

## Quality Standards

Before any change ships:

**It must be secure**
- [ ] No eval of external data
- [ ] All variables properly quoted
- [ ] Input validation for user-provided values
- [ ] Network operations fail safely

**It must be tested**
- [ ] shellcheck passes without warnings
- [ ] Works on Linux, macOS, Windows
- [ ] Example project runs successfully
- [ ] CI validates all changes

**It must be maintainable**
- [ ] Clear variable names
- [ ] Comments explain why, not what
- [ ] Functions do one thing
- [ ] Error messages guide users to solutions

**It must be fast**
- [ ] No redundant cargo invocations
- [ ] Parallel operations where possible
- [ ] Minimal file I/O

## The Future

We grow by:
1. **Hardening fundamentals**: Better error handling, more platforms, clearer docs
2. **Composability**: Playing well with other tools
3. **Observability**: Making the coverage process transparent

We don't grow by:
1. Feature creep
2. Configuration complexity
3. Mandatory cloud services
4. Breaking existing workflows

## Contributing Philosophy

**Good contributions:**
- Fix bugs with test cases
- Improve error messages
- Add platform support
- Enhance documentation
- Optimize performance

**Think twice about:**
- New command-line flags
- Optional dependencies
- Alternative output formats
- Framework integrations

**We won't accept:**
- Features that complicate simple usage
- Platform-specific hacks that break others
- Dependencies that balloon the install
- Magic that sacrifices transparency

## Success Metrics

We're succeeding when:
1. **First-time users** run one command and get coverage
2. **CI pipelines** add us in 5 lines of YAML
3. **Contributors** understand the entire codebase in 30 minutes
4. **Issues** are answered by reading error messages
5. **Updates** feel like finding money in your pocket—pleasant surprises, never breaking changes

## The Craft

Every line in this repository is intentional. Every function name is considered. Every error message is tested. Every feature is questioned.

We're not building software. We're solving a problem so well that people forget the tool exists.

That's when we've won.

---

*"Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away."* — Antoine de Saint-Exupéry

*"Simple things should be simple, complex things should be possible."* — Alan Kay

**Now go forth and measure your code with confidence.**
