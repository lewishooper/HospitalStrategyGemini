# Ontario Hospital Strategic Theme Validation
## Session Handoff Summary & Next Steps
### February 27, 2026 | Phase 1 Validation Work — Session 4

---

## 1. Session Overview

This session completed Phase 1 keyword validation work on the 11-theme strategic taxonomy for Ontario hospital strategic plans. The primary focus was executing Methods B, C, and D in sequence to verify, rationalize, and expand the keyword set established in Session 3, culminating in the finalized `StrategicKeywordsv2.rds`.

Method B (KWIC co-occurrence) was applied to all 11 themes, with priority focus on the three under-specified themes (2, 4, 6) from Session 3. Method C (unmatched directions review) confirmed a 96% overall match rate and identified 21 unmatched directions, the majority attributable to French-language content rather than keyword gaps. Method D (domain vocabulary from Ontario Health and OHA frameworks) produced targeted swaps across four themes, replacing lower-performing keywords with domain-validated alternatives.

A total of 18 changes were made to the keyword set across the session — 9 net additions to under-ceiling themes, 4 Method B/D swaps, 4 drops of underperforming or bleeding keywords, and 1 rural addition from Method C.

---

## 2. Completed Steps This Session

- Executed Method B KWIC co-occurrence analysis for all 11 themes using `quanteda::kwic()` with window = 10
- Made expansion decisions for priority Themes 2, 4, and 6 based on full 30-word context outputs
- Executed Method B for remaining Themes 1, 3, 5, 7, 8, 9, 10, 11 and made add/swap decisions
- Executed Method C unmatched directions analysis — 21 unmatched of 523 (4%), 96% match rate
- Identified French-language content as primary driver of unmatched directions
- Added `rural` to Theme 4 based on Method C vocabulary gap review
- Executed Method D domain vocabulary check against Ontario Health and OHA framework terms
- Applied 4 Method D swaps across Themes 2, 4, 6, and 11
- Saved finalized keyword set as `StrategicKeywordsv2.rds` and `StrategicKeywordsv2.csv`

---

## 3. Final Keyword Set — StrategicKeywordsv2

| Theme | # Keywords | Keywords |
|-------|-----------|---------|
| 1 - Patient Care Excellence | 8 | clinical, improvement, outcomes, patient care, patient experience, quality, safe, safety |
| 2 - Access & Capacity | 8 | access, capacity, expand, flow, mental, timely, transitions, virtual |
| 3 - Health Equity & Social Accountability | 8 | anti racism, diversity, equitable, equity, health equity, inclusion, indigenous, reconciliation |
| 4 - Population & Community Health | 9 | aging, communities, population, populations, prevention, primary, rural, vulnerable, wellness |
| 5 - Workforce Sustainability | 8 | professional development, recruitment, retain, retention, teams, well-being, workforce, workplace |
| 6 - Financial Sustainability | 8 | financial, fiscal, funding, investment, operational, resources, stewardship, sustainability |
| 7 - Digital Health & Innovation | 8 | analytics, artificial intelligence, data, digital, digital health, innovation, innovative, systems |
| 8 - Integration & Partnerships | 8 | collaboration, collaborative, community partners, integrated, integrated care, integration, partners, partnerships |
| 9 - Infrastructure & Environment | 7 | building, capital, environmental, equipment, facilities, infrastructure, physical |
| 10 - Organizational Culture & Governance | 8 | accountability, culture, engagement, governance, leadership, organizational, transparency, values |
| 11 - Research, Education & Academics | 8 | academic, academic health, clinical research, discovery, education, knowledge, learning, research innovation |

**Notes:**
- Theme 4 at 9 keywords is intentional — `rural` warrants inclusion as a distinct population concept not subsumed by existing keywords
- Theme 9 at 7 keywords — one slot intentionally left open; no corpus or domain candidate was sufficiently clean
- Bold items from Session 3 (bigrams) are retained; `Type` column distinguishes `word` vs `bigram` in the RDS
- Overlap flags in the RDS: `capital` (Theme 9, moderate overlap with Theme 6); `leadership` (Theme 10, moderate overlap with Theme 5)

---

## 4. Key Changes From Session 3 Baseline

| Theme | Action | Word | Method | Rationale |
|-------|--------|------|--------|-----------|
| 2 | Add | mental | B | "Mental health access" strong corpus signal |
| 2 | Add | flow | B | "Patient flow" — capacity management language |
| 2 | Drop | barriers | D | Too sparse; replaced by virtual |
| 2 | Add | virtual | D | "Virtual care" — post-pandemic Ontario access language |
| 3 | Swap out | belonging | B | Subsumed by diversity/inclusion/equity |
| 3 | Swap in | reconciliation | B | Strong Ontario Indigenous health accountability signal |
| 4 | Add | aging | B | "Aging population" — concrete Ontario demographic driver |
| 4 | Add | prevention | B | Core population health language |
| 4 | Add | vulnerable | B | "Vulnerable populations" — standard public health framing |
| 4 | Drop | healthy | D | Subsumed by wellness |
| 4 | Add | wellness | D | Strongest Method D signal (n=35, 6.7%) |
| 4 | Add | rural | C | Vocabulary gap in unmatched directions |
| 5 | Add | well-being | B | "Staff well-being" — authentic workforce strategy language |
| 6 | Add | stewardship | B | "Financial stewardship" — most distinctive financial phrase |
| 6 | Add | fiscal | B | "Fiscal responsibility/health" — zero overlap risk |
| 6 | Add | resources | B | High frequency (n=15 around financial) |
| 6 | Drop | efficiency | D | Bleeds into Theme 7; replaced by investment |
| 6 | Add | investment | D | Distinctively financial; n=11, 2.1% |
| 7 | Add | analytics | B | "Data analytics" — specific to digital theme |
| 9 | Add | physical | B | "Physical space/environment/plant" — clean, no overlap |
| 9 | Add | capital | B | "Capital planning/investment" — flagged moderate overlap with Theme 6 |
| 10 | Add | leadership | B | Organizational leadership concept; flagged moderate overlap with Theme 5 |
| 10 | Add | transparency | B | "Transparency and accountability" — governance language |
| 11 | Add | knowledge | B | "Knowledge translation" — specific academic health science term |
| 11 | Drop | training | D | Bleeds into Theme 5; replaced by discovery |
| 11 | Add | discovery | D | "Discovery research" — academic health language; n=17, 3.3% |

---

## 5. Method C Findings — Unmatched Directions

- **Overall match rate: 96%** (502 of 523 directions matched at least one keyword)
- **21 unmatched directions** — not a keyword quality problem
- **Primary driver: French-language content** — francophone hospitals (Hawkesbury, Montfort, etc.) produce French strategic plans that English keyword matching cannot reach. These represent a distinct analytical stratum, not a gap.
- **Secondary driver: short directions** — a structural bias in the bag-of-words approach. Very short directions (1–3 tokens) have limited opportunity to match keywords. Not a fixable keyword problem.
- **Genuine gaps identified:** `rural` (added); `communicate/communication` too generic to add; `pandemic` and "Design for the Future" are temporal/aspirational outliers with no natural theme home
- **Manual coding decision deferred** — see Section 6 for open items

---

## 6. Open Items for Next Session

### Immediate
- **French-language stratum decision:** Run French detection code (flagging directions with `santé`, `les`, `aux`, `des`, etc.) and decide whether to exclude from match-rate denominator or flag as a separate analytical group. Code ready — not yet executed.
- **FAC 888 reprocessing:** English version of strategic plan identified. Add to corpus and rerun match once keyword set is confirmed stable.
- **Manual coding decision:** With ~21 unmatched directions and the majority being French or structural outliers, manual coding of the residual English unmatched (~5–8 directions) may not be worth the effort. Review the `method_c_unmatched.csv` file and make a final call at the start of next session.

### Next Active Step — Theme Assignment and Frequency Analysis
With the keyword set finalized, the next phase is:
1. Apply keyword matching to assign each of the 523 directions to one or more themes
2. Handle multi-theme directions (directions matching keywords from 2+ themes) — decision needed on whether to assign to primary theme, allow multi-assignment, or flag as ambiguous
3. Generate frequency counts by theme across the full hospital dataset
4. Begin comparative analysis by hospital type, region, and size

---

## 7. Key Technical Notes for New Session

### Environment
- **Working directory:** `E:/HospitalStrategyGemini/`
- **Output files:** `E:/HospitalStrategyGemini/Output/`
- **R scripts:** `E:/HospitalStrategyGemini/scripts/`
- **R graphics:** `E:/HospitalStrategyGemini/graphic/`

### Key Objects and Files
- `final_dataset.rds` — prime data source (523 rows × 14 cols); `Analysis_Corpus` clean of NF tags; `any_match` column added this session
- `final_dataset_BACKUP_20260226.rds` — pre-NF-cleaning backup
- `StrategicKeywordsv2.rds` — **finalized keyword set** (this session's primary output); 85 rows × 12 cols
- `StrategicKeywordsv2.csv` — CSV copy for inspection
- `method_c_unmatched.csv` — 21 unmatched directions with FAC codes for manual review
- `method_c_unmatched_freq.csv` — top 50 word frequencies in unmatched directions
- `method_d_candidates.csv` — full Method D candidate evaluation including corpus frequency counts
- `kwic_priority_themes_246.csv` — Method B context word outputs for Themes 2, 4, 6
- `kwic_remaining_themes.csv` — Method B context word outputs for Themes 1, 3, 5, 7, 8, 9, 10, 11
- `word_freq` — data.frame (2683 obs × 7 vars): word, n_occurrences, rank, pct_of_tokens, cumulative_pct, n_directions, pct_directions
- `bigrams100.csv` — top 100 bigrams (reviewed Session 3; reference only)

### French Detection Code (Ready to Run)
```r
final_dataset <- final_dataset |>
  mutate(
    is_french = str_detect(str_to_lower(Analysis_Corpus),
                           "\\b(santé|les|aux|des|pour|nous|notre|nos)\\b")
  )

# Recalculate match rate excluding French
final_dataset |>
  filter(!is_french) |>
  count(any_match) |>
  mutate(pct = round(n / sum(n) * 100, 1))
```

### Methodological Notes to Document
- **Length bias in keyword matching:** Short strategic directions (1–3 tokens) are structurally disadvantaged in bag-of-words matching. This is inherent to the method, not a keyword quality problem. Should be noted in methods section of any publication.
- **Francophone hospitals:** French-language strategic plans require either translation preprocessing or exclusion from keyword-based analysis. These hospitals may warrant separate treatment as a sub-group given distinct regulatory and community context.
- **96% match rate** is the reportable figure for English-language corpus coverage with the finalized keyword set.

---

*Document prepared: February 27, 2026*
*Next review: Start of Session 5*
*Owner: Skip*
