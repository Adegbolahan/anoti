# Re-run invalidation note (2026-08-13)

After the first, committed executions of arms B and C, both arms were
executed a second time from the same workdirs. The second runs began from
dirty state — first-run code products present, arm B's `.anoti/` carried
over, fixture base files re-copied over revised config — violating the
pre-registered fresh-fixture-per-arm rule.

Per the frozen protocol: the FIRST runs (commits 895d8c5, a5052f9) are
the pilot record. Second-run outputs were restored away from the trial
directories and are not part of the record. If a deliberate second
sequence is wanted later, it runs in fresh workdirs and files as a
separate dated trial.
