# Arm B run observations (integrity, not grading)

- All 7 headless transcripts parseable; timing complete (705s headless total).
- `.anoti/` present in workdir: telemetry.log (9 classification lines,
  preserved here for rubric metric 7) and one session-state file.
- **No GROUNDING.yaml existed in the arm workdir at completion.** The
  governed arm therefore ran with hooks active but no memory store ever
  bootstrapped — the retrieval digest had nothing to inject, and any
  consolidation dialog had no store to write to unless it created one
  (it did not). Interpretation belongs to the decision-rules stage; the
  observation is recorded here because it shapes what arm B actually
  tested: anoti-as-installed-by-default, not anoti-with-scaffolded-
  workspace.
- Plugin state after runner exit: explicitly re-enabled by the
  controller (the arm-B restore trap disables on exit by design).
- Interactive points S1P2/S5P1 ran in the human's own sessions; relayed
  records to be filed alongside as S1P2.relayed.md / S5P1.relayed.md.
