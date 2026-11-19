# ExamPrep BD — Foundation

## বর্তমান অবস্থা
বাংলা অনুশীলন পরীক্ষা বিদ্যমান: এক পৃষ্ঠায় প্রশ্ন, ব্রাউজার টাইমার, ফলাফল ও ব্যাখ্যা। এটি লাইভ পরীক্ষা নয়। নতুন SQL migrations এখনও কোনো Supabase প্রকল্পে চালানো হয়নি এবং UI-এর সঙ্গে সংযুক্ত নয়। পুরনো `supabase/schema.sql` legacy prototype; fresh backend-এ শুধু `supabase/migrations/` ক্রমানুসারে চালাতে হবে।

## স্তর ও দায়িত্ব
- **Next.js App Router**: পাবলিক হোম ও সিলেবাস; `/student` ব্যক্তিগত অংশ; `/admin` কর্মীদের অংশ। প্রস্তুতি, অনুশীলন, লাইভ সময়সূচি, রুটিন, PDF ও ফলাফল পৃথক ফিচার। বিদ্যমান সরল পরীক্ষা UI অনুশীলনের ভিত্তি।
- **Supabase Auth**: ইমেইল যাচাই, লগইন/লগআউট, reset callback এবং SSR cookie session। অ্যানন/পাবলিশেবল key ক্লায়েন্টে; service-role key কেবল সার্ভারের secret। ছাত্রদের জন্য role row প্রয়োজন নেই; admin এবং super_admin আলাদা role values, role grant এখন privileged bootstrap মাত্র।
- **PostgreSQL**: সিলেবাস সংস্করণ → বিষয় → অধ্যায়/টপিক → সাবটপিক → প্রশ্ন ও উৎস। `auth.users` পরিচয়; `profiles` পছন্দ। প্রশ্নের ৪টি অপশন একটি constrained array; প্রকাশের সময় লাইভ প্রশ্ন ও উত্তর immutable snapshot। ছাত্রের রুটিন, bookmarks, revision ও progress-এ owner RLS।
- **লাইভ**: প্রকাশিত সময়সূচি → `enter_live` → `save_live_answer` → `submit_live` → `live_result`। সময় `timestamptz`; দেখানো ও অ্যাডমিন ইনপুট Asia/Dhaka। প্রবেশ ও save RPC ডেটাবেজের ঘড়ি ব্যবহার করে। Deadline = পরীক্ষার close অথবা ব্যক্তিগত সময়সীমা, যেটি আগে। একটি session/student/exam; save ও submit একই locked session row ব্যবহার করে। ফল প্রকাশের আগে ব্যাখ্যা ও answer key দেওয়া হয় না। নির্ধারিত server scheduler-কে `finalize_expired` চালাতে হবে; এটি এখনও কনফিগার করা হয়নি।
- **PDF**: প্রস্তাবিত আলাদা server/worker renderer, Chromium-এ স্থানীয় বাংলা ফন্ট লোড করে A4 PDF তৈরি, `application/pdf` ও attachment header দিয়ে পাঠানো। রুটিন/ফলাফল access প্রথমে যাচাই করতে হবে। ব্যক্তিগত PDF public cache-এ নয়। এই renderer এখনো নেই।

## UI ডিজাইন সিস্টেম
- Surface: সাদা, page tint `#f6f7fc`, text navy `#14203b`, action indigo `#4338ca`, secondary text `#53617a`, border `#dce2ef`। Dark theme: navy background `#0e1529`, surface `#18223d`, text `#edf0fd`।
- Noto Sans Bengali locally hosted করার লক্ষ্য; keyboard focus দৃশ্যমান, বোতামে বোধগম্য বাংলা নাম, error শুধু রং দিয়ে নয়। সর্বনিম্ন control height 44px।
- Dashboard: প্রথম কাজ/পরবর্তী পরীক্ষা আগে, তারপর রুটিন ও বাস্তব ফল। চার্ট শুধু performance view। পরীক্ষার পেজে sidebar/চার্ট নয়; sticky countdown, single/all layout, স্পষ্ট প্রশ্ন অবস্থা। English ও Mathematics-এর প্রশ্ন ইংরেজিতে থাকতে পারে।

## পরবর্তী কাজ, ক্রমানুসারে
1. Supabase dev project-এ migration smoke test; SSR authentication, role tests, recovery callback এবং rate limits।
2. BPSC মূল নথি সংগ্রহ এবং দ্বৈত পর্যালোচনায় topic-by-topic নথিভুক্ত করা; EEE বিজ্ঞপ্তির উৎস আলাদা। বর্তমান সংক্ষিপ্ত taxonomy পূর্ণাঙ্গ অফিসিয়াল সিলেবাস নয়।
3. Staff publish UI ও live student UI; job scheduler, ফল প্রকাশ, pagination, ranking এবং audit trail।
4. প্রমাণ-নির্ভর routine, revision, student analytics এবং বাংলা downloadable PDFs।
5. Concurrent load, database security, PDF font embedding, mobile/browser validation; staging থেকে production।
