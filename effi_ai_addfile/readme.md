# Smart Code Merger Pro 2.0 - מאחד קוד חכם

![גרסה](https://img.shields.io/badge/גרסה-2.0.0-blue)
![רישיון](https://img.shields.io/badge/רישיון-MIT-green)
![שפת פיתוח](https://img.shields.io/badge/שפה-Python-yellow)

מודול מתקדם לניתוח, זיהוי ומיזוג של קבצי קוד במערכת Effi-AI-privet. המודול מספק יכולות מתקדמות לניתוח קבצים, זיהוי קשרים בין רכיבי קוד, וויזואליזציה של מבנה פרויקטים.

## 📋 תכונות עיקריות

- **ניתוח מעמיק של קבצי קוד** - זיהוי שפות, ניתוח מבנה, חילוץ תלויות ומדדי איכות קוד
- **גרף קשרים** - יצירת גרף קשרים בין קבצים, ניתוח תלויות והצגה ויזואלית
- **זיהוי פרויקטים** - זיהוי אוטומטי של סוגי פרויקטים ומסגרות העבודה שלהם
- **מיזוג חכם** - מיזוג אינטליגנטי של קבצי קוד תוך פתרון קונפליקטים
- **בדיקות אבטחה** - סריקת חולשות אבטחה וקוד פגיע
- **ניהול גרסאות** - מעקב אחר שינויים והשוואת גרסאות
- **למידת מכונה** - שימוש באלגוריתמי למידת מכונה לשיפור הניתוח והזיהוי

## ⚙️ דרישות מערכת

- Python 3.8 ומעלה
- [רשימת חבילות Python הנדרשות](requirements.txt)
- Node.js 14 ומעלה (עבור ממשק המשתמש)
- [רשימת חבילות Node.js הנדרשות](package.json)

## 🚀 התקנה

```bash
# התקנה באמצעות סקריפט ההתקנה האוטומטי
./install.sh

# או התקנה ידנית
pip install -r requirements.txt
npm install
```

## 🔄 שימוש בסיסי

```python
from modules.smart_code_merger_pro.module import SmartCodeMerger

# יצירת אובייקט חדש
merger = SmartCodeMerger()

# ניתוח פרויקט
project_info = merger.analyze_project("/path/to/project")

# ניתוח קובץ בודד
file_analysis = merger.analyze_file("/path/to/file.py")

# ניתוח קשרים בין קבצים
relationships = merger.analyze_relationships(["/path/to/file1.py", "/path/to/file2.py"])

# מיזוג קבצים
merged_result = merger.merge_files("/path/to/file1.py", "/path/to/file2.py", "/path/to/output.py")
```

## 📊 דוגמה לויזואליזציית גרף קשרים

```python
from modules.smart_code_merger_pro.core.relationship_graph import RelationshipGraph

# יצירת מנהל גרף קשרים
graph_manager = RelationshipGraph()

# בניית גרף מתוצאות ניתוח
graph_manager.build_graph_from_analysis(analysis_results)

# שמירת הגרף כתמונה
graph_manager.visualize(output_format="png", output_path="project_graph.png")

# יצירת ויזואליזציה אינטראקטיבית
html_visualization = graph_manager.get_html_visualization()
with open("interactive_graph.html", "w", encoding="utf-8") as f:
    f.write(html_visualization)
```

## 📁 מבנה המודול

```
modules/smart_code_merger_pro/
├── module.py                    # מודול ראשי
├── metadata.json                # מידע על המודול
├── README.md                    # תיעוד
├── requirements.txt             # תלויות Python
├── package.json                 # תלויות JavaScript
├── install.sh                   # סקריפט התקנה
├── preview.html                 # תצוגה מקדימה
├── core/                        # מודולי ליבה
│   ├── file_analyzer.py         # מנתח קבצים
│   ├── relationship_graph.py    # גרף קשרים
│   ├── project_detector.py      # זיהוי פרויקטים
│   ├── code_merger.py           # מיזוג קוד
│   ├── security_scanner.py      # סריקת אבטחה
│   ├── version_manager.py       # ניהול גרסאות
│   ├── code_runner.py           # הרצת קוד
│   ├── code_completer.py        # השלמת קוד
│   ├── document_analyzer.py     # ניתוח מסמכים
│   └── log_manager.py           # ניהול לוגים
├── api/                         # ממשקי API
│   ├── api_manager.py           # ניהול API
│   ├── export_import.py         # ייצוא ויבוא
│   └── ci_cd_integration.py     # אינטגרציית CI/CD
├── utils/                       # כלי עזר
│   ├── remote_storage.py        # אחסון מרוחק
│   └── helpers.py               # פונקציות עזר
├── ui/                          # ממשק משתמש
│   ├── templates/
│   │   ├── index.html           # עמוד ראשי
│   │   └── preview.html         # תצוגה מקדימה
├── assets/                      # נכסים
│   ├── css/
│   │   └── style.css            # עיצוב
│   ├── js/
│   │   └── app.js               # JavaScript
│   └── images/                  # תמונות ואייקונים
├── logs/                        # תיקיית לוגים
└── docs/                        # תיעוד מפורט
    └── manual.md                # מדריך שימוש
```

## 📋 פונקציות עיקריות

### מנתח קבצים (FileAnalyzer)

- `analyze_file(file_path)`: ניתוח קובץ בודד
- `analyze_files(file_paths)`: ניתוח מספר קבצים במקביל
- `calculate_project_statistics(file_paths)`: חישוב סטטיסטיקות לפרויקט

### גרף קשרים (RelationshipGraph)

- `build_graph_from_analysis(analysis_results)`: בניית גרף מתוצאות ניתוח
- `visualize(output_format, output_path)`: יצירת ויזואליזציה של הגרף
- `find_cyclic_dependencies()`: איתור תלויות מעגליות
- `analyze_dependencies()`: ניתוח מקיף של תלויות

### זיהוי פרויקטים (ProjectDetector) - בפיתוח

- `detect_project_type(directory)`: זיהוי סוג הפרויקט
- `detect_frameworks(directory)`: זיהוי מסגרות עבודה (frameworks)
- `analyze_project_structure(directory)`: ניתוח מבנה הפרויקט

### מיזוג קוד (Merger) - בפיתוח

- `merge_files(file1, file2, output)`: מיזוג שני קבצים
- `resolve_conflicts(conflicts)`: פתרון קונפליקטים במיזוג
- `smart_merge(sources, output)`: מיזוג חכם של מספר מקורות

## 📈 תמיכה בשפות

המודול תומך במגוון רחב של שפות תכנות, כולל:

- Python
- JavaScript / TypeScript
- Java
- C / C++
- C#
- Go
- Ruby
- PHP
- Swift
- Kotlin
- Scala
- HTML / CSS
- Shell scripts

## 🔑 רישוי

מודול זה מופץ תחת רישיון MIT. ראה את קובץ LICENSE למידע נוסף.

## 👥 תרומה

אנו מעודדים תרומות למודול. אנא עקבו אחר הנהלים הבאים:

1. פתחו נושא (issue) לדיון בתכונה או בבאג
2. מזגו את הקוד העדכני ביותר מהענף הראשי
3. פתחו בקשת משיכה (pull request) עם השינויים שלכם

## 📮 יצירת קשר

לכל שאלה או בעיה, אנא צרו קשר עם צוות הפיתוח:
- שם: Shay AI
- דוא"ל: dev@effi-ai-privet.com
