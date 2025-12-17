
# Power Automate (اختياري) – تدفّق احتياطي

سيناريو: إنشاء تذكرة ثم إرسال إشعار Teams/بريد.

**مدخلات من Copilot:** `title`, `severity`, `details`
**خطوات مقترحة:**
1. HTTP (POST) إلى `/tickets`.
2. Create message في Teams أو Send email في Outlook.
3. إرجاع `{ticketId}` و `{status}` إلى Copilot.

مرجع: Integrating Copilot Studio with Power Automate – مقال إرشادي.
