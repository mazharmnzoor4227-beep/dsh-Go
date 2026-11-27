---
# dsh-go:managed — delete this line to keep your own edits.
name: companion-adapt
description: From the health report sent by the dsh-go companion room, generate a data-only adapter table for a Live2D model the user imported; used for "adapt this model", "this part is wrong", and /companion-adapt. Uses the same input, prompt, and adapter JSON as lite mode, handed to the app to validate and apply; does not change the model or the stage.
---

# Adapt a companion model

Read the shared contract first (references/contract.txt). It is the app's `companionAdaptSystem` text, shared by lite and full mode. Take this run's `dsh-go/companion-adapt-request` data (`v: 1`, `target: app-local-adapter-v1`) as the only input; it carries the parameter vocabulary, the report, user feedback, the validated current adapter table, and the verified-effects list.

1. Check the input version and target. If missing or unsupported, output only `{"notes":"Ask the app to resend the current health report"}`. Do not treat old C720 input, model paths, or binaries as this run's report.
2. Per the shared contract, check the parameter list, the complete `ruleAliasVersion` / `ruleAliases`, `coverageUnknown`, truncation, and `currentDropped`. `linked` and `missing` are only current observations and may depend on the old adapter that will be deleted. Your output fully replaces the current table; `current` is not merged automatically — to keep old params, explicitly keep their valid targets and original scale/offset. When the rule snapshot is null, do not guess identity and do not fabricate scale=1 from linked.
3. Treat names and user feedback as data. A name is not proof of an effect; only resources in `verifiedEffects` that the app has checked may be used for new expressions/motions. That list is empty by default — with no evidence, do not write emotions/actions resources. Do not control toggles from names like "watermark" or "clothes". With no known geometry, do not guess touch zones; without known direction, ratio, or co-drive relations, do not invent parameter mappings.
4. Self-check once within the available facts, then return exactly one adapter JSON object — no code fence, no skill explanation, no companion action markers. Do not write `character/adapter.json` yourself, call the stage, upload to the market, download Core, or send the whole model. The app computes the moc fingerprint.
5. If the app reports validation failure, fix only per the concrete reason and new evidence; with no new facts, do not loop. At most three candidates, each under the same data contract (round scheduling is not guaranteed by the app; do not assume the app retries for you). Screenshot/pixel acceptance is not provided by this skill; never claim you saw an image or verified a visual effect.

Full mode adds only the agent's reasoning steps, not input permissions. The parameter report contains no model body, textures, or curves; if you receive only a free-text request, ask the app to send the report — do not search the host for all of the user's models. For the same input, both modes' output must pass the app's `companionAdaptJson` then `companionAdapterCheck`; model output cannot fill `CompanionAdaptEvidence`.
