# מדריך שימוש - מאחד קוד חכם Pro 2.0

ברוכים הבאים למדריך המלא עבור מודול **מאחד קוד חכם Pro 2.0**. מדריך זה יסביר כיצד להשתמש במגוון התכונות והיכולות של המערכת.

## תוכן עניינים

1. [התקנה והפעלה](#התקנה-והפעלה)
2. [ניתוח קבצים](#ניתוח-קבצים)
3. [גרף קשרים](#גרף-קשרים)
4. [מיזוג קבצים](#מיזוג-קבצים)
5. [בדיקות אבטחה](#בדיקות-אבטחה)
6. [ממשק שורת פקודה](#ממשק-שורת-פקודה)
7. [עבודה עם API](#עבודה-עם-api)
8. [פתרון בעיות נפוצות](#פתרון-בעיות-נפוצות)

## התקנה והפעלה

### דרישות מקדימות

לפני התקנת המודול, ודא כי יש ברשותך:

- **Python 3.8** ומעלה
- **Node.js 14** ומעלה (לממשק המשתמש)
- **Git** (לשליפת קוד מקור)

### התקנה אוטומטית

הדרך הפשוטה ביותר להתקין את המודול היא באמצעות סקריפט ההתקנה:

```bash
./install.sh
```

סקריפט זה יבצע את הפעולות הבאות:
1. יצירת כל מבנה התיקיות הנדרש
2. התקנת כל תלויות Python הנדרשות
3. התקנת תלויות JavaScript (אם Node.js מותקן)
4. הורדת אייקונים ונכסים נוספים
5. יצירת קבצי לוג ראשוניים

### התקנה ידנית

אם תעדיף להתקין באופן ידני, בצע את הפעולות הבאות:

1. שכפל את המודול לתיקיית היעד:
   ```bash
   git clone https://github.com/user/smart-code-merger-pro.git
   cd smart-code-merger-pro
   ```

2. התקן את תלויות Python:
   ```bash
   pip install -r requirements.txt
   ```

3. התקן את תלויות JavaScript:
   ```bash
   npm install
   ```

4. צור את תיקיות הלוגים וההגדרות:
   ```bash
   mkdir -p logs
   ```

### הפעלה

לאחר ההתקנה, ניתן להפעיל את המודול בכמה דרכים:

1. **דרך ממשק הדפדפן**:
   ```bash
   python -m http.server 8000
   ```
   ואז פתח בדפדפן את הכתובת http://localhost:8000/ui/templates/index.html

2. **באמצעות ייבוא בקוד Python**:
   ```python
   from modules.smart_code_merger_pro.module import SmartCodeMerger
   
   merger = SmartCodeMerger()
   ```

3. **באמצעות ממשק שורת פקודה**:
   ```bash
   python module.py analyze-project /path/to/project
   ```

## ניתוח קבצים

אחד מהכלים החזקים במודול הוא יכולת הניתוח המתקדמת של קבצי קוד. המערכת מנתחת את הקבצים ואוספת מידע מקיף עליהם.

### שימוש בסיסי

```python
from modules.smart_code_merger_pro.module import SmartCodeMerger

# יצירת מופע חדש
merger = SmartCodeMerger()

# ניתוח קובץ בודד
file_analysis = merger.analyze_file("/path/to/file.py")

# ניתוח פרויקט שלם
project_analysis = merger.analyze_project("/path/to/project")
```

### נתוני ניתוח

המערכת אוספת את הנתונים הבאים עבור כל קובץ:

- **מידע בסיסי**: שם קובץ, גודל, תאריך עדכון אחרון וכו'
- **שפת תכנות**: זיהוי אוטומטי של שפת התכנות
- **מבנה קוד**: מחלקות, פונקציות, משתנים ועוד
- **סטטיסטיקות שורות**: קוד, הערות, שורות ריקות
- **מורכבות**: מדדי מורכבות ציקלומטית ועומק קינון
- **תלויות**: ייבואים, הכללות וקשרים לקבצים אחרים
- **רישיון**: זיהוי רישיון (אם קיים)

### סטטיסטיקות פרויקט

לאחר ניתוח פרויקט שלם, המערכת מחשבת סטטיסטיקות מסכמות:

- **מספר קבצים וגודל כולל**
- **התפלגות שפות תכנות**
- **סך שורות קוד, הערות ושורות ריקות**
- **מורכבות ממוצעת ומקסימלית**
- **תלויות נפוצות**

### סינון וחיפוש

ניתן לסנן את הניתוח לפי מספר קריטריונים:

```python
# ניתוח עם סינון סוגי קבצים
project_analysis = merger.analyze_project(
    "/path/to/project",
    include_subfolders=True,
    file_extensions=['.py', '.js']
)
```

## גרף קשרים

המודול יוצר גרף ויזואלי של הקשרים והתלויות בין קבצי הקוד.

### יצירת גרף

```python
# ניתוח קשרים בין קבצים ספציפיים
relationships = merger.analyze_relationships([
    "/path/to/file1.py",
    "/path/to/file2.py",
    "/path/to/file3.js"
])

# יצירת ויזואליזציה
merger.visualize_relationships(
    output_format="html",
    output_path="relationships.html"
)
```

### פורמטים נתמכים

- **HTML**: ויזואליזציה אינטראקטיבית
- **PNG/SVG/PDF**: תמונה סטטית
- **JSON/GraphML/DOT/GEXF**: פורמטים לניתוח מתקדם

### תכונות עיקריות בויזואליזציה

- **תצוגה מותאמת אישית**: גודל, צבע ומיקום קודקודים
- **סינון**: הצגה/הסתרה של סוגי קודקודים וקשרים
- **אנימציה**: פיזיקה דינמית והנפשה
- **חיפוש**: התמקדות בקודקודים ספציפיים
- **מידע**: הצגת מידע מפורט על כל קודקוד

### איתור תלויות מעגליות

```python
# חיפוש תלויות מעגליות
cycles = merger.find_cyclic_dependencies()

# ניתוח מקיף של תלויות
dependency_analysis = merger.analyze_dependencies()
```

תלויות מעגליות הן קשרים מעגליים בין קבצים שעשויים לגרום לבעיות תחזוקה ופיתוח.

### דוגמה לתוצאת ניתוח תלויות

```json
{
  "statistics": {
    "total_files": 15,
    "total_dependencies": 42,
    "avg_dependencies_per_file": 2.8
  },
  "central_files": [
    {
      "by_dependents": [
        {"node": "module.py", "score": 8, "name": "module.py"}
      ],
      "by_dependencies": [
        {"node": "file_analyzer.py", "score": 12, "name": "file_analyzer.py"}
      ]
    }
  ],
  "cyclic_dependencies": [
    {
      "nodes": ["file_analyzer.py", "relationship_graph.py", "module.py"],
      "names": ["file_analyzer.py", "relationship_graph.py", "module.py"],
      "length": 3
    }
  ]
}
```

## מיזוג קבצים

המודול מאפשר מיזוג חכם של קבצי קוד, עם יכולת לפתור קונפליקטים באופן אוטומטי.

### שימוש בסיסי

```python
# מיזוג שני קבצים
merger.merge_files(
    "/path/to/file1.py",
    "/path/to/file2.py",
    "/path/to/output.py",
    strategy="smart"
)
```

### אסטרטגיות מיזוג

- **smart**: שימוש באלגוריתם AI לבחירת החלקים הטובים ביותר מכל קובץ
- **keep-left**: העדפת הקובץ הראשון בקונפליקטים
- **keep-right**: העדפת הקובץ השני בקונפליקטים
- **both**: שמירת שתי הגרסאות בקונפליקטים (בהערות)

### זיהוי ופתרון קונפליקטים

המערכת מזהה קונפליקטים ברמות שונות:

1. **רמת טקסט**: שורות שהשתנו בשני הקבצים
2. **רמת תחביר**: שינויים בפונקציות או מחלקות זהות
3. **רמת סמנטיקה**: שינויים בהתנהגות או בלוגיקה

הפתרון החכם משתמש בניתוח מבני כדי לבחור את הפתרון המתאים ביותר לכל קונפליקט.

## בדיקות אבטחה

המודול מבצע סריקת אבטחה מקיפה לאיתור פגיעויות וחולשות בקוד.

### שימוש בסיסי

```python
# בקרוב - לאחר פיתוח מודול security_scanner
# security_results = merger.scan_security("/path/to/project")
```

### סוגי בדיקות

- **תלויות פגיעות**: בדיקת גרסאות חבילות עם פגיעויות ידועות
- **דפוסי קוד פגיעים**: זיהוי קוד העלול לגרום לחולשות אבטחה
- **סיסמאות וסודות בקוד**: זיהוי מפתחות, סיסמאות וסודות
- **בעיות רישוי**: בדיקת תאימות וחשיפת רישיונות

### דירוג פגיעויות

הממצאים מדורגים לפי רמות חומרה:

- **קריטי**: פגיעויות המחייבות טיפול מיידי
- **גבוה**: פגיעויות משמעותיות שיש לטפל בהן בהקדם
- **בינוני**: בעיות הדורשות טיפול לפי מדיניות
- **נמוך**: בעיות קטנות שיש להיות מודעים להן

## ממשק שורת פקודה

המודול כולל ממשק שורת פקודה לשימוש ישיר מהטרמינל.

### פקודות עיקריות

```bash
# ניתוח קובץ בודד
python module.py analyze-file /path/to/file.py --output results.json

# ניתוח פרויקט
python module.py analyze-project /path/to/project --extensions .py .js

# ניתוח קשרים
python module.py analyze-relationships /path/to/file1.py /path/to/file2.py --format json

# יצירת ויזואליזציה
python module.py visualize --format html --output graph.html

# מיזוג קבצים
python module.py merge /path/to/file1.py /path/to/file2.py /path/to/output.py --strategy smart
```

### פרמטרים גלובליים

- `--config`: נתיב לקובץ קונפיגורציה
- `--log-level`: רמת לוגים (debug, info, warning, error)

## עבודה עם API

המודול מספק API לשילוב עם מערכות אחרות.

### שימוש ב-Python

```python
from modules.smart_code_merger_pro.module import SmartCodeMerger

# יצירת מופע חדש עם קונפיגורציה מותאמת אישית
config = {
    "file_analyzer": {
        "max_file_size_mb": 50,
        "parallel_processing": True
    },
    "relationship_graph": {
        "max_nodes": 300,
        "layout_algorithm": "force_directed"
    }
}

merger = SmartCodeMerger(config_path="/path/to/config.json")
# או
merger = SmartCodeMerger(config)

# ניתוח קבצים
results = merger.analyze_project("/path/to/project")

# ייצוא תוצאות
merger.save_results("/path/to/results.json", format="json")
```

### שילוב עם CI/CD

ניתן לשלב את המודול במערכות CI/CD כדי לבצע בדיקות אוטומטיות:

```yaml
# דוגמה לקובץ GitHub Actions
name: Code Analysis

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.8'
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
      - name: Analyze code
        run: |
          python module.py analyze-project ./src --output analysis.json
      - name: Check for cyclic dependencies
        run: |
          python module.py analyze-relationships ./src/**/*.py --format json --output cycles.json
```

## פתרון בעיות נפוצות

### בעיות התקנה

**בעיה**: שגיאות בהתקנת תלויות Python
**פתרון**: ודא שיש לך Python 3.8 ומעלה וגרסת pip עדכנית
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**בעיה**: שגיאות בהתקנת תלויות JavaScript
**פתרון**: ודא שיש לך Node.js 14 ומעלה
```bash
npm cache clean --force
npm install
```

### בעיות ניתוח

**בעיה**: הניתוח נכשל עם שגיאת קידוד
**פתרון**: ציין את הקידוד הנכון בקונפיגורציה
```python
config = {
    "file_analyzer": {
        "default_encoding": "utf-8"  # או קידוד אחר
    }
}
```

**בעיה**: ניתוח איטי של פרויקטים גדולים
**פתרון**: התאם את הגדרות המקביליות והזיכרון
```python
config = {
    "file_analyzer": {
        "parallel_processing": True,
        "max_workers": 8
    }
}
```

### בעיות ויזואליזציה

**בעיה**: גרף גדול מדי ולא קריא
**פתרון**: הגבל את מספר הקודקודים והשתמש בפילטרים
```python
config = {
    "relationship_graph": {
        "max_nodes": 100,
        "min_edge_weight": 2
    }
}
```

**בעיה**: שגיאות בייצוא גרף לפורמטים מסוימים
**פתרון**: ודא שיש לך את הספריות הנדרשות
```bash
pip install pydot graphviz
```

---

למידע נוסף ועדכונים, בקר באתר הפרויקט או פנה לצוות התמיכה.
