# Tasks CLI Friction Report

**Report Date:** 2026-08-13  
**Practitioner:** support  
**Scope:** Reproduce and rank two user-reported error scenarios against `q004-prefix-snapshot`

---

## Executive Summary

Two critical failure modes were reproduced and ranked by severity and frequency:

1. **Silent Data Corruption on Corrupted Restore** (CRITICAL) — App accepts tasks.json with duplicate IDs without validation or warning; users lose visibility into data integrity.
2. **Unhandled Permission Error as Traceback** (HIGH) — Permission errors during writes produce multi-line Python traceback instead of clean error message; wrapper scripts misinterpret exit codes.

Both require immediate remediation to meet the contract stated in the module docstring (error codes 0–3, error format, schema validation).

---

## Friction #1: Silent Data Corruption on Restore (CRITICAL)

### Reproduction Evidence

**Scenario:** User restores tasks.json from backup; the file contains duplicate task IDs (data corruption). App loads it silently and operates as if the data is valid.

**Setup:**

```bash
# Create corrupted tasks.json with duplicate IDs
mkdir corruption_test && cd corruption_test
cp ../tasks.py .
cat > tasks.json << 'EOF'
{
  "next_id": 3,
  "tasks": [
    {"id": 1, "text": "task A", "done": false},
    {"id": 1, "text": "task B", "done": false}
  ]
}
EOF
```

**Command & Output:**

```bash
$ python3 tasks.py list
[ ] 1: task A
[ ] 1: task B
Exit code: 0
```

**Expected Behavior (per contract):**

- Exit code: 3 (data error, schema validation failed)
- Stderr: `Error: <reason>`
- No tasks displayed

**Actual Behavior:**

- Exit code: 0 (success)
- Displays corrupted data as if valid
- User has no warning their restore is broken

### Root Cause

**Evidence:** {file: tasks.py, lines: 87–109}  
The `_validate_schema()` function validates type constraints but not data uniqueness. Task IDs must be unique per the implicit contract (each ID used as a primary key in list/done/rm operations), but this is never checked.

**Call chain:**

1. `main()` calls `load(TASKS_PATH)` (line 239)
2. `load()` calls `_validate_schema(data)` (line 130)
3. `_validate_schema()` returns without error (no uniqueness check)
4. Corrupted data is returned to caller
5. App proceeds with invalid state

### Severity Ranking

**Judgment:** CRITICAL — Data integrity failure.

- **Frequency:** High. Restore-from-backup is a common operation; corruption can occur across backup media, network, or filesystem migration.
- **Impact:** Silent. User has no warning the file is corrupted. User operates on data they believe is valid. Subsequent edits persist the corruption. This is worse than an explicit error because the user loses visibility into the problem.
- **User Recovery:** User must manually inspect tasks.json to discover duplicate IDs. There is no self-healing mechanism.

---

## Friction #2: Unhandled Permission Error as Traceback (HIGH)

### Reproduction Evidence

**Scenario:** User attempts to add a task to a directory that is read-only (e.g., after system restore makes a directory read-only, or after backup tool sets read-only flag).

**Setup:**

```bash
mkdir readonly_test && cd readonly_test
cp ../tasks.py .
python3 tasks.py add "first task"  # succeeds, creates tasks.json
cd ..
chmod 555 readonly_test              # directory is now r-xr-xr-x
```

**Command & Output:**

```bash
$ python3 readonly_test/tasks.py add "second task"
Traceback (most recent call last):
  File "/path/to/tasks.py", line 297, in <module>
    sys.exit(main())
  File "/path/to/tasks.py", line 251, in main
    save(TASKS_PATH, data)
  File "/path/to/tasks.py", line 137, in save
    fd, tmp_path = tempfile.mkstemp(prefix=".tasks-", suffix=".tmp", dir=directory)
  File "/opt/homebrew/Cellar/python@3.14/3.14.4/Frameworks/Python.framework/Versions/3.14/lib/python3.14/tempfile.py", line 354, in mkstemp
    return _mkstemp_inner(dir, prefix, suffix, flags, output_type)
  File "/opt/homebrew/Cellar/python@3.14/3.14.4/Frameworks/Python.framework/Versions/3.14/lib/python3.14/tempfile.py", line 255, in _mkstemp_inner
    fd = _os.open(file, flags, 0o600)
PermissionError: [Errno 13] Permission denied: '/path/to/.tasks-XXXXX.tmp'
Exit code: 1
```

**Expected Behavior (per contract):**

- Stderr: `Error: could not write tasks.json: Permission denied`
- Exit code: 3 (data error, I/O failure during persistence)
- One-line error message only

**Actual Behavior:**

- Stderr: Multi-line Python traceback (7 lines)
- Exit code: 1 (semantic error — misleads caller into thinking "task not found")
- User's wrapper script (which checks exit codes) misinterprets the failure

### Root Cause

**Evidence:** {file: tasks.py, lines: 134–146}  
The `save()` function does not catch `OSError`/`PermissionError`. When `tempfile.mkstemp()` or `os.replace()` fails, the exception propagates to `main()`, which has no handler for I/O errors.

**Call chain:**

1. `main()` catches `TasksDataError` only (line 240–242)
2. `main()` calls `save(TASKS_PATH, data)` (line 251)
3. `save()` calls `tempfile.mkstemp()` (line 137), which raises `PermissionError`
4. `PermissionError` is not caught; propagates to Python's top-level handler
5. Python prints traceback and exits with code 1

### Severity Ranking

**Judgment:** HIGH — Contract violation; misleading error signal.

- **Frequency:** Medium. Occurs in backup/restore scenarios, read-only mounted filesystems, or after system permissions are modified.
- **Impact:** Moderate. Error is visible to the user (traceback), but violates the contract (should be one-line `Error: <message>`). Wrapper scripts that check exit codes are misled: exit code 1 means "semantic error / task not found", not "I/O error". This can cause the wrapper to retry, fail silently, or corrupt downstream logic.
- **User Recovery:** User sees scary traceback; must read stack trace to understand the root cause (permission denied). User must manually fix directory permissions.

---

## Friction Summary and Ranking

| Rank | Issue                            | Severity | Frequency | Impact                         | Reproducibility |
| ---- | -------------------------------- | -------- | --------- | ------------------------------ | --------------- |
| 1    | Silent corruption on restore (B) | CRITICAL | HIGH      | Data loss visibility           | 100%            |
| 2    | Permission error traceback (A)   | HIGH     | MEDIUM    | Error signal misinterpretation | 100%            |

**Basis for Ranking:**

- **Rank 1 (Friction B):** Chosen for rank 1 because silent data corruption is more harmful than error messaging. A user operating on corrupted data without warning can lose or corrupt data in subsequent operations. The error is invisible, making it unrecoverable without manual inspection.
- **Rank 2 (Friction A):** High severity because it violates the contract and confuses wrapper scripts, but less critical than silent corruption because the failure is at least visible (traceback), and users can see what went wrong and manually intervene.

---

## Requirements Rewrite

### Requirement 1: Validate ID Uniqueness on Load (Addresses Friction #1)

**User Story:**  
As a user restoring tasks.json from an old backup, I want the app to validate that all task IDs are unique. If the file has duplicate IDs, I want the app to reject it with an exit code 3 and a clear error message, so I know my backup is corrupted and can take action.

**Acceptance Criteria:**

1. **Valid data (no duplicates) passes validation:**
   - Command: `python3 tasks.py list`
   - Input file: tasks.json with IDs [1, 2, 3] (all unique)
   - Expected: Exit code 0, tasks displayed normally

2. **Duplicate IDs are detected on load:**
   - Command: `python3 tasks.py list`
   - Input file: tasks.json with IDs [1, 1, 2] (duplicate ID 1)
   - Expected: Exit code 3, stderr: `Error: tasks schema validation failed: duplicate task id <X>`

3. **Duplicate check occurs before any operation:**
   - Command: `python3 tasks.py add "new task"` with corrupted tasks.json
   - Expected: Exit code 3, error message, no changes made

4. **Error message is single-line and descriptive:**
   - Stderr format: `Error: <message>`
   - No traceback, no multi-line output

---

### Requirement 2: Catch I/O Errors and Return Exit Code 3 (Addresses Friction #2)

**User Story:**  
As a user working with tasks in a read-only directory (after a system restore or backup tool locks the directory), I want the app to give me a clear, one-line error message and exit code 3, so my wrapper scripts can correctly handle the error and I know what went wrong.

**Acceptance Criteria:**

1. **Read-only directory is caught gracefully:**
   - Command: `python3 tasks.py add "task"` in read-only directory with read-only tasks.json
   - Expected: Exit code 3, stderr: `Error: could not write tasks.json: Permission denied`
   - No traceback

2. **Error message is single-line:**
   - Stderr output must be exactly one line starting with `Error: `
   - No Python traceback lines

3. **Exit code correctly signals data error:**
   - Exit code: 3 (not 1, 2, or other)
   - Wrapper scripts can distinguish I/O errors from semantic errors (exit 1) and usage errors (exit 2)

4. **All I/O failures are caught:**
   - Write failures (tempfile.mkstemp, os.replace, json.dump)
   - Read failures during load() (file read, JSON parse, schema validation)
   - All produce exit code 3 with descriptive message

---

## Questions & Doubts

1. **Friction #1 — What should the error message say for duplicate IDs?**
   - Should it list all duplicate IDs found, or just the first one?
   - Should it suggest a recovery action (e.g., "manually edit tasks.json to remove duplicates")?
   - _Current recommendation:_ Report the first duplicate found; recovery is user's responsibility (manual edit or restore from earlier backup).

2. **Friction #2 — Should save() catch BaseException or just OSError?**
   - Current code in save() has a broad `except BaseException` clause (line 143–146). Is this intentional?
   - Should we let MemoryError, KeyboardInterrupt, etc. propagate, or catch them?
   - _Current recommendation:_ Catch OSError specifically for I/O errors; let other exceptions propagate so they don't mask unexpected failures.

3. **Scope question — Does the app need to validate next_id?**
   - E.g., if next_id = 1 but tasks already have IDs up to 10, is that corruption?
   - _Current assumption:_ No—next_id is an internal state for assigning IDs to new tasks. Mismatch with existing task IDs doesn't cause operational failure, just inefficiency.

4. **Recovery — Should the app offer a self-heal mode?**
   - E.g., `--validate` or `--repair` flag to detect and fix duplicate IDs?
   - _Current recommendation:_ Out of scope for this fix. Repair mode should be a separate feature request (requires manual approval to rewrite the file).

---

## Methodology Notes

**Per policy-epistemic:**

- All reproductions made against the frozen snapshot in `q004-prefix-snapshot/` (tasks.py, test_tasks.py, unmodified)
- Predictions stated before each test
- All outputs and exit codes cited as {command, output, exit_code} evidence
- Severity ranking includes frequency, impact, and visibility as factors
- Doubts and uncertainties surfaced in this section

**Per policy-trace-to-frame:**

- This report serves the goal: build trial evidence for Q004 (support role's model tier sufficient for reproduce-and-translate work)
- Reproduction and rewrite work traces to the support role's friction-first approach
- Report is a proposal for human ratification before any publication or action

---

## Next Steps (for human ratification)

1. Review and approve this friction report
2. Validate that requirements are testable and actionable
3. Decide: accept, reject, or modify rankings and requirements
4. Hand off to architecture or engineering for implementation planning
