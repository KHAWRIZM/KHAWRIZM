
# Topic: إنشاء تذكرة دعم في CometX

- اجمع المتغيرات:
  - {title:string} "عنوان المشكلة؟"
  - {severity:enum(Low,Medium,High,Critical)} "درجة الخطورة؟"
  - {details:string?} "تفاصيل إضافية (اختياري)."

- Call Action: Connector → CometX → CreateTicket
  - Inputs:
    - body.title = {title}
    - body.severity = {severity}
    - body.details = {details}
  - Store outputs:
    - {ticketId} <- result.id
    - {ticketStatus} <- result.status

- Reply:
  "تم فتح التذكرة رقم {ticketId} بحالة {ticketStatus}."
