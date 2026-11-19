# ExamPrep BD — BCS-first + EEE Job Preparation

A Next.js application with two separate tracks: (1) BCS preliminary preparation using a detailed 10-subject syllabus structure and the 50th BCS reported marks distribution, and (2) EEE technical recruitment preparation.

## Run locally

Requirements: Node.js 20+.

```bash
npm install
npm run dev
```

Open http://localhost:3000.

For production build:

```bash
npm run build
npm start
```

## Current features

- Separate BCS and EEE tracks and topic/subtopic syllabus navigation.
- BCS syllabus hierarchy expanded against the BPSC preliminary syllabus topics. The marks shown are the 50th regular BCS preliminary distribution reported in December 2025; always check the current BPSC circular/syllabus for the target exam.
- EEE recruitment syllabus covering circuits, machines, power systems, power electronics, control systems, measurements, electronics, installation, renewable energy, microprocessors and engineering mathematics.
- Timed daily mock exam with a minimum of 30 questions, questions from at least two subjects, countdown and automatic submission on timeout.
- Custom practice, bookmarks, question bank import/export, performance analytics and spaced revision.
- Routine generator and printable routine. Use **Download routine PDF** and choose **Save as PDF** in the browser print dialog.
- Browser-local persistence.

## Important limitations

- This is a local starter app, not a hosted public website.
- The current question bank contains 72 clearly labelled original demo questions (36 per track). They are not a verified BCS past-paper database and do not establish full BCS-standard question coverage. A 30-question paper can be generated from this seed, but repeated use will expose a small pool. Add a carefully reviewed question bank before relying on it for serious preparation.
- A true simultaneous live exam for many candidates, fixed server-side opening/closing times, tamper-resistant submission, leaderboards and centralized result publication require a backend, database, authentication and server-side exam scheduler. The present timer/auto-submit works only in the current browser session and local browser storage; it is a timed mock, not a centrally synchronized live exam.
- Progress and question records are stored in this browser only. There is no cloud sync or multi-device account system.
- Routine PDF export uses the browser's print-to-PDF function.

## Question import

Export the question bank as JSON or Excel to use as an import template. Imported past-paper records are downgraded to `Unverified past paper` until a human checks the question, answer and citation.
