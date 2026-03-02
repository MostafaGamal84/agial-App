# سيناريو الموبايل: تسجيل الدخول + إضافة/عرض/تعديل تقرير

> هذا الملف مبني على الاندبوينتس المستخدمة فعليًا في الواجهة الحالية (Angular) لتسهيل تسليمها لفريق الموبايل.

## 1) معلومات عامة

- **Base URL (Development):** `https://localhost:7260`.
- كل الاندبوينتس ترجع بنفس الغلاف (Envelope):

```json
{
  "isSuccess": true,
  "errors": [],
  "data": {},
  "message": null
}
```

### شكل الأخطاء

```json
{
  "isSuccess": false,
  "errors": [
    {
      "fieldName": "email",
      "code": "Invalid",
      "message": "Email or password is incorrect",
      "fieldLang": null
    }
  ],
  "data": null,
  "message": null
}
```

### Authorization

بعد تسجيل الدخول، بعت هيدر:

```http
Authorization: Bearer <token>
```

---

## 2) سيناريو تسجيل الدخول

### Endpoint

`POST /api/Account/Login`

### Request

```json
{
  "email": "user@example.com",
  "password": "P@ssw0rd"
}
```

### Validation (Client-Side الحالية)

- `email`: **required**
- `password`: **required**

> ملاحظة: الواجهة الحالية لا تطبق regex للإيميل، فقط required.

### Success Response (مثال)

```json
{
  "isSuccess": true,
  "errors": [],
  "data": {
    "token": "eyJ...",
    "refreshToken": "r1...",
    "username": "user@example.com",
    "fullName": "Ahmed Ali",
    "role": 3,
    "userId": 55,
    "branchId": 2
  },
  "message": null
}
```

### استخدام البيانات في الموبايل

- خزّن: `token`, `refreshToken`, `userId`, `role`, `username/fullName`.
- أي Request لاحق على الـ API يبقى مع `Bearer token`.

---

## 3) سيناريو شاشة إضافة تقرير (Create Report)

> الشاشة تعتمد على تحميل قوائم (مشرف/معلم/حلقة/طالب) حسب الدور قبل الإرسال.

### 3.1 Endpoints التحميل قبل الحفظ

#### A) جلب المشرفين
`GET /api/UsersForGroups/GetUsersForSelects?UserTypeId=3&managerId=0&teacherId=0&branchId=0&Filter=lookupOnly=true`

#### B) جلب المعلمين حسب المشرف
`GET /api/UsersForGroups/GetUsersForSelects?UserTypeId=4&managerId={managerId}&teacherId=0&branchId=0&Filter=lookupOnly=true`

#### C) جلب الحلقات حسب المعلم
`GET /api/Circle/GetResultsByFilter?SkipCount=0&MaxResultCount=...&teacherId={teacherId}`

#### D) جلب تفاصيل الحلقة + الطلاب
`GET /api/Circle/Get?id={circleId}`

---

### 3.2 Endpoint إنشاء التقرير

`POST /api/CircleReport/Create`

### Request (Body)

```json
{
  "managerId": 10,
  "teacherId": 25,
  "circleId": 8,
  "studentId": 145,
  "attendStatueId": 1,
  "minutes": 40,
  "newId": 2,
  "newFrom": "1",
  "newTo": "5",
  "generalRate": "ممتاز",
  "isVisual": true,
  "nextCircleOrder": "مراجعة سورة الملك",
  "recentPast": "جيد",
  "distantPast": "جيد جدًا",
  "farthestPast": "متوسط",
  "theWordsQuranStranger": "لا يوجد",
  "intonation": "جيد",
  "creationTime": "2026-02-20T18:30"
}
```

### Validation (حسب الحالة)

#### حقول مطلوبة دائمًا
- `circleId` required
- `studentId` required
- `attendStatueId` required

#### حسب دور المستخدم
- **Admin / Branch Manager / Supervisor:**
  - `managerId` required
  - `teacherId` required
- **Teacher:**
  - `teacherId` required (بيكون غالبًا ثابت من حسابه)

#### حسب حالة الحضور `attendStatueId`
- **حضر (Attended = 1):**
  - مطلوبة: `generalRate`, `isVisual`, `nextCircleOrder`
  - وباقي حقول التقييم متاحة (اختيارية):
    `newId`, `newFrom`, `newTo`, `recentPast`, `distantPast`, `farthestPast`, `theWordsQuranStranger`, `intonation`
- **تغيب بدون عذر (UnexcusedAbsence = 3):**
  - `minutes` required
- **تغيب بعذر (ExcusedAbsence = 2):**
  - لا توجد حقول تقييم إلزامية إضافية

### Success Response

```json
{
  "isSuccess": true,
  "errors": [],
  "data": true,
  "message": "Created successfully"
}
```

### Failure Response (Validation)

```json
{
  "isSuccess": false,
  "errors": [
    {
      "fieldName": "circleId",
      "code": "Required",
      "message": "Circle is required",
      "fieldLang": "الحلقة مطلوبة"
    }
  ],
  "data": false,
  "message": null
}
```

---

## 4) سيناريو عرض التقارير (List + Filters)

### Endpoint

`GET /api/CircleReport/GetResultsByFilter`

### Query Parameters المستخدمة

- Pagination:
  - `SkipCount`
  - `MaxResultCount`
- Search:
  - `SearchTerm`
  - `SearchWord` (اختياري)
- Filters:
  - `circleId`
  - `studentId`
  - `teacherId` (لما المستخدم Teacher)
  - `residentId` (اختياري)
  - `residentGroup` (`all | resident | nonResident` حسب تطبيق الموبايل)
- Sorting (اختياري):
  - `SortBy`
  - `SortingDirection`

### مثال Request

```http
GET /api/CircleReport/GetResultsByFilter?SkipCount=0&MaxResultCount=10&SearchTerm=&circleId=8&studentId=145
```

### Success Response (مثال)

```json
{
  "isSuccess": true,
  "errors": [],
  "data": {
    "totalCount": 207,
    "items": [
      {
        "id": 901,
        "creationTime": "2026-02-20T18:30:00",
        "circleId": 8,
        "circleName": "حلقة مسجد النور",
        "studentId": 145,
        "studentName": "محمد أحمد",
        "teacherId": 25,
        "teacherName": "عبدالله علي",
        "attendStatueId": 1,
        "minutes": 40,
        "generalRate": "ممتاز",
        "isVisual": true,
        "nextCircleOrder": "مراجعة سورة الملك"
      }
    ]
  },
  "message": null
}
```

---

## 5) سيناريو تعديل تقرير

> التعديل في الواجهة الحالية يتم عبر خطوتين: جلب التقرير ثم إرسال تحديث.

### 5.1 جلب التقرير للتعديل

`GET /api/CircleReport/Get?id={reportId}`

### Success Response (مثال)

```json
{
  "isSuccess": true,
  "errors": [],
  "data": {
    "id": 901,
    "circleId": 8,
    "studentId": 145,
    "teacherId": 25,
    "attendStatueId": 1,
    "minutes": 40,
    "generalRate": "ممتاز",
    "isVisual": true,
    "nextCircleOrder": "مراجعة سورة الملك",
    "creationTime": "2026-02-20T18:30:00"
  },
  "message": null
}
```

### 5.2 تحديث التقرير

`POST /api/CircleReport/Update`

### Request

> نفس Body الإنشاء + `id`.

```json
{
  "id": 901,
  "teacherId": 25,
  "circleId": 8,
  "studentId": 145,
  "attendStatueId": 3,
  "minutes": 20,
  "creationTime": "2026-02-20T18:30"
}
```

### Validation

- نفس قواعد Validation الخاصة بإنشاء التقرير.
- `id` لازم يكون موجود وصحيح (> 0).

### Success Response

```json
{
  "isSuccess": true,
  "errors": [],
  "data": true,
  "message": "Updated successfully"
}
```

---

## 6) Endpoint إضافي مستخدم في شاشة القائمة

### حذف تقرير
`POST /api/CircleReport/Delete?id={reportId}`

Response:

```json
{
  "isSuccess": true,
  "errors": [],
  "data": true,
  "message": "Deleted"
}
```

---

## 7) ترتيب التنفيذ المقترح على الموبايل

1. Login → خزّن `token`.
2. افتح List → `GetResultsByFilter`.
3. عند Add Report:
   - حمّل مشرفين/معلمين/حلقات/طلاب بالتسلسل حسب الدور.
   - ابعت `Create`.
4. عند Edit Report:
   - `Get?id=...` لملء الفورم.
   - ابعت `Update`.
5. كل Request مؤمن بـ `Bearer token`.

---

## 8) ملاحظات مهمة لفريق الموبايل

- اسم الحقل القادم من الباك-إند هو `attendStatueId` (بنفس الكتابة الحالية)، فخلّي الموديل في الموبايل مطابق له.
- قيم `role` قد ترجع رقم أو string، فاعمل parse قبل المقارنة.
- لو `isSuccess=false` اعرض أول رسالة في `errors[0].message` للمستخدم.
- في حالة `401` اعمل logout/refresh-token flow حسب سياسة التطبيق.
