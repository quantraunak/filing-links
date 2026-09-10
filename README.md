# Point-in-Time Economic Links from Filing Text

**A construction protocol for dated firm-relationship graphs, with the benchmark and
cost frontier needed to build one.**

Companies name each other in their 10-Ks. *"Intel is one of our most significant
customers."* *"We purchase substrates from Ibiden and Unimicron."* Nobody sells a map of
those disclosures: the vendor supply-chain products cover the large, obvious links, and
the academic text-based networks measure product-description *similarity* rather than
stated relationships.

What does not exist publicly is the graph as a *point-in-time historical series*. The
nearest published work extracts firm networks from filings for 42 firms in a single
fiscal year. This targets 160 issuers across 2012–2025, with every edge keyed to the date
it was disclosed and carrying a validity interval, so the graph can be asked what it
looked like on any past date.

The protocol has three parts.

---

## 1. A benchmark with auditable negatives

Ten filings, 55 links, **five of them deliberately empty-but-rich**, and every *excluded*
name listed with the rule that excluded it ([`docs/gold_exclusions.md`](docs/gold_exclusions.md)).

Benchmarks for this task normally publish positives only, which makes precision
unfalsifiable: a model that invents a plausible counterparty is scored the same as one
that abstains. The empty-but-rich filings are the discriminating cases — documents dense
with company names where none of them is a disclosed counterparty.

## 2. A measured cost/quality frontier

Six extractor configurations on that benchmark, on hardware a single person owns
([`docs/EXTRACTION.md`](docs/EXTRACTION.md); regenerate offline from cache with
`scripts/benchmark_table.py`):

| model | F1 | s/filing | FP on empty filings | direction errors | recall on 10+ names |
|---|---|---|---|---|---|
| `qwen3:32b` | **0.857** | 270 | 2 | 0 | 0.789 |
| `qwen3:30b-a3b` (MoE) | 0.792 | **13** | 2 | 1 | 0.658 |
| `llama3:8b` | 0.646 | 47 | **27** | 1 | 0.711 |
| `qwen3:32b` no-reasoning | 0.558 | 206 | **26** | **8** | 0.553 |
| `qwen3:14b` | 0.462 | 32 | 3 | 0 | **0.158** |

Three findings aggregate F1 hides. The five deliberately-empty filings separate usable
from unusable models by an order of magnitude where F1 differs by less than two.
Reasoning's contribution is preventing relation *inversions*, not finding more links — it
also returns fewer. And a 20x-faster mixture-of-experts model is **perfect** on filings
naming one to nine counterparties and loses a third on those naming ten or more: its
deficit is length, not quality.

The frontier is load-bearing rather than descriptive. The released graph and the
pre-registered signal test have opposite failure modes — a false edge is a permanent
defect in a published dataset, while a missing edge only attenuates an effect the signal
test is trying to detect — so they take **different points on the same frontier**, and
the measurement is what makes that a decision rather than a preference.

## 3. A pre-registered coverage gate

Returns are known to propagate along supply-chain links with a delay, and the effect is
known to concentrate where investors pay least attention. That is established literature,
not a claim of this repository — see the
[prior-work note](docs/HYPOTHESIS.md#prior-work-checked-2026-09-07--after-the-design-was-fixed-before-any-result).
The return test is therefore a **validation of the graph, not a discovery**, and
[the pre-registration](docs/HYPOTHESIS.md) commits the study to stopping at the coverage
report if edge density does not reach the cross-section.

The gate has already fired once. Under `qwen3:32b` the corpus stalled at 163 filings,
giving 35 source firms and a median of 4 names per date; a cross-sectional rank
correlation over 4 names is undefined, so the study stopped at the coverage report — for
lack of coverage rather than lack of signal. The corpus run then switched to
`qwen3:30b-a3b` to buy coverage at a known cost in F1.

**No forward return has been regressed on any graph-derived quantity.**
`scripts/run_signal_test.py` implements the falsification table as written: an
overlap-corrected IC t-statistic, 20 degree-preserving placebo shuffles, second- against
first-order links, quintile monotonicity, and coverage reported before any return is
regressed. It runs once, when the corpus is complete. The signal section of
[`docs/SPECIFICATIONS.md`](docs/SPECIFICATIONS.md) is empty until then, and it was opened
before the corpus existed so the denominator for a future multiple-testing correction is
honest.

---

## What ships

| Artifact | Status |
|---|---|
| Benchmark v2, 10 filings with auditable negatives | complete |
| Extraction frontier, 6 configurations | complete, reproducible offline |
| Pilot graph — 163 filings, 38 of 160 issuers, 264 edges | released |
| Full corpus — 2,364 filings | extraction in progress |
| Signal test | implemented, pre-registered, not yet run |

Release plan in [`docs/RELEASE.md`](docs/RELEASE.md), datasheet in
[`docs/DATASHEET.md`](docs/DATASHEET.md) following Gebru et al.

## The record

The hypothesis, its falsification table and its placebo test were committed **before any
extraction ran**, so the design cannot be reverse-engineered from the result. The git
history is the evidence: `git log --follow docs/HYPOTHESIS.md` reaches `d645638`,
*"Pre-register the economic-links hypothesis before the corpus exists."*

Every choice made since is appended to [`docs/SPECIFICATIONS.md`](docs/SPECIFICATIONS.md),
never retro-edited, including every configuration that was rejected and the measurement
that killed it. Two rejected hypotheses have their own write-ups:
[`RESULT_01.md`](docs/RESULT_01.md) (extraction recall does not depend on how many items
are present) and [`PILOT_FINDINGS.md`](docs/PILOT_FINDINGS.md) (the median large-cap 10-K
names zero counterparties, which changed the design).

## Layout

```
docs/
  EXTRACTION.md        the cost/quality frontier, and the reading of it
  HYPOTHESIS.md        pre-registration, committed before the corpus
  SPECIFICATIONS.md    every choice tried, append-only
  RELATED_WORK.md      literature checked before building, not after
  EXPERIMENT_01.md     a pre-registered experiment
  RESULT_01.md         its result: the hypothesis rejected
  PILOT_FINDINGS.md    what the pilot measured before the full run was committed to
  DATASHEET.md         Gebru et al. datasheet for the released graph
  RELEASE.md           what ships, in what form, under what licence
  gold_exclusions.md   every excluded name, with the rule that excluded it
project/
  src/
    graph/             filings, passages, extract, resolve, build, signal
    data/              point-in-time universe, prices, fundamentals, panel
    model/ eval/       forward returns and IC, for the signal test only
  scripts/             extraction, benchmarking, graph build, signal test
  tests/               119 tests + 1 xfail, offline and deterministic
```

## Run it

```bash
pip install -r requirements.txt
cd project

python -m scripts.build_data --stage universe     # point-in-time membership
python -m scripts.screen_corpus                   # which filings are worth reading
python -m scripts.extract_corpus --model qwen3:30b-a3b --no-think --sp500
python -m scripts.build_graph                     # claims -> resolved, dated edges
python -m scripts.benchmark_table                 # the frontier, from cache, no GPU
pytest tests
```

Extraction is resumable: the response cache is the source of truth, so a killed run loses
nothing but the filing in flight. `run_corpus_overnight.sh` wraps it in the restart loop
that a long run needs.

## Provenance

Split out of [`bias-fingerprints`](https://github.com/quantraunak/bias-fingerprints) at
commit `6bfe7c2`, which is why the history before that point also contains the factor
study the two projects shared a point-in-time substrate with. That substrate lives on in
`project/src/data`.

## Stack

Python · pandas · Ollama (local Qwen 3) · BeautifulSoup/lxml · pytest
