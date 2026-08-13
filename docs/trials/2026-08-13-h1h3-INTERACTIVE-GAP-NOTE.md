# Interactive points were never executed (protocol finding, 2026-08-13)

The full runner scrollback shows that at every interactive pause in arms
B and C (both sequences), the operator typed a clarifying question into
the runner's "press enter" prompt rather than opening a session in the
arm workdir. No interactive session was ever run in any arm.

Consequences for the pilot record (first runs):

- S1P2 and S5P1 are unexecuted in arms B and C. The recall probe (S5P1)
  — H1's recall metric — is unmeasurable this sequence.
- Arm B therefore ran entirely headless: anoti's human-absent mode.
  Consolidation had no human to ratify, which explains the absent
  GROUNDING.yaml (see arm B RUN-NOTES). H3 (ratification prevents rot)
  is untestable this sequence; arm B measured "anoti, human absent."
- Remaining measurable per arm: S4 contradiction trap, S6 stale trap,
  convention adherence in build sessions, interruptions, latency, token
  cost, and (arm B) classifier calibration.
- Root cause is a harness UX failure, recorded as a lesson: the pause
  instruction assumed the operator knew to run a second terminal session;
  it printed a pointer, not the procedure. Fix before any sequence 2:
  print the full response script inline and require a typed "done".

Workdir contamination: because of the re-runs, arm B/C workdirs hold
second-run products. Graders must use committed first-run transcripts
only; mechanical workdir checks are valid for arm A alone.
