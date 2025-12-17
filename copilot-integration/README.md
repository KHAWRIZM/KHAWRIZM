
# تكامل GraTech CometX مع Microsoft Copilot Studio

هذا المشروع يوفّر **هيكل تكامل كامل** بين CometX و Copilot Studio باستخدام **Custom Connector** مبنيّ على **OpenAPI 2.0 (Swagger)**، مع **Environment Variables** في Dataverse، و**ملفات توثيق** و**نماذج Topics/Actions**.

## لماذا هذا النهج؟
- دعم استدعاء الموصلات كـ **Tools/Actions** مباشرة داخل Copilot Studio.\[1]\[2]
- إنشاء موصلات مخصّصة من **OpenAPI 2.0** مع امتدادات x-ms لتحسين تجربة المستخدم.\[3]
- إدارة إعدادات البيئة عبر **Environment Variables** في الحلول (Solutions) للـ ALM.\[4]

## المتطلبات
- صلاحية الوصول إلى **Power Apps/Automate** و **Copilot Studio** داخل التينانت.
- نطاق CometX: `api.gratech.sa` ومسار أساس `\_/api/v1` (قابل للتعديل).
- اختيار نمط المصادقة: **API Key** أو **OAuth2 (Entra ID)**.

## البدء السريع
1. أنشئ **Environment Variables** المذكورة في `solution/environment-variables.md`.
2. استورد الموصل من `openapi/cometx.connector.openapi.v2.json` داخل حلّك.\[5]\[6]
3. في **Copilot Studio** أضِف Action من الموصل داخل الوكيل/Topic.\[7]
4. (اختياري) استخدم Power Automate للسيناريوهات متعددة الخطوات.

## مراجع
[1] Use connectors in Copilot Studio agents – Microsoft Learn.  
[2] Create REST API actions for custom agents – Release plan (Copilot Studio).  
[3] OpenAPI extensions for custom connectors – Microsoft Learn.  
[4] Use environment variables in solution custom connectors – Microsoft Learn.  
[5] Create a custom connector from an OpenAPI definition – Microsoft Learn.  
[6] Build and certify custom connectors – Microsoft Learn.  
[7] Supercharge Copilot with Custom Actions – Jamie McAllister.
