
# Environment Variables (Dataverse)

أنشئ المتغيرات التالية داخل **Solution** ثم استخدم صيغة الإحالة داخل حقول الموصل:

- `COMETX_API_HOST` = `api.gratech.sa`
- `COMETX_API_BASEPATH` = `/api/v1`
- (اختياري) `COMETX_API_KEY` (Secret)
- (اختياري) `COMETX_OAUTH_CLIENT_ID`, `COMETX_OAUTH_TENANT_ID`, `COMETX_OAUTH_SCOPE` (Secrets)

**صيغة الإحالة داخل الموصل:**
```
@environmentVariables("crxx_COMETX_API_HOST")
@environmentVariables("crxx_COMETX_API_BASEPATH")
```
> تذكير: بعد تغيير القيم يجب **إعادة حفظ الموصل** كي يعتمد القيم الجديدة.\[1]

مرجع: Use environment variables in solution custom connectors – Microsoft Learn.
