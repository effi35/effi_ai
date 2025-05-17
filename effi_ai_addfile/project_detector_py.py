#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול זיהוי פרויקטים למאחד קוד חכם Pro 2.0
מספק זיהוי אוטומטי ואינטליגנטי של סוגי פרויקטים מקבצים שונים

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import sys
import json
import logging
import hashlib
import itertools
import subprocess
import collections
import concurrent.futures
from typing import Dict, List, Tuple, Any, Optional, Union, Set
from pathlib import Path

try:
    import numpy as np
    import joblib
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.cluster import DBSCAN
    from sklearn.metrics.pairwise import cosine_similarity
    from sklearn.ensemble import RandomForestClassifier
    ML_AVAILABLE = True
except ImportError:
    ML_AVAILABLE = False
    

# הגדרת לוגים
logger = logging.getLogger(__name__)

class ProjectDetector:
    """
    מזהה פרויקטים חכם - מזהה וממיין קבצים לפרויקטים לוגיים על בסיס חתימות ותבניות
    
    יכולות:
    - זיהוי אוטומטי של סוגי פרויקטים לפי מבנה קבצים וחתימות
    - מיפוי קשרי תלות בין קבצים
    - קיבוץ קבצים קשורים לפרויקטים לוגיים
    - זיהוי טכנולוגיות ושפות תכנות בקבצים
    - ניתוח היסטוגרמת שפות בפרויקט
    - טיפול במקרי קצה וסתירות
    """
    
    def __init__(self, config: dict = None):
        """אתחול מזהה הפרויקטים עם הגדרות אופציונליות"""
        self.config = config or {}
        self.min_file_count = self.config.get("min_file_count", 5)
        self.detection_methods = self.config.get("detection_methods", ["file_structure", "dependency_analysis", "signature_matching"])
        self.project_types = self.config.get("project_types", ["nodejs", "python", "java", "web", "cpp", "android", "ios"])
        self.detection_confidence_threshold = self.config.get("detection_confidence_threshold", 0.7)
        self.max_workers = self.config.get("max_workers", 4)
        
        # טעינת חתימות פרויקטים
        self.project_signatures = self._load_project_signatures()
        
        # מודל למידת מכונה לזיהוי פרויקטים
        self.ml_model = None
        self.vectorizer = None
        if ML_AVAILABLE and self.config.get("use_ml", True):
            self._init_ml_components()
        
        logger.info(f"מזהה פרויקטים אותחל: ML זמין={ML_AVAILABLE}, שיטות={self.detection_methods}")

    def _load_project_signatures(self) -> Dict[str, Any]:
        """
        טעינת חתימות וסמנים לסוגי פרויקטים שונים
        
        Returns:
            מילון המכיל חתימות וסמנים לכל סוג פרויקט
        """
        # חתימות פרויקטים מובנות
        signatures = {
            "nodejs": {
                "files": ["package.json", "package-lock.json", "node_modules", "npm-debug.log"],
                "dir_patterns": ["node_modules", "dist", "build"],
                "file_patterns": [".*\\.js$", ".*\\.jsx$", ".*\\.ts$", ".*\\.tsx$"],
                "dependency_packages": ["express", "react", "vue", "angular", "axios", "lodash"],
                "metadata_files": ["package.json", "tsconfig.json", "webpack.config.js", "babel.config.js"]
            },
            "python": {
                "files": ["requirements.txt", "setup.py", "Pipfile", "pyproject.toml", "__init__.py"],
                "dir_patterns": ["venv", ".venv", "__pycache__", ".pytest_cache"],
                "file_patterns": [".*\\.py$", ".*\\.pyw$", ".*\\.ipynb$"],
                "dependency_packages": ["django", "flask", "numpy", "pandas", "tensorflow", "pytorch"],
                "metadata_files": ["setup.py", "requirements.txt", "pyproject.toml"]
            },
            "java": {
                "files": ["pom.xml", "build.gradle", "gradlew", "mvnw", "settings.gradle"],
                "dir_patterns": ["src/main/java", "src/test/java", "target", "build"],
                "file_patterns": [".*\\.java$", ".*\\.class$", ".*\\.jar$", ".*\\.jsp$"],
                "dependency_packages": ["org.springframework", "com.google.guava", "junit", "log4j"],
                "metadata_files": ["pom.xml", "build.gradle", "gradle.properties", "settings.gradle"]
            },
            "web": {
                "files": ["index.html", "styles.css", "style.css", "main.js", "index.js"],
                "dir_patterns": ["css", "js", "images", "fonts", "assets"],
                "file_patterns": [".*\\.html$", ".*\\.css$", ".*\\.scss$", ".*\\.less$"],
                "dependency_packages": ["bootstrap", "jquery", "tailwindcss", "normalize.css"],
                "metadata_files": ["index.html", "webpack.config.js", "postcss.config.js", "vite.config.js"]
            },
            "cpp": {
                "files": ["CMakeLists.txt", "Makefile", "compile_commands.json", ".clang-format"],
                "dir_patterns": ["src", "include", "build", "lib", "bin"],
                "file_patterns": [".*\\.c$", ".*\\.cpp$", ".*\\.cc$", ".*\\.h$", ".*\\.hpp$"],
                "dependency_packages": ["boost", "eigen", "opencv", "gtest"],
                "metadata_files": ["CMakeLists.txt", "Makefile", "compile_commands.json"]
            },
            "android": {
                "files": ["AndroidManifest.xml", "build.gradle", "gradle.properties", "gradlew"],
                "dir_patterns": ["app/src/main", "app/src/test", "app/src/androidTest", "app/build"],
                "file_patterns": [".*\\.java$", ".*\\.kt$", ".*\\.xml$", ".*\\.gradle$"],
                "dependency_packages": ["androidx", "com.google.android", "kotlin", "retrofit"],
                "metadata_files": ["AndroidManifest.xml", "build.gradle", "gradle.properties"]
            },
            "ios": {
                "files": ["Info.plist", "AppDelegate.swift", "AppDelegate.m", "*.xcodeproj", "*.xcworkspace"],
                "dir_patterns": ["Assets.xcassets", "Base.lproj", "Pods"],
                "file_patterns": [".*\\.swift$", ".*\\.m$", ".*\\.h$", ".*\\.storyboard$", ".*\\.xib$"],
                "dependency_packages": ["UIKit", "Foundation", "CoreData", "SwiftUI"],
                "metadata_files": ["Info.plist", "Podfile", "project.pbxproj", "Package.swift"]
            },
            "flutter": {
                "files": ["pubspec.yaml", "pubspec.lock", "analysis_options.yaml", ".metadata"],
                "dir_patterns": ["lib", "test", "build", "android", "ios", "web"],
                "file_patterns": [".*\\.dart$"],
                "dependency_packages": ["flutter", "provider", "bloc", "dio", "sqflite"],
                "metadata_files": ["pubspec.yaml", "pubspec.lock", "analysis_options.yaml"]
            },
            "dotnet": {
                "files": ["*.csproj", "*.sln", "appsettings.json", "Program.cs", "Startup.cs"],
                "dir_patterns": ["bin", "obj", "Properties", "wwwroot", "Controllers", "Views", "Models"],
                "file_patterns": [".*\\.cs$", ".*\\.cshtml$", ".*\\.vb$", ".*\\.razor$"],
                "dependency_packages": ["Microsoft.Extensions", "Microsoft.AspNetCore", "Microsoft.EntityFrameworkCore"],
                "metadata_files": ["*.csproj", "*.sln", "appsettings.json", "global.json"]
            },
            "go": {
                "files": ["go.mod", "go.sum", "main.go", "Makefile"],
                "dir_patterns": ["cmd", "pkg", "internal", "vendor", "test"],
                "file_patterns": [".*\\.go$"],
                "dependency_packages": ["github.com/gorilla/mux", "github.com/gin-gonic/gin", "golang.org/x/sync"],
                "metadata_files": ["go.mod", "go.sum", "Makefile", "golangci.yml"]
            },
            "ruby": {
                "files": ["Gemfile", "Gemfile.lock", "Rakefile", "config.ru", "*.gemspec"],
                "dir_patterns": ["app", "bin", "config", "db", "lib", "test", "spec"],
                "file_patterns": [".*\\.rb$", ".*\\.erb$", ".*\\.rake$"],
                "dependency_packages": ["rails", "sinatra", "rspec", "activerecord"],
                "metadata_files": ["Gemfile", "Gemfile.lock", "config.ru", "*.gemspec"]
            },
            "php": {
                "files": ["composer.json", "composer.lock", "index.php", "artisan", ".htaccess"],
                "dir_patterns": ["vendor", "public", "app", "src", "bootstrap", "resources"],
                "file_patterns": [".*\\.php$", ".*\\.phtml$"],
                "dependency_packages": ["laravel", "symfony", "wordpress", "guzzlehttp"],
                "metadata_files": ["composer.json", "composer.lock", "artisan", ".htaccess"]
            },
            "rust": {
                "files": ["Cargo.toml", "Cargo.lock", "src/main.rs", "src/lib.rs"],
                "dir_patterns": ["src", "target", "tests", "examples", "benches"],
                "file_patterns": [".*\\.rs$"],
                "dependency_packages": ["serde", "tokio", "actix-web", "diesel", "clap"],
                "metadata_files": ["Cargo.toml", "Cargo.lock", "rust-toolchain.toml"]
            }
        }
        return signatures

    def _init_ml_components(self) -> None:
        """
        אתחול רכיבי למידת מכונה לזיהוי פרויקטים
        """
        try:
            self.vectorizer = TfidfVectorizer(
                analyzer='word',
                ngram_range=(1, 2),
                max_features=1000,
                stop_words='english'
            )
            
            # ניסיון לטעון מודל קיים או ליצור מודל חדש אם אינו קיים
            model_path = os.path.join(os.path.dirname(__file__), 'models', 'project_classifier.joblib')
            if os.path.exists(model_path):
                logger.info(f"טוען מודל קיים מ-{model_path}")
                clf = joblib.load(model_path)
                self.ml_model = clf
            else:
                logger.info("יוצר מודל RandomForest חדש (לא מאומן)")
                # יצירת מודל בסיסי שיאומן במהלך השימוש
                self.ml_model = RandomForestClassifier(
                    n_estimators=100,
                    max_depth=None,
                    min_samples_split=2,
                    random_state=42
                )
        except Exception as e:
            logger.error(f"שגיאה באתחול רכיבי למידת מכונה: {str(e)}")
            self.ml_model = None
            self.vectorizer = None

    def detect_projects(self, files: List[str]) -> List[Dict[str, Any]]:
        """
        זיהוי פרויקטים מתוך רשימת קבצים
        
        Args:
            files: רשימת נתיבי קבצים לניתוח
            
        Returns:
            רשימת פרויקטים שזוהו (כל פרויקט הוא מילון עם מזהה, שם, סוג, רשימת קבצים, וכו')
        """
        if not files:
            logger.warning("לא סופקו קבצים לזיהוי פרויקטים")
            return []
        
        logger.info(f"מתחיל זיהוי פרויקטים עבור {len(files)} קבצים")
        
        try:
            # שלב 1: קבלת תמונה ראשונית של תיקיות ומבנה הקבצים
            file_structure = self._analyze_file_structure(files)
            
            # שלב 2: זיהוי פרויקטים על בסיס סמנים וחתימות ידועים
            signature_projects = self._detect_by_signatures(file_structure)
            logger.info(f"זוהו {len(signature_projects)} פרויקטים לפי חתימות")
            
            # שלב 3: זיהוי קשרי תלות בין קבצים
            dependency_groups = self._analyze_dependencies(files)
            
            # שלב 4: שילוב תוצאות לרשימת פרויקטים סופית
            candidate_projects = self._merge_detection_results(signature_projects, dependency_groups, file_structure)
            
            # שלב 5: ניתוח וסיווג פרויקטים עם למידת מכונה (אם זמין)
            if ML_AVAILABLE and self.ml_model and 'ml_classification' in self.detection_methods:
                candidate_projects = self._ml_classify_projects(candidate_projects)
            
            # שלב 6: סינון וניקוי פרויקטים שאינם עומדים בקריטריונים
            final_projects = self._filter_and_enrich_projects(candidate_projects)
            
            logger.info(f"זיהוי פרויקטים הושלם, נמצאו {len(final_projects)} פרויקטים")
            return final_projects
            
        except Exception as e:
            logger.error(f"שגיאה בזיהוי פרויקטים: {str(e)}")
            return []

    def _analyze_file_structure(self, files: List[str]) -> Dict[str, Any]:
        """
        ניתוח מבנה תיקיות וקבצים
        
        Args:
            files: רשימת נתיבי קבצים
            
        Returns:
            מילון עם ניתוח מבנה התיקיות והקבצים
        """
        file_structure = {
            'all_files': files,
            'dir_to_files': collections.defaultdict(list),
            'file_extensions': collections.defaultdict(int),
            'common_root_dirs': [],
            'dir_hierarchy': {}
        }
        
        # מיפוי קבצים לתיקיות
        for file_path in files:
            dir_path = os.path.dirname(file_path)
            file_structure['dir_to_files'][dir_path].append(file_path)
            
            # ספירת סיומות קבצים
            ext = os.path.splitext(file_path)[1].lower()
            if ext:
                file_structure['file_extensions'][ext] += 1
        
        # איתור שורשי תיקיות נפוצים
        all_dirs = list(file_structure['dir_to_files'].keys())
        if all_dirs:
            # מיון תיקיות לפי עומק בהיררכיה
            dir_depths = [(dir_path, dir_path.count(os.sep)) for dir_path in all_dirs]
            dir_depths.sort(key=lambda x: x[1])  # מיון לפי עומק
            
            # לקיחת 5 השורשים העליונים (הכי רדודים)
            top_dirs = [d[0] for d in dir_depths[:5]]
            file_structure['common_root_dirs'] = top_dirs
            
            # בניית היררכיית תיקיות
            file_structure['dir_hierarchy'] = self._build_directory_hierarchy(all_dirs)
        
        logger.debug(f"ניתוח מבנה קבצים: {len(all_dirs)} תיקיות, {len(file_structure['file_extensions'])} סוגי קבצים")
        return file_structure

    def _build_directory_hierarchy(self, dirs: List[str]) -> Dict[str, Any]:
        """
        בניית עץ היררכיה של תיקיות
        
        Args:
            dirs: רשימת נתיבי תיקיות
            
        Returns:
            מילון המייצג את היררכיית התיקיות
        """
        hierarchy = {}
        for dir_path in sorted(dirs, key=len):
            parts = dir_path.split(os.sep)
            current = hierarchy
            
            # בנייה הדרגתית של העץ
            for i, part in enumerate(parts):
                if not part:  # דילוג על חלקים ריקים (למשל, בהתחלה ל-Unix paths)
                    continue
                
                if part not in current:
                    current[part] = {}
                
                current = current[part]
        
        return hierarchy

    def _detect_by_signatures(self, file_structure: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        זיהוי פרויקטים על פי חתימות וסמנים ידועים
        
        Args:
            file_structure: מבנה תיקיות וקבצים
            
        Returns:
            רשימת פרויקטים שזוהו על בסיס חתימות
        """
        signature_projects = []
        all_files = file_structure['all_files']
        all_files_set = set(all_files)
        
        # בדיקת כל תיקייה לזיהוי סמני פרויקט
        for dir_path, dir_files in file_structure['dir_to_files'].items():
            dir_files_set = set(dir_files)
            
            # חיפוש לכל סוג פרויקט
            for project_type, signature in self.project_signatures.items():
                match_score = 0
                total_criteria = 4  # מספר קריטריונים לחישוב ציון התאמה
                
                # בדיקת קבצים מרכזיים
                key_files = set()
                for key_file in signature['files']:
                    # חיפוש בדיוק ובדפוסים של שמות קבצים
                    for file_path in dir_files:
                        if os.path.basename(file_path) == key_file or key_file in file_path:
                            key_files.add(file_path)
                            break
                
                # חישוב ציון התאמה לקבצים מרכזיים
                if signature['files']:
                    key_files_score = len(key_files) / len(signature['files'])
                    match_score += key_files_score
                else:
                    match_score += 0.25  # ערך ברירת מחדל אם אין קבצים מרכזיים
                
                # בדיקת דפוסי תיקיות
                dir_pattern_matches = 0
                for pattern in signature['dir_patterns']:
                    pattern_regex = re.compile(pattern)
                    for subdir in [d for d in file_structure['dir_to_files'].keys() if d.startswith(dir_path)]:
                        if pattern_regex.search(subdir):
                            dir_pattern_matches += 1
                            break
                
                # חישוב ציון התאמה לדפוסי תיקיות
                if signature['dir_patterns']:
                    dir_patterns_score = min(1.0, dir_pattern_matches / len(signature['dir_patterns']))
                    match_score += dir_patterns_score
                else:
                    match_score += 0.25  # ערך ברירת מחדל אם אין דפוסי תיקיות
                
                # בדיקת דפוסי קבצים
                file_pattern_matches = 0
                file_matches = []
                for pattern in signature['file_patterns']:
                    pattern_regex = re.compile(pattern)
                    for file_path in dir_files:
                        if pattern_regex.search(file_path):
                            file_pattern_matches += 1
                            file_matches.append(file_path)
                            break
                
                # חישוב ציון התאמה לדפוסי קבצים
                if signature['file_patterns']:
                    file_patterns_score = min(1.0, file_pattern_matches / len(signature['file_patterns']))
                    match_score += file_patterns_score
                else:
                    match_score += 0.25  # ערך ברירת מחדל אם אין דפוסי קבצים
                
                # בדיקת קבצי מטא-דאטה
                metadata_matches = 0
                for metadata_file in signature['metadata_files']:
                    for file_path in dir_files:
                        if os.path.basename(file_path) == metadata_file:
                            metadata_matches += 1
                            break
                
                # חישוב ציון התאמה לקבצי מטא-דאטה
                if signature['metadata_files']:
                    metadata_score = min(1.0, metadata_matches / len(signature['metadata_files']))
                    match_score += metadata_score
                else:
                    match_score += 0.25  # ערך ברירת מחדל אם אין קבצי מטא-דאטה
                
                # חישוב ציון התאמה סופי
                final_score = match_score / total_criteria
                
                # אם הציון מעל הסף, זהו פרויקט מתאים
                if final_score >= self.detection_confidence_threshold:
                    # איסוף כל הקבצים ששייכים לפרויקט
                    project_files = []
                    
                    # הוספת כל הקבצים בתיקייה ובתת-תיקיות
                    for file_path in all_files:
                        if file_path.startswith(dir_path):
                            project_files.append(file_path)
                    
                    # אם יש מספיק קבצים, הוסף כפרויקט
                    if len(project_files) >= self.min_file_count:
                        project_id = hashlib.md5(dir_path.encode()).hexdigest()[:8]
                        project_name = os.path.basename(os.path.normpath(dir_path)) or f"{project_type}-project"
                        
                        project_info = {
                            "id": project_id,
                            "name": project_name,
                            "type": project_type,
                            "path": dir_path,
                            "confidence": final_score,
                            "files": project_files,
                            "detection_method": "signature",
                            "key_files": list(key_files),
                            "metadata_files": [f for f in dir_files if os.path.basename(f) in signature['metadata_files']]
                        }
                        
                        signature_projects.append(project_info)
                        logger.debug(f"נמצא פרויקט {project_type} בנתיב {dir_path} (ביטחון: {final_score:.2f})")
        
        # מיון לפי רמת הביטחון (מהגבוה לנמוך)
        signature_projects.sort(key=lambda p: p['confidence'], reverse=True)
        
        # הסרת כפילויות (פרויקטים שמכילים תתי-פרויקטים)
        return self._remove_overlapping_projects(signature_projects)

    def _analyze_dependencies(self, files: List[str]) -> List[Dict[str, Any]]:
        """
        ניתוח קשרי תלות בין קבצים וקיבוצם
        
        Args:
            files: רשימת נתיבי קבצים
            
        Returns:
            רשימת קבוצות קבצים על פי תלויות
        """
        dependency_groups = []
        import_mappings = {}
        import_patterns = {
            ".py": {
                "import": r"^\s*import\s+([a-zA-Z0-9_., ]+)",
                "from": r"^\s*from\s+([a-zA-Z0-9_.]+)\s+import"
            },
            ".js": {
                "import": r"^\s*import.*from\s+['\"]([^'\"]+)['\"]",
                "require": r"^\s*(?:const|let|var)\s+.*=\s*require\(['\"]([^'\"]+)['\"]\)"
            },
            ".java": {
                "import": r"^\s*import\s+([a-zA-Z0-9_.]+(?:\.[*])?);"
            },
            ".cpp": {
                "include": r"^\s*#include\s+[<\"]([^>\"]+)[>\"]"
            },
            ".cs": {
                "using": r"^\s*using\s+([a-zA-Z0-9_.]+);"
            },
            ".html": {
                "script": r'<script[^>]*src=["\'](.*?)["\']',
                "link": r'<link[^>]*href=["\'](.*?)["\']'
            }
        }
        
        # צלמיות עבור סוגי קבצים
        file_to_module = {}
        
        # 1. ניתוח ייבוא וייצוא בקבצים
        def analyze_file_imports(file_path):
            ext = os.path.splitext(file_path)[1].lower()
            if ext not in import_patterns:
                return []
            
            file_imports = []
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    # חיפוש כל דפוסי הייבוא הרלוונטיים לסוג הקובץ
                    for pattern_type, regex in import_patterns[ext].items():
                        for line in lines:
                            match = re.search(regex, line)
                            if match:
                                import_name = match.group(1).strip()
                                file_imports.append(import_name)
            except Exception as e:
                logger.debug(f"שגיאה בניתוח ייבוא בקובץ {file_path}: {str(e)}")
            
            return file_imports
        
        # ניתוח מקבילי של קבצים
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            results = list(executor.map(analyze_file_imports, files))
        
        # עיבוד התוצאות
        for i, file_path in enumerate(files):
            file_imports = results[i]
            if file_imports:
                module_name = self._file_to_module_name(file_path)
                file_to_module[file_path] = module_name
                import_mappings[file_path] = file_imports
        
        # 2. בניית גרף תלויות
        dependency_graph = collections.defaultdict(set)
        for file_path, imports in import_mappings.items():
            file_dir = os.path.dirname(file_path)
            file_module = file_to_module[file_path]
            
            for import_name in imports:
                # חיפוש קבצים שמתאימים לייבוא
                for other_file, other_module in file_to_module.items():
                    if file_path == other_file:
                        continue
                    
                    other_dir = os.path.dirname(other_file)
                    
                    # בדיקת התאמה לייבוא
                    if (
                        import_name == other_module or
                        import_name.startswith(other_module + ".") or
                        os.path.basename(other_file).startswith(import_name) or
                        os.path.basename(other_dir) == import_name
                    ):
                        dependency_graph[file_path].add(other_file)
                        dependency_graph[other_file].add(file_path)
        
        # 3. אלגוריתם DFS לגילוי רכיבים מחוברים
        def dfs(node, visited, component):
            visited[node] = True
            component.append(node)
            for neighbor in dependency_graph[node]:
                if not visited.get(neighbor, False):
                    dfs(neighbor, visited, component)
        
        visited = {}
        for file_path in dependency_graph:
            if not visited.get(file_path, False):
                component = []
                dfs(file_path, visited, component)
                
                if len(component) >= self.min_file_count:
                    # זיהוי תיקיית השורש המשותפת
                    common_prefix = os.path.commonprefix(component)
                    common_dir = os.path.dirname(common_prefix)
                    
                    # אם אין תיקייה משותפת, השתמש בתיקיית האב של הקובץ הראשון
                    if not common_dir:
                        common_dir = os.path.dirname(component[0])
                    
                    project_id = hashlib.md5(str(component).encode()).hexdigest()[:8]
                    project_name = os.path.basename(os.path.normpath(common_dir)) or "dependency-project"
                    
                    dependency_groups.append({
                        "id": project_id,
                        "name": project_name,
                        "path": common_dir,
                        "files": component,
                        "detection_method": "dependency"
                    })
        
        logger.debug(f"ניתוח תלויות: זוהו {len(dependency_groups)} קבוצות")
        return dependency_groups

    def _file_to_module_name(self, file_path: str) -> str:
        """
        המרת נתיב קובץ לשם מודול לוגי
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            שם המודול הלוגי
        """
        basename = os.path.basename(file_path)
        module_name = os.path.splitext(basename)[0]
        return module_name.replace("-", "_").replace(" ", "_")

    def _merge_detection_results(self, 
                               signature_projects: List[Dict[str, Any]], 
                               dependency_groups: List[Dict[str, Any]], 
                               file_structure: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        שילוב תוצאות הזיהוי מהשיטות השונות
        
        Args:
            signature_projects: פרויקטים שזוהו על בסיס חתימות
            dependency_groups: קבוצות שזוהו על בסיס תלויות
            file_structure: מבנה הקבצים והתיקיות
            
        Returns:
            רשימת פרויקטים מאוחדת
        """
        # זכרון כל הקבצים שכבר הוקצו לפרויקטים
        assigned_files = set()
        merged_projects = []
        
        # התחלה מפרויקטים שזוהו לפי חתימות (בדרך כלל הכי אמינים)
        for project in signature_projects:
            merged_projects.append(project)
            assigned_files.update(project["files"])
        
        # הוספת קבוצות תלויות שאינן חופפות עם פרויקטים קיימים
        for group in dependency_groups:
            group_files = set(group["files"])
            unique_files = group_files - assigned_files
            
            # אם רוב הקבצים בקבוצה אינם משויכים עדיין, הוסף כפרויקט חדש
            if len(unique_files) > 0.5 * len(group_files):
                # עדכון רשימת הקבצים להכיל רק קבצים לא משויכים
                group["files"] = list(unique_files)
                
                if len(group["files"]) >= self.min_file_count:
                    # הוספת חיזוי סוג הפרויקט
                    group["type"] = self._predict_project_type(group["files"])
                    
                    # חישוב רמת ביטחון
                    group["confidence"] = 0.7  # ערך ברירת מחדל לזיהוי לפי תלויות
                    
                    merged_projects.append(group)
                    assigned_files.update(unique_files)
        
        # חיפוש תיקיות שלמות עם קבצים שלא שויכו עדיין
        unassigned_dirs = {}
        for file_path in file_structure["all_files"]:
            if file_path not in assigned_files:
                dir_path = os.path.dirname(file_path)
                if dir_path not in unassigned_dirs:
                    unassigned_dirs[dir_path] = []
                unassigned_dirs[dir_path].append(file_path)
        
        # בדיקה האם יש תיקיות עם מספיק קבצים לא משויכים כדי ליצור פרויקט
        for dir_path, dir_files in unassigned_dirs.items():
            if len(dir_files) >= self.min_file_count:
                project_id = hashlib.md5(dir_path.encode()).hexdigest()[:8]
                project_name = os.path.basename(os.path.normpath(dir_path)) or "unknown-project"
                
                # חיזוי סוג הפרויקט
                project_type = self._predict_project_type(dir_files)
                
                project_info = {
                    "id": project_id,
                    "name": project_name,
                    "type": project_type,
                    "path": dir_path,
                    "confidence": 0.6,  # ערך ברירת מחדל לזיהוי לפי שיוך לתיקייה
                    "files": dir_files,
                    "detection_method": "directory"
                }
                
                merged_projects.append(project_info)
                assigned_files.update(dir_files)
        
        # מיון פרויקטים לפי רמת הביטחון ומספר הקבצים
        merged_projects.sort(key=lambda p: (p.get('confidence', 0), len(p['files'])), reverse=True)
        
        return merged_projects

    def _predict_project_type(self, file_paths: List[str]) -> str:
        """
        חיזוי סוג הפרויקט לפי הקבצים
        
        Args:
            file_paths: רשימת נתיבי קבצים
            
        Returns:
            סוג הפרויקט המנוחש
        """
        ext_counter = collections.Counter()
        
        # ספירת סיומות קבצים
        for file_path in file_paths:
            ext = os.path.splitext(file_path)[1].lower()
            if ext:
                ext_counter[ext] += 1
        
        # חיפוש קבצי מפתח
        key_files = [os.path.basename(f) for f in file_paths]
        
        # מיפוי בדיקות לסוגי פרויקטים
        project_type_checks = [
            (lambda: 'package.json' in key_files or 'node_modules' in str(file_paths), "nodejs"),
            (lambda: 'requirements.txt' in key_files or 'setup.py' in key_files or ext_counter.get('.py', 0) > 3, "python"),
            (lambda: 'pom.xml' in key_files or 'build.gradle' in key_files or ext_counter.get('.java', 0) > 3, "java"),
            (lambda: 'index.html' in key_files and (ext_counter.get('.html', 0) + ext_counter.get('.css', 0) > 3), "web"),
            (lambda: 'CMakeLists.txt' in key_files or ext_counter.get('.cpp', 0) + ext_counter.get('.h', 0) > 3, "cpp"),
            (lambda: 'AndroidManifest.xml' in key_files or 'build.gradle' in key_files, "android"),
            (lambda: 'Info.plist' in key_files or ext_counter.get('.swift', 0) > 1, "ios"),
            (lambda: 'pubspec.yaml' in key_files or ext_counter.get('.dart', 0) > 1, "flutter"),
            (lambda: any(f.endswith('.csproj') for f in file_paths) or ext_counter.get('.cs', 0) > 3, "dotnet"),
            (lambda: 'go.mod' in key_files or ext_counter.get('.go', 0) > 1, "go"),
            (lambda: 'Gemfile' in key_files or ext_counter.get('.rb', 0) > 1, "ruby"),
            (lambda: 'composer.json' in key_files or ext_counter.get('.php', 0) > 1, "php"),
            (lambda: 'Cargo.toml' in key_files or ext_counter.get('.rs', 0) > 1, "rust")
        ]
        
        # בדיקת התאמה לסוגי פרויקטים
        for check_func, project_type in project_type_checks:
            if check_func():
                return project_type
        
        # אם אין התאמה ברורה, בחר לפי סיומת הכי נפוצה
        if ext_counter:
            most_common_ext = ext_counter.most_common(1)[0][0]
            if most_common_ext == '.py':
                return "python"
            elif most_common_ext in ('.js', '.jsx', '.ts', '.tsx'):
                return "nodejs"
            elif most_common_ext == '.java':
                return "java"
            elif most_common_ext in ('.html', '.css'):
                return "web"
            elif most_common_ext in ('.c', '.cpp', '.h', '.hpp'):
                return "cpp"
        
        # ברירת מחדל
        return "unknown"

    def _ml_classify_projects(self, projects: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        שיפור סיווג פרויקטים באמצעות למידת מכונה
        
        Args:
            projects: רשימת פרויקטים לסיווג
            
        Returns:
            רשימת פרויקטים מסווגת
        """
        if not ML_AVAILABLE or not self.ml_model or not self.vectorizer:
            logger.debug("למידת מכונה אינה זמינה לסיווג פרויקטים")
            return projects
        
        try:
            # הכנת נתונים לסיווג
            project_features = []
            for project in projects:
                # יצירת מאפיינים לסיווג
                features = self._extract_project_features(project)
                project_features.append(features)
            
            # אם אין נתונים, החזר את הפרויקטים המקוריים
            if not project_features:
                return projects
            
            # המרת מאפיינים לטקסט לצורך סיווג
            project_texts = [' '.join(f) for f in project_features]
            X = self.vectorizer.fit_transform(project_texts)
            
            # ניסיון לסווג
            try:
                # חיזוי סוגי פרויקטים
                predicted_types = self.ml_model.predict(X)
                
                # עדכון המידע בפרויקטים
                for i, project in enumerate(projects):
                    # רק אם זה לא "unknown"
                    if project["type"] == "unknown" and i < len(predicted_types):
                        project["type"] = predicted_types[i]
                        project["ml_classified"] = True
            except Exception as e:
                logger.warning(f"שגיאה בסיווג ML: {str(e)}")
            
            return projects
        except Exception as e:
            logger.error(f"שגיאה בסיווג פרויקטים עם למידת מכונה: {str(e)}")
            return projects

    def _extract_project_features(self, project: Dict[str, Any]) -> List[str]:
        """
        חילוץ מאפיינים מפרויקט לצורך סיווג ML
        
        Args:
            project: פרויקט לחילוץ מאפיינים
            
        Returns:
            רשימת מאפיינים
        """
        features = []
        
        # הוספת שם הפרויקט
        features.append(project["name"])
        
        # הוספת סוגי קבצים
        extensions = set()
        for file_path in project["files"]:
            ext = os.path.splitext(file_path)[1].lower()
            if ext:
                extensions.add(ext[1:])  # הסרת הנקודה
        features.extend(list(extensions))
        
        # הוספת שמות קבצי מפתח
        key_files = []
        for file_path in project["files"]:
            basename = os.path.basename(file_path)
            if any(basename == key for key in itertools.chain(*[signature["files"] for signature in self.project_signatures.values()])):
                key_files.append(basename)
        features.extend(key_files)
        
        # הוספת שמות תיקיות
        directories = set()
        for file_path in project["files"]:
            dir_path = os.path.dirname(file_path)
            directories.add(os.path.basename(dir_path))
        features.extend(list(directories))
        
        return features

    def _filter_and_enrich_projects(self, projects: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        סינון, ניקוי והעשרת פרויקטים
        
        Args:
            projects: רשימת פרויקטים
            
        Returns:
            רשימת פרויקטים מסוננת ומועשרת
        """
        if not projects:
            return []
        
        # הסרת פרויקטים חופפים ומיזוג פרויקטים דומים
        non_overlapping = self._remove_overlapping_projects(projects)
        
        # העשרת מידע לכל פרויקט
        for project in non_overlapping:
            # זיהוי שפות תכנות
            project["languages"] = self._identify_languages(project["files"])
            
            # ניתוח היסטוגרמת קבצים
            project["file_histogram"] = self._analyze_file_histogram(project["files"])
            
            # הוספת מדדים סטטיסטיים
            project["stats"] = {
                "file_count": len(project["files"]),
                "directory_count": len(set(os.path.dirname(f) for f in project["files"])),
                "main_language": project["languages"][0][0] if project["languages"] else "unknown"
            }
            
            # בדיקה אם זהו פרויקט תת-תיקייה
            project["is_subdirectory"] = self._check_subdirectory_project(project, non_overlapping)
        
        # סינון פרויקטים שאינם עומדים בקריטריונים
        filtered_projects = []
        for project in non_overlapping:
            # וידוא שיש מספיק קבצים
            if len(project["files"]) >= self.min_file_count:
                filtered_projects.append(project)
        
        # מיון סופי לפי גודל ורמת ביטחון
        filtered_projects.sort(key=lambda p: (p.get('confidence', 0) * len(p['files'])), reverse=True)
        
        # הסרת שדות לא נחוצים או זמניים
        for project in filtered_projects:
            project.pop('is_subdirectory', None)
        
        return filtered_projects

    def _remove_overlapping_projects(self, projects: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        הסרת פרויקטים חופפים
        
        Args:
            projects: רשימת פרויקטים
            
        Returns:
            רשימת פרויקטים ללא חפיפות משמעותיות
        """
        if not projects:
            return []
        
        # מיון פרויקטים לפי גודל (מהגדול לקטן)
        sorted_projects = sorted(projects, key=lambda p: len(p["files"]), reverse=True)
        
        non_overlapping = []
        all_files = set()
        
        for project in sorted_projects:
            project_files = set(project["files"])
            overlap_ratio = len(project_files.intersection(all_files)) / len(project_files) if project_files else 0
            
            # אם רוב הקבצים אינם בפרויקטים אחרים או זהו פרויקט גדול מאוד, הוסף אותו
            if overlap_ratio < 0.5 or len(project_files) > 100:
                non_overlapping.append(project)
                all_files.update(project_files)
        
        return non_overlapping

    def _identify_languages(self, files: List[str]) -> List[Tuple[str, int]]:
        """
        זיהוי שפות תכנות בפרויקט
        
        Args:
            files: רשימת נתיבי קבצים
            
        Returns:
            רשימה מסודרת של שפות ומספר הקבצים
        """
        # מיפוי סיומות קבצים לשפות
        extension_to_language = {
            '.py': 'Python',
            '.ipynb': 'Python',
            '.js': 'JavaScript',
            '.jsx': 'JavaScript',
            '.ts': 'TypeScript',
            '.tsx': 'TypeScript',
            '.html': 'HTML',
            '.css': 'CSS',
            '.scss': 'SCSS',
            '.less': 'LESS',
            '.java': 'Java',
            '.kt': 'Kotlin',
            '.c': 'C',
            '.cpp': 'C++',
            '.cc': 'C++',
            '.h': 'C/C++ Header',
            '.hpp': 'C++ Header',
            '.cs': 'C#',
            '.php': 'PHP',
            '.rb': 'Ruby',
            '.go': 'Go',
            '.rs': 'Rust',
            '.swift': 'Swift',
            '.dart': 'Dart',
            '.json': 'JSON',
            '.xml': 'XML',
            '.yaml': 'YAML',
            '.yml': 'YAML',
            '.md': 'Markdown',
            '.sh': 'Shell',
            '.bat': 'Batch',
            '.ps1': 'PowerShell',
            '.sql': 'SQL'
        }
        
        language_counter = collections.Counter()
        
        for file_path in files:
            ext = os.path.splitext(file_path)[1].lower()
            language = extension_to_language.get(ext, 'Other')
            language_counter[language] += 1
        
        # הסרת שפות לא רלוונטיות
        language_counter.pop('Other', None)
        
        # מיון לפי תדירות
        return language_counter.most_common()

    def _analyze_file_histogram(self, files: List[str]) -> Dict[str, int]:
        """
        יצירת היסטוגרמת קבצים לפי סוג
        
        Args:
            files: רשימת נתיבי קבצים
            
        Returns:
            מילון עם ספירת קבצים לפי סוג
        """
        histogram = {}
        
        # ספירת קבצים לפי סיומת
        for file_path in files:
            ext = os.path.splitext(file_path)[1].lower()
            if not ext:
                ext = '(no extension)'
            
            if ext in histogram:
                histogram[ext] += 1
            else:
                histogram[ext] = 1
        
        # מיון לפי ספירה (מהגבוה לנמוך)
        return dict(sorted(histogram.items(), key=lambda x: x[1], reverse=True))

    def _check_subdirectory_project(self, project: Dict[str, Any], all_projects: List[Dict[str, Any]]) -> bool:
        """
        בדיקה האם פרויקט הוא תת-תיקייה של פרויקט אחר
        
        Args:
            project: פרויקט לבדיקה
            all_projects: כל הפרויקטים
            
        Returns:
            True אם זהו פרויקט תת-תיקייה
        """
        project_path = project["path"]
        
        for other in all_projects:
            if project["id"] == other["id"]:
                continue
            
            if project_path.startswith(other["path"] + os.sep):
                return True
        
        return False

    def get_project_info(self, project_id: str, projects: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        """
        קבלת מידע על פרויקט ספציפי
        
        Args:
            project_id: מזהה הפרויקט
            projects: רשימת פרויקטים
            
        Returns:
            מידע על הפרויקט או None אם לא נמצא
        """
        for project in projects:
            if project["id"] == project_id:
                return project
        return None

    def update_ml_model(self, projects: List[Dict[str, Any]], correct_types: Dict[str, str]) -> bool:
        """
        עדכון מודל למידת מכונה עם מידע מתוקן
        
        Args:
            projects: רשימת פרויקטים
            correct_types: מילון של מזהי פרויקטים וסוגים מתוקנים
            
        Returns:
            האם העדכון הצליח
        """
        if not ML_AVAILABLE or not self.ml_model or not self.vectorizer:
            logger.warning("למידת מכונה אינה זמינה לעדכון")
            return False
        
        try:
            # איסוף נתונים לאימון
            X_train = []
            y_train = []
            
            for project in projects:
                project_id = project["id"]
                if project_id in correct_types:
                    # שימוש בסוג המתוקן
                    correct_type = correct_types[project_id]
                    features = self._extract_project_features(project)
                    X_train.append(' '.join(features))
                    y_train.append(correct_type)
            
            # אם אין מספיק נתוני אימון, אין טעם לעדכן את המודל
            if len(X_train) < 2:
                logger.warning("אין מספיק נתוני אימון לעדכון המודל")
                return False
            
            # המרת מאפיינים לוקטורים
            X_vectors = self.vectorizer.fit_transform(X_train)
            
            # אימון המודל
            self.ml_model.fit(X_vectors, y_train)
            
            # שמירת המודל המעודכן
            try:
                models_dir = os.path.join(os.path.dirname(__file__), 'models')
                os.makedirs(models_dir, exist_ok=True)
                
                model_path = os.path.join(models_dir, 'project_classifier.joblib')
                vectorizer_path = os.path.join(models_dir, 'vectorizer.joblib')
                
                joblib.dump(self.ml_model, model_path)
                joblib.dump(self.vectorizer, vectorizer_path)
                
                logger.info(f"המודל המעודכן נשמר ב-{model_path}")
            except Exception as e:
                logger.warning(f"שגיאה בשמירת המודל: {str(e)}")
            
            return True
        except Exception as e:
            logger.error(f"שגיאה בעדכון מודל למידת מכונה: {str(e)}")
            return False

    def validate_project_structure(self, project: Dict[str, Any]) -> Dict[str, Any]:
        """
        בדיקת תקינות מבנה פרויקט
        
        Args:
            project: פרויקט לבדיקה
            
        Returns:
            מידע על תקינות המבנה
        """
        validation_result = {
            "is_valid": True,
            "warnings": [],
            "missing_files": [],
            "recommendations": []
        }
        
        project_type = project.get("type", "unknown")
        project_files = set(os.path.basename(f) for f in project["files"])
        
        # בדיקה רק אם קיימת חתימה לסוג הפרויקט
        if project_type in self.project_signatures:
            signature = self.project_signatures[project_type]
            
            # בדיקת קבצים מרכזיים
            for key_file in signature["files"]:
                if key_file not in project_files and not any(f.endswith(key_file) for f in project_files):
                    validation_result["missing_files"].append(key_file)
                    validation_result["warnings"].append(f"קובץ מרכזי חסר: {key_file}")
            
            # בדיקת קבצי מטא-דאטה
            for metadata_file in signature["metadata_files"]:
                if metadata_file not in project_files and not any(f.endswith(metadata_file) for f in project_files):
                    validation_result["warnings"].append(f"קובץ מטא-דאטה חסר: {metadata_file}")
        
        # בדיקות מבנה תקין
        if len(project["files"]) < self.min_file_count:
            validation_result["is_valid"] = False
            validation_result["warnings"].append(f"מספר קבצים קטן מדי ({len(project['files'])} קבצים, מינימום {self.min_file_count})")
        
        # המלצות
        if project_type == "unknown":
            validation_result["recommendations"].append("מומלץ לזהות את סוג הפרויקט באופן ידני")
        
        if len(validation_result["missing_files"]) > 0:
            validation_result["recommendations"].append("מומלץ ליצור את קבצי התשתית החסרים")
        
        return validation_result

    def suggest_project_improvements(self, project: Dict[str, Any]) -> List[str]:
        """
        הצעת שיפורים לפרויקט
        
        Args:
            project: פרויקט לניתוח
            
        Returns:
            רשימת הצעות שיפור
        """
        suggestions = []
        project_type = project.get("type", "unknown")
        languages = project.get("languages", [])
        
        # המלצות לפי סוג פרויקט
        if project_type == "nodejs":
            if not any(os.path.basename(f) == ".gitignore" for f in project["files"]):
                suggestions.append("הוספת קובץ .gitignore עבור Node.js")
            if not any(os.path.basename(f) == "README.md" for f in project["files"]):
                suggestions.append("הוספת קובץ README.md עם הסבר על הפרויקט")
        
        elif project_type == "python":
            if not any(os.path.basename(f) == "requirements.txt" for f in project["files"]):
                suggestions.append("הוספת קובץ requirements.txt להגדרת תלויות")
            if not any(os.path.basename(f) == "setup.py" for f in project["files"]):
                suggestions.append("הוספת קובץ setup.py להגדרת חבילה")
        
        elif project_type == "web":
            if not any(f.endswith(".css") for f in project["files"]):
                suggestions.append("הוספת קובץ CSS לעיצוב")
            if not any(f.endswith(".js") for f in project["files"]):
                suggestions.append("הוספת קובץ JavaScript לאינטראקטיביות")
        
        # המלצות לפי שפות
        for lang, count in languages:
            if lang == "Python" and count > 10:
                suggestions.append("הוספת בדיקות יחידה עם pytest")
            elif lang == "JavaScript" and count > 10:
                suggestions.append("הוספת בדיקות עם Jest או Mocha")
            elif lang == "Java" and count > 10:
                suggestions.append("הוספת בדיקות יחידה עם JUnit")
        
        # המלצות כלליות
        if len(project["files"]) > 20:
            suggestions.append("ארגון קבצים בתיקיות לוגיות לשיפור מבנה הפרויקט")
        
        return suggestions

# פונקציה לשימוש ישיר כמודול עצמאי
def main():
    """פונקציית הרצה עצמאית"""
    import argparse
    
    parser = argparse.ArgumentParser(description='מזהה פרויקטים חכם')
    parser.add_argument('--dir', required=True, help='תיקייה לסריקה')
    parser.add_argument('--output', default='projects.json', help='קובץ פלט')
    parser.add_argument('--min-files', type=int, default=5, help='מספר קבצים מינימלי לפרויקט')
    parser.add_argument('--confidence', type=float, default=0.7, help='סף ביטחון מינימלי')
    parser.add_argument('--use-ml', action='store_true', help='שימוש בלמידת מכונה לזיהוי')
    
    args = parser.parse_args()
    
    # הגדרת לוגים
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    print(f"סורק תיקייה: {args.dir}")
    
    # קביעת קונפיגורציה
    config = {
        "min_file_count": args.min_files,
        "detection_confidence_threshold": args.confidence,
        "use_ml": args.use_ml
    }
    
    # יצירת מזהה פרויקטים
    detector = ProjectDetector(config)
    
    # איסוף כל הקבצים בתיקייה
    files = []
    for root, dirs, filenames in os.walk(args.dir):
        for filename in filenames:
            files.append(os.path.join(root, filename))
    
    print(f"נמצאו {len(files)} קבצים לניתוח")
    
    # זיהוי פרויקטים
    projects = detector.detect_projects(files)
    
    # שמירת תוצאות
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump({
            "timestamp": datetime.datetime.now().isoformat(),
            "directory": args.dir,
            "total_files": len(files),
            "projects": projects
        }, f, ensure_ascii=False, indent=2)
    
    print(f"זוהו {len(projects)} פרויקטים:")
    for i, project in enumerate(projects):
        print(f"{i+1}. {project['name']} ({project['type']}): {len(project['files'])} קבצים")
    
    print(f"התוצאות נשמרו בקובץ: {args.output}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
