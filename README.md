# ExamPrep BD

1. Extract this ZIP and open a terminal in the extracted folder.
2. Install Node.js 20.9 or newer, then run `npm ci` and `npm run dev`.
3. Open http://localhost:3000.

The app starts with 72 original practice MCQs. To get an import template, open Question Bank → JSON ↓, CSV ↓, or XLSX ↓. Import an extracted `.json`, `.csv`, or `.xlsx` file, not a ZIP. Keep the exported columns and use answer indices 0–3. In CSV/Excel the options cell contains a JSON array of four strings. Match subject/topic/subtopic names to the Syllabus tab. Imported historical claims must be reviewed before counting as verified.

Study progress, edits and exam attempts are saved in the current browser, not in this ZIP. Question Bank exports contain questions only. Supabase is not wired up; `supabase/schema.sql` is a starting schema, not a live backend.
