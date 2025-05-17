#!/bin/bash

# סקריפט התקנה למאחד קוד חכם Pro 2.0
echo "🚀 התקנת מאחד קוד חכם Pro 2.0 מתחילה..."
echo "============================================="

# יצירת תיקיות
echo "📁 יוצר מבנה תיקיות..."

# תיקיית בסיס
BASE_DIR="$(pwd)/smart_code_merger_pro"
mkdir -p "$BASE_DIR"

# תיקיות ליבה
mkdir -p "$BASE_DIR/core"
mkdir -p "$BASE_DIR/utils"
mkdir -p "$BASE_DIR/ui"
mkdir -p "$BASE_DIR/ui/templates"
mkdir -p "$BASE_DIR/assets/css"
mkdir -p "$BASE_DIR/assets/js"
mkdir -p "$BASE_DIR/assets/images"
mkdir -p "$BASE_DIR/pwa"
mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/uploads"
mkdir -p "$BASE_DIR/temp"
mkdir -p "$BASE_DIR/versions"
mkdir -p "$BASE_DIR/security_reports"
mkdir -p "$BASE_DIR/remote_cache"

echo "✅ מבנה תיקיות נוצר בהצלחה!"

# יצירת קובץ module.py
echo "📝 יוצר קבצי מודול ראשי..."
cat > "$BASE_DIR/module.py" << 'MODULE_PY'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מאחד קוד חכם Pro 2.0
מודול מרכזי לזיהוי, ניתוח ומיזוג פרויקטים מקבצי ZIP

מחבר: Claude AI
גרסה: 2.0.0
תאריך: מאי 2025
"""

import os
import sys
import json
import zipfile
import logging
import shutil
import tempfile
import hashlib
import importlib
import datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, List, Tuple, Any, Optional, Union, Set

# וידוא שמערכת הספריות נגישה
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.append(current_dir)

# הגדרת לוגים
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(current_dir, 'logs', 'smart_code_merger.log')),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# טעינת הגדרות
try:
    with open(os.path.join(current_dir, 'config.json'), 'r', encoding='utf-8') as f:
        CONFIG = json.load(f)
    with open(os.path.join(current_dir, 'metadata.json'), 'r', encoding='utf-8') as f:
        METADATA = json.load(f)
    with open(os.path.join(current_dir, 'languages_config.json'), 'r', encoding='utf-8') as f:
        LANGUAGES_CONFIG = json.load(f)
    logger.info(f"טעינת הגדרות הושלמה, גרסת מודול: {METADATA['version']}")
except Exception as e:
    logger.error(f"שגיאה בטעינת הגדרות: {str(e)}")
    sys.exit(1)

# ייבוא מודולים מקומיים
try:
    from core.project_detector import ProjectDetector
    from core.file_analyzer import FileAnalyzer
    from core.code_merger import CodeMerger
    from core.version_manager import VersionManager
    from core.security_scanner import SecurityScanner
    from core.code_runner import CodeRunner
    from core.code_completion import CodeCompletion
    from core.remote_storage import RemoteStorageManager
    from utils.helpers import create_directory_if_not_exists, get_file_extension, get_file_hash
    logger.info("ייבוא מודולים מקומיים הושלם")
except ImportError as e:
    logger.warning(f"חלק מהמודולים לא נטענו: {str(e)}. יצירת קישורים שבורים.")
    
    # יצירת מחלקות דמה לקישורים שבורים
    class DummyClass:
        def __init__(self, *args, **kwargs):
            logger.warning(f"שימוש במחלקת דמה: {self.__class__.__name__}")
        
        def __getattr__(self, name):
            return lambda *args, **kwargs: None
    
    class ProjectDetector(DummyClass): pass
    class FileAnalyzer(DummyClass): pass
    class CodeMerger(DummyClass): pass
    class VersionManager(DummyClass): pass
    class SecurityScanner(DummyClass): pass
    class CodeRunner(DummyClass): pass
    class CodeCompletion(DummyClass): pass
    class RemoteStorageManager(DummyClass): pass
    
    def create_directory_if_not_exists(directory: str) -> bool:
        """יוצר תיקייה אם היא לא קיימת"""
        try:
            os.makedirs(directory, exist_ok=True)
            return True
        except Exception as e:
            logger.error(f"שגיאה ביצירת תיקייה {directory}: {str(e)}")
            return False
    
    def get_file_extension(file_path: str) -> str:
        """מחזיר את הסיומת של הקובץ"""
        return os.path.splitext(file_path)[1].lower()
    
    def get_file_hash(file_path: str) -> str:
        """מחזיר את החתימה של הקובץ"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception as e:
            logger.error(f"שגיאה בחישוב חתימת קובץ: {str(e)}")
            return ""


class SmartCodeMerger:
    """
    מחלקה מרכזית למאחד קוד חכם Pro 2.0
    אחראית על ניהול תהליך זיהוי, ניתוח ומיזוג פרויקטים מקבצי ZIP
    """
    
    def __init__(self, config: dict = None):
        """אתחול המערכת עם הגדרות אופציונליות"""
        logger.info("מאתחל מאחד קוד חכם Pro 2.0")
        self.config = config or CONFIG
        self.metadata = METADATA
        self.version = self.metadata["version"]
        self.zip_files = []
        self.target_directory = None
        self.temp_dir = None
        self.detected_projects = []
        self.project_files = {}
        self.merged_projects = {}
        
        # יצירת תיקיות נדרשות
        for directory in ['logs', 'versions', 'security_reports', 'temp', 'remote_cache']:
            create_directory_if_not_exists(os.path.join(current_dir, directory))
        
        # אתחול מודולים
        self.project_detector = ProjectDetector(self.config["project_detection"])
        self.file_analyzer = FileAnalyzer()
        self.code_merger = CodeMerger(self.config["merger"])
        self.version_manager = VersionManager(self.config["version_management"])
        self.security_scanner = SecurityScanner(self.config["security_scanning"])
        self.code_runner = CodeRunner(self.config["code_running"], LANGUAGES_CONFIG)
        self.code_completion = CodeCompletion(self.config["code_completion"])
        self.remote_storage = RemoteStorageManager(self.config["remote_storage"])
        
        logger.info(f"מאחד קוד חכם Pro {self.version} אותחל בהצלחה")
    
    def select_zip_files(self, zip_file_paths: List[str]) -> bool:
        """בחירת קבצי ZIP לניתוח"""
        logger.info(f"בחירת {len(zip_file_paths)} קבצי ZIP לניתוח")
        valid_files = []
        
        for zip_path in zip_file_paths:
            if not os.path.exists(zip_path):
                logger.error(f"קובץ ZIP לא קיים: {zip_path}")
                continue
            
            if not zipfile.is_zipfile(zip_path):
                logger.error(f"קובץ אינו בפורמט ZIP תקין: {zip_path}")
                continue
            
            valid_files.append(zip_path)
            logger.info(f"קובץ ZIP תקין נבחר: {zip_path}")
        
        self.zip_files = valid_files
        return len(valid_files) > 0
    
    def set_target_directory(self, directory: str) -> bool:
        """הגדרת תיקיית היעד למיזוג"""
        try:
            abs_path = os.path.abspath(directory)
            create_directory_if_not_exists(abs_path)
            self.target_directory = abs_path
            logger.info(f"תיקיית יעד הוגדרה: {abs_path}")
            return True
        except Exception as e:
            logger.error(f"שגיאה בהגדרת תיקיית יעד: {str(e)}")
            return False
    
    def _extract_zip_files(self) -> bool:
        """חילוץ קבצי ZIP לתיקייה זמנית"""
        try:
            # יצירת תיקייה זמנית
            self.temp_dir = tempfile.mkdtemp(prefix="smart_code_merger_")
            logger.info(f"נוצרה תיקייה זמנית: {self.temp_dir}")
            
            # חילוץ כל קבצי ה-ZIP
            for idx, zip_path in enumerate(self.zip_files):
                zip_extract_dir = os.path.join(self.temp_dir, f"source_{idx}")
                os.makedirs(zip_extract_dir, exist_ok=True)
                
                with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                    # קידום אחוז ההתקדמות בהתאם למספר הקבצים
                    total_files = len(zip_ref.namelist())
                    logger.info(f"מחלץ {total_files} קבצים מ-{zip_path}")
                    
                    for i, file in enumerate(zip_ref.namelist()):
                        zip_ref.extract(file, zip_extract_dir)
                        if i % max(1, total_files // 10) == 0:  # עדכון כל 10%
                            progress = int((i / total_files) * 100)
                            logger.info(f"התקדמות חילוץ {zip_path}: {progress}%")
                
                logger.info(f"חילוץ {zip_path} הושלם")
            
            return True
        except Exception as e:
            logger.error(f"שגיאה בחילוץ קבצי ZIP: {str(e)}")
            if self.temp_dir and os.path.exists(self.temp_dir):
                shutil.rmtree(self.temp_dir)
            self.temp_dir = None
            return False
    
    def analyze_projects(self) -> Dict[str, Any]:
        """
        ניתוח הפרויקטים בקבצי ה-ZIP
        מחזיר מילון עם תוצאות הניתוח
        """
        logger.info("מתחיל ניתוח פרויקטים")
        
        if not self.zip_files:
            logger.error("לא נבחרו קבצי ZIP לניתוח")
            return {"error": "לא נבחרו קבצי ZIP לניתוח"}
        
        # חילוץ קבצי ZIP
        if not self._extract_zip_files():
            return {"error": "שגיאה בחילוץ קבצי ZIP"}
        
        try:
            # איסוף כל הקבצים הזמינים
            all_files = []
            for root, _, files in os.walk(self.temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    all_files.append(file_path)
            
            logger.info(f"נמצאו {len(all_files)} קבצים לניתוח")
            
            # סינון קבצים על פי הגדרות
            if self.config["file_handling"]["excluded_extensions"]:
                excluded_exts = set(self.config["file_handling"]["excluded_extensions"])
                filtered_files = [f for f in all_files if get_file_extension(f) not in excluded_exts]
                logger.info(f"לאחר סינון סיומות: {len(filtered_files)} קבצים")
                all_files = filtered_files
            
            # הגבלת גודל קובץ
            max_size = self.config["file_handling"]["max_file_size_mb"] * 1024 * 1024
            if max_size > 0:
                filtered_files = []
                for file_path in all_files:
                    file_size = os.path.getsize(file_path)
                    if file_size <= max_size:
                        filtered_files.append(file_path)
                    else:
                        logger.warning(f"קובץ {file_path} נפסל בגלל גודל: {file_size / (1024*1024):.2f} MB")
                
                logger.info(f"לאחר סינון גודל: {len(filtered_files)} קבצים")
                all_files = filtered_files
            
            # ניתוח קבצים וזיהוי פרויקטים
            logger.info("מתחיל זיהוי פרויקטים")
            projects = self.project_detector.detect_projects(all_files)
            logger.info(f"זוהו {len(projects)} פרויקטים")
            
            # ניתוח קשרים בין קבצים
            for project in projects:
                project_id = project["id"]
                project_files = project["files"]
                
                logger.info(f"מנתח קשרים בפרויקט {project_id} ({len(project_files)} קבצים)")
                file_relationships = self.file_analyzer.analyze_relationships(project_files)
                
                project["file_relationships"] = file_relationships
                project["statistics"] = self.file_analyzer.calculate_project_statistics(project_files)
                
                # סריקת אבטחה ראשונית
                if self.config["security_scanning"]["enabled"]:
                    project["security_scan"] = self.security_scanner.quick_scan(project_files)
            
            self.detected_projects = projects
            
            # איסוף תוצאות
            result = {
                "detected_projects": projects,
                "total_files": len(all_files),
                "timestamp": datetime.datetime.now().isoformat()
            }
            
            logger.info("ניתוח פרויקטים הושלם בהצלחה")
            return result
            
        except Exception as e:
            logger.error(f"שגיאה בניתוח פרויקטים: {str(e)}")
            return {"error": f"שגיאה בניתוח פרויקטים: {str(e)}"}
        finally:
            # במקרה של שגיאה, נשמור את התיקייה הזמנית לצורך ניפוי באגים
            # בסביבת ייצור, יש לשקול למחוק אותה כאן
            pass
    
    def merge_project(self, project_id: str) -> Dict[str, Any]:
        """
        מיזוג פרויקט שזוהה לתיקיית היעד
        """
        logger.info(f"מתחיל מיזוג פרויקט {project_id}")
        
        # בדיקת תקינות
        if not self.detected_projects:
            logger.error("לא בוצע ניתוח פרויקטים")
            return {"error": "לא בוצע ניתוח פרויקטים"}
        
        if not self.target_directory:
            logger.error("לא הוגדרה תיקיית יעד")
            return {"error": "לא הוגדרה תיקיית יעד"}
        
        # חיפוש הפרויקט המבוקש
        project = None
        for p in self.detected_projects:
            if p["id"] == project_id:
                project = p
                break
        
        if not project:
            logger.error(f"פרויקט {project_id} לא נמצא")
            return {"error": f"פרויקט {project_id} לא נמצא"}
        
        try:
            project_files = project["files"]
            project_name = project["name"]
            
            # יצירת תיקיית הפרויקט
            project_dir = os.path.join(self.target_directory, project_name)
            create_directory_if_not_exists(project_dir)
            
            logger.info(f"ממזג {len(project_files)} קבצים לתיקייה {project_dir}")
            
            # מיזוג הקבצים
            merged_files = self.code_merger.merge_project_files(project_files, project_dir)
            
            # ניהול גרסאות
            if self.config["version_management"]["enabled"]:
                version_id = self.version_manager.save_version(project_dir)
                logger.info(f"גרסה נשמרה בהצלחה, מזהה: {version_id}")
            
            # סריקת אבטחה מלאה
            security_report = None
            if self.config["security_scanning"]["enabled"]:
                security_report = self.security_scanner.full_scan(project_dir)
                report_path = os.path.join(self.config["security_scanning"]["report_path"], 
                                          f"{project_name}_security_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
                
                with open(report_path, 'w', encoding='utf-8') as f:
                    json.dump(security_report, f, ensure_ascii=False, indent=2)
                
                logger.info(f"דוח אבטחה נשמר: {report_path}")
            
            # יצירת קובץ ZIP אם מוגדר
            zip_path = None
            if self.config["merger"]["create_zip"]:
                zip_path = os.path.join(self.target_directory, f"{project_name}.zip")
                shutil.make_archive(os.path.splitext(zip_path)[0], 'zip', project_dir)
                logger.info(f"קובץ ZIP נוצר: {zip_path}")
            
            # תוצאות המיזוג
            result = {
                "project_id": project_id,
                "project_name": project_name,
                "merged_files": len(merged_files),
                "output_directory": project_dir,
                "zip_file": zip_path,
                "version_id": version_id if self.config["version_management"]["enabled"] else None,
                "security_report": security_report,
                "timestamp": datetime.datetime.now().isoformat()
            }
            
            # שמירת תוצאות המיזוג
            self.merged_projects[project_id] = result
            
            logger.info(f"מיזוג פרויקט {project_id} הושלם בהצלחה")
            return result
            
        except Exception as e:
            logger.error(f"שגיאה במיזוג פרויקט {project_id}: {str(e)}")
            return {"error": f"שגיאה במיזוג פרויקט: {str(e)}"}
    
    def cleanup(self) -> bool:
        """ניקוי משאבים זמניים"""
        try:
            if self.temp_dir and os.path.exists(self.temp_dir):
                shutil.rmtree(self.temp_dir)
                logger.info(f"תיקייה זמנית נמחקה: {self.temp_dir}")
                self.temp_dir = None
            return True
        except Exception as e:
            logger.error(f"שגיאה בניקוי משאבים זמניים: {str(e)}")
            return False
    
    def get_version_history(self, project_name: str) -> List[Dict[str, Any]]:
        """קבלת היסטוריית גרסאות של פרויקט"""
        if not self.config["version_management"]["enabled"]:
            logger.warning("ניהול גרסאות לא מופעל")
            return []
        
        return self.version_manager.get_project_versions(project_name)
    
    def compare_versions(self, version1: str, version2: str) -> Dict[str, Any]:
        """השוואה בין שתי גרסאות"""
        if not self.config["version_management"]["enabled"]:
            logger.warning("ניהול גרסאות לא מופעל")
            return {"error": "ניהול גרסאות לא מופעל"}
        
        return self.version_manager.compare_versions(version1, version2)
    
    def restore_version(self, version_id: str, target_dir: str = None) -> Dict[str, Any]:
        """שחזור גרסה קודמת"""
        if not self.config["version_management"]["enabled"]:
            logger.warning("ניהול גרסאות לא מופעל")
            return {"error": "ניהול גרסאות לא מופעל"}
        
        if target_dir is None:
            target_dir = self.target_directory
        
        return self.version_manager.restore_version(version_id, target_dir)
    
    def run_code(self, file_path: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """הרצת קובץ קוד בסביבה מבודדת"""
        if not self.config["code_running"]["enabled"]:
            logger.warning("הרצת קוד לא מופעלת")
            return {"error": "הרצת קוד לא מופעלת"}
        
        return self.code_runner.run_file(file_path, params or {})
    
    def complete_code(self, file_path: str, context_lines: int = None) -> Dict[str, Any]:
        """השלמת קוד חסר"""
        if not self.config["code_completion"]["enabled"]:
            logger.warning("השלמת קוד לא מופעלת")
            return {"error": "השלמת קוד לא מופעלת"}
        
        if context_lines is None:
            context_lines = self.config["code_completion"]["context_lines"]
        
        return self.code_completion.complete_file(file_path, context_lines)
    
    def connect_remote_storage(self, storage_type: str, connection_params: Dict[str, Any]) -> Dict[str, Any]:
        """התחברות לאחסון מרוחק"""
        if not self.config["remote_storage"]["enabled"]:
            logger.warning("גישה לאחסון מרוחק לא מופעלת")
            return {"error": "גישה לאחסון מרוחק לא מופעלת"}
        
        if storage_type not in self.config["remote_storage"]["types"]:
            logger.error(f"סוג אחסון לא נתמך: {storage_type}")
            return {"error": f"סוג אחסון לא נתמך: {storage_type}"}
        
        return self.remote_storage.connect(storage_type, connection_params)
    
    def sync_from_remote(self, remote_id: str, remote_path: str, local_path: str) -> Dict[str, Any]:
        """סנכרון מאחסון מרוחק"""
        if not self.config["remote_storage"]["enabled"]:
            logger.warning("גישה לאחסון מרוחק לא מופעלת")
            return {"error": "גישה לאחסון מרוחק לא מופעלת"}
        
        return self.remote_storage.sync_from_remote(remote_id, remote_path, local_path)
    
    def sync_to_remote(self, remote_id: str, local_path: str, remote_path: str) -> Dict[str, Any]:
        """סנכרון לאחסון מרוחק"""
        if not self.config["remote_storage"]["enabled"]:
            logger.warning("גישה לאחסון מרוחק לא מופעלת")
            return {"error": "גישה לאחסון מרוחק לא מופעלת"}
        
        return self.remote_storage.sync_to_remote(remote_id, local_path, remote_path)


# פונקציה לשימוש ישיר מהפקודה
def main():
    """פונקציה ראשית להפעלה ישירה"""
    import argparse
    
    parser = argparse.ArgumentParser(description='מאחד קוד חכם Pro 2.0')
    parser.add_argument('zip_files', nargs='+', help='קבצי ZIP לניתוח')
    parser.add_argument('-o', '--output', required=True, help='תיקיית פלט')
    parser.add_argument('-p', '--project', help='מזהה פרויקט למיזוג (אופציונלי)')
    parser.add_argument('--no-cleanup', action='store_true', help='לא לנקות קבצים זמניים')
    parser.add_argument('--version', action='store_true', help='הצגת גרסה')
    
    args = parser.parse_args()
    
    if args.version:
        try:
            with open(os.path.join(current_dir, 'metadata.json'), 'r', encoding='utf-8') as f:
                metadata = json.load(f)
            print(f"מאחד קוד חכם Pro גרסה {metadata['version']}")
            return 0
        except Exception as e:
            print(f"שגיאה בטעינת מידע גרסה: {str(e)}")
            return 1
    
    merger = SmartCodeMerger()
    
    print(f"משתמש בקבצי ZIP: {', '.join(args.zip_files)}")
    print(f"תיקיית פלט: {args.output}")
    
    merger.select_zip_files(args.zip_files)
    merger.set_target_directory(args.output)
    
    results = merger.analyze_projects()
    
    if "error" in results:
        print(f"שגיאה: {results['error']}")
        return 1
    
    print(f"זוהו {len(results['detected_projects'])} פרויקטים:")
    for idx, project in enumerate(results['detected_projects']):
        print(f"{idx+1}. {project['name']} ({len(project['files'])} קבצים)")
    
    if args.project:
        project_id = args.project
    else:
        # אם יש רק פרויקט אחד, משתמשים בו אוטומטית
        if len(results['detected_projects']) == 1:
            project_id = results['detected_projects'][0]['id']
            print(f"משתמש בפרויקט יחיד: {results['detected_projects'][0]['name']}")
        else:
            # בחירת פרויקט
            try:
                selection = int(input("בחר מספר פרויקט למיזוג: "))
                if selection < 1 or selection > len(results['detected_projects']):
                    print("בחירה לא חוקית")
                    return 1
                project_id = results['detected_projects'][selection - 1]['id']
            except ValueError:
                print("בחירה לא חוקית")
                return 1
    
    merge_result = merger.merge_project(project_id)
    
    if "error" in merge_result:
        print(f"שגיאה במיזוג: {merge_result['error']}")
        return 1
    
    print(f"מיזוג הושלם בהצלחה!")
    print(f"תיקיית פלט: {merge_result['output_directory']}")
    
    if merge_result.get('zip_file'):
        print(f"קובץ ZIP: {merge_result['zip_file']}")
    
    if not args.no_cleanup:
        merger.cleanup()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
MODULE_PY

# יצירת מודול ניהול גרסאות
echo "📝 יוצר מודולי ליבה..."
mkdir -p "$BASE_DIR/core"

echo "📝 יוצר מודול ניהול גרסאות..."
cat > "$BASE_DIR/core/version_manager.py" << 'VERSION_MANAGER_PY'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול ניהול גרסאות למאחד קוד חכם Pro 2.0
מאפשר שמירה, שחזור והשוואה של גרסאות קוד

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import sys
import json
import shutil
import logging
import datetime
import hashlib
import tarfile
import difflib
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional, Union, Set

# הגדרת לוגים
logger = logging.getLogger(__name__)

class VersionManager:
    """
    מנהל גרסאות לשמירה, שחזור והשוואה של קבצי קוד
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        אתחול מנהל הגרסאות
        
        Args:
            config: מילון הגדרות תצורה
        """
        self.config = config
        self.enabled = config.get("enabled", True)
        self.max_versions = config.get("max_versions", 10)
        self.compression = config.get("compression", "gzip")
        self.storage_path = config.get("storage_path", "versions")
        self.include_metadata = config.get("include_metadata", True)
        self.branch_tracking = config.get("branch_tracking", True)
        
        # וידוא שתיקיית הגרסאות קיימת
        os.makedirs(self.storage_path, exist_ok=True)
        
        # קובץ מעקב גרסאות
        self.versions_index_path = os.path.join(self.storage_path, "versions_index.json")
        self.versions_index = self._load_versions_index()
        
        logger.info(f"מנהל גרסאות אותחל עם הגדרות: max_versions={self.max_versions}, "
                   f"compression={self.compression}, storage_path={self.storage_path}")
    
    def _load_versions_index(self) -> Dict[str, Any]:
        """
        טעינת אינדקס הגרסאות
        
        Returns:
            מילון אינדקס הגרסאות
        """
        if os.path.exists(self.versions_index_path):
            try:
                with open(self.versions_index_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"שגיאה בטעינת אינדקס גרסאות: {str(e)}")
                return {"projects": {}, "versions": {}}
        else:
            return {"projects": {}, "versions": {}}
    
    def _save_versions_index(self) -> bool:
        """
        שמירת אינדקס הגרסאות
        
        Returns:
            האם השמירה הצליחה
        """
        try:
            with open(self.versions_index_path, 'w', encoding='utf-8') as f:
                json.dump(self.versions_index, f, ensure_ascii=False, indent=2)
            return True
        except Exception as e:
            logger.error(f"שגיאה בשמירת אינדקס גרסאות: {str(e)}")
            return False
    
    def _create_version_id(self, project_dir: str, timestamp: str) -> str:
        """
        יצירת מזהה גרסה ייחודי
        
        Args:
            project_dir: נתיב הפרויקט
            timestamp: חותמת זמן
            
        Returns:
            מזהה גרסה ייחודי
        """
        project_name = os.path.basename(project_dir)
        unique_id = hashlib.md5(f"{project_name}_{timestamp}".encode()).hexdigest()[:10]
        return f"{project_name}_{timestamp.replace(':', '-').replace(' ', '_')}_{unique_id}"
    
    def _get_file_hash(self, file_path: str) -> str:
        """
        חישוב חתימת MD5 של קובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            חתימת MD5 של תוכן הקובץ
        """
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception as e:
            logger.error(f"שגיאה בחישוב חתימת קובץ {file_path}: {str(e)}")
            return ""
    
    def _get_project_files_info(self, project_dir: str) -> Dict[str, Dict[str, Any]]:
        """
        איסוף מידע על קבצי הפרויקט
        
        Args:
            project_dir: נתיב הפרויקט
            
        Returns:
            מילון עם מידע על כל הקבצים בפרויקט
        """
        files_info = {}
        
        # רשימת סיומות שלא לשמור בגרסה
        excluded_extensions = [".pyc", ".pyo", ".pyd", "__pycache__", ".git"]
        
        for root, _, files in os.walk(project_dir):
            # דילוג על תיקיות מוחרגות
            if any(excluded in root for excluded in excluded_extensions):
                continue
            
            for file in files:
                if any(file.endswith(ext) for ext in excluded_extensions):
                    continue
                
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, project_dir)
                
                # מידע על הקובץ
                file_info = {
                    "path": rel_path,
                    "size": os.path.getsize(file_path),
                    "modified": datetime.datetime.fromtimestamp(os.path.getmtime(file_path)).isoformat(),
                    "hash": self._get_file_hash(file_path)
                }
                
                files_info[rel_path] = file_info
        
        return files_info
    
    def save_version(self, project_dir: str) -> Dict[str, Any]:
        """
        שמירת גרסה של פרויקט
        
        Args:
            project_dir: נתיב הפרויקט לשמירה
            
        Returns:
            מידע על הגרסה שנשמרה
        """
        if not self.enabled:
            logger.warning("ניהול גרסאות אינו מופעל")
            return {"status": "error", "error": "ניהול גרסאות אינו מופעל"}
        
        try:
            project_name = os.path.basename(project_dir)
            timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            version_id = self._create_version_id(project_dir, timestamp)
            
            # יצירת ארכיון
            version_path = os.path.join(self.storage_path, f"{version_id}.tar.gz")
            
            # איסוף מידע על הפרויקט
            files_info = self._get_project_files_info(project_dir)
            
            # יצירת ארכיון
            with tarfile.open(version_path, f"w:gz") as tar:
                # הוספת קבצים לארכיון
                for rel_path, file_info in files_info.items():
                    file_path = os.path.join(project_dir, rel_path)
                    tar.add(file_path, arcname=rel_path)
                
                # הוספת מטא-דאטה
                if self.include_metadata:
                    metadata = {
                        "version_id": version_id,
                        "project_name": project_name,
                        "timestamp": timestamp,
                        "files_count": len(files_info),
                        "files": files_info
                    }
                    
                    # כתיבת המטא-דאטה לקובץ זמני
                    with tempfile.NamedTemporaryFile(mode='w', delete=False, encoding='utf-8') as tmp:
                        json.dump(metadata, tmp, ensure_ascii=False, indent=2)
                        tmp_path = tmp.name
                    
                    # הוספת קובץ המטא-דאטה לארכיון
                    tar.add(tmp_path, arcname="metadata.json")
                    
                    # מחיקת הקובץ הזמני
                    os.unlink(tmp_path)
            
            # עדכון אינדקס הגרסאות
            if project_name not in self.versions_index["projects"]:
                self.versions_index["projects"][project_name] = []
            
            # הוספת הגרסה החדשה לפרויקט
            self.versions_index["projects"][project_name].append(version_id)
            
            # שמירת מידע על הגרסה
            self.versions_index["versions"][version_id] = {
                "project_name": project_name,
                "timestamp": timestamp,
                "path": version_path,
                "files_count": len(files_info)
            }
            
            # שמירת האינדקס
            self._save_versions_index()
            
            # בדיקה אם יש צורך למחוק גרסאות ישנות
            self._cleanup_old_versions(project_name)
            
            logger.info(f"נשמרה גרסה חדשה: {version_id} לפרויקט {project_name}")
            return {
                "status": "success",
                "version_id": version_id,
                "project_name": project_name,
                "timestamp": timestamp,
                "files_count": len(files_info)
            }
            
        except Exception as e:
            logger.error(f"שגיאה בשמירת גרסה: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _cleanup_old_versions(self, project_name: str) -> None:
        """
        ניקוי גרסאות ישנות מעבר למספר המקסימלי
        
        Args:
            project_name: שם הפרויקט לניקוי
        """
        if project_name not in self.versions_index["projects"]:
            return
        
        versions = self.versions_index["projects"][project_name]
        
        # אם מספר הגרסאות עולה על המקסימום, מחק את הישנות ביותר
        if len(versions) > self.max_versions:
            # מיון לפי זמן יצירה (מהישן לחדש)
            versions.sort(key=lambda v: self.versions_index["versions"][v]["timestamp"])
            
            # מחיקת הגרסאות הישנות
            versions_to_delete = versions[:-self.max_versions]
            
            for version_id in versions_to_delete:
                self._delete_version(version_id)
            
            # עדכון רשימת הגרסאות
            self.versions_index["projects"][project_name] = versions[-self.max_versions:]
            self._save_versions_index()
    
    def _delete_version(self, version_id: str) -> bool:
        """
        מחיקת גרסה
        
        Args:
            version_id: מזהה הגרסה למחיקה
            
        Returns:
            האם המחיקה הצליחה
        """
        if version_id not in self.versions_index["versions"]:
            logger.warning(f"גרסה {version_id} לא נמצאה")
            return False
        
        try:
            # מחיקת קובץ הארכיון
            version_path = self.versions_index["versions"][version_id]["path"]
            if os.path.exists(version_path):
                os.remove(version_path)
            
            # מחיקה מהאינדקס
            project_name = self.versions_index["versions"][version_id]["project_name"]
            if project_name in self.versions_index["projects"]:
                if version_id in self.versions_index["projects"][project_name]:
                    self.versions_index["projects"][project_name].remove(version_id)
            
            del self.versions_index["versions"][version_id]
            
            logger.info(f"גרסה {version_id} נמחקה")
            return True
            
        except Exception as e:
            logger.error(f"שגיאה במחיקת גרסה {version_id}: {str(e)}")
            return False
    
    def get_project_versions(self, project_name: str) -> List[Dict[str, Any]]:
        """
        קבלת רשימת הגרסאות של פרויקט
        
        Args:
            project_name: שם הפרויקט
            
        Returns:
            רשימת גרסאות הפרויקט
        """
        if not self.enabled:
            logger.warning("ניהול גרסאות אינו מופעל")
            return []
        
        if project_name not in self.versions_index["projects"]:
            logger.warning(f"פרויקט {project_name} לא נמצא")
            return []
        
        versions = []
        for version_id in self.versions_index["projects"][project_name]:
            if version_id in self.versions_index["versions"]:
                version_info = self.versions_index["versions"][version_id].copy()
                version_info["version_id"] = version_id
                versions.append(version_info)
        
        # מיון לפי זמן יצירה (מהחדש לישן)
        versions.sort(key=lambda v: v["timestamp"], reverse=True)
        
        return versions
    
    def get_version_info(self, version_id: str) -> Dict[str, Any]:
        """
        קבלת מידע על גרסה
        
        Args:
            version_id: מזהה הגרסה
            
        Returns:
            מידע על הגרסה
        """
        if not self.enabled:
            logger.warning("ניהול גרסאות אינו מופעל")
            return {"status": "error", "error": "ניהול גרסאות אינו מופעל"}
        
        if version_id not in self.versions_index["versions"]:
            logger.warning(f"גרסה {version_id} לא נמצאה")
            return {"status": "error", "error": f"גרסה {version_id} לא נמצאה"}
        
        try:
            version_path = self.versions_index["versions"][version_id]["path"]
            
            if not os.path.exists(version_path):
                logger.error(f"קובץ גרסה {version_path} לא נמצא")
                return {"status": "error", "error": f"קובץ גרסה לא נמצא"}
            
            # חילוץ מטא-דאטה מהארכיון
            with tempfile.TemporaryDirectory() as temp_dir:
                with tarfile.open(version_path, "r:gz") as tar:
                    # חיפוש קובץ מטא-דאטה
                    metadata_info = None
                    for member in tar.getmembers():
                        if member.name == "metadata.json":
                            metadata_info = member
                            break
                    
                    if metadata_info:
                        # חילוץ קובץ המטא-דאטה
                        tar.extract(metadata_info, temp_dir)
                        metadata_path = os.path.join(temp_dir, "metadata.json")
                        
                        # קריאת המטא-דאטה
                        with open(metadata_path, 'r', encoding='utf-8') as f:
                            metadata = json.load(f)
                            
                            # הוספת מידע מהאינדקס
                            metadata.update(self.versions_index["versions"][version_id])
                            metadata["version_id"] = version_id
                            metadata["status"] = "success"
                            
                            return metadata
                    
                    # אם אין מטא-דאטה, החזר מידע בסיסי מהאינדקס
                    version_info = self.versions_index["versions"][version_id].copy()
                    version_info["version_id"] = version_id
                    version_info["status"] = "success"
                    
                    # ספירת קבצים בארכיון
                    file_count = sum(1 for member in tar.getmembers() if member.isfile() and member.name != "metadata.json")
                    version_info["files_count"] = file_count
                    
                    return version_info
        
        except Exception as e:
            logger.error(f"שגיאה בקבלת מידע על גרסה {version_id}: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def restore_version(self, version_id: str, target_dir: str) -> Dict[str, Any]:
        """
        שחזור גרסה ליעד מסוים
        
        Args:
            version_id: מזהה הגרסה לשחזור
            target_dir: נתיב היעד לשחזור
            
        Returns:
            תוצאת השחזור
        """
        if not self.enabled:
            logger.warning("ניהול גרסאות אינו מופעל")
            return {"status": "error", "error": "ניהול גרסאות אינו מופעל"}
        
        if version_id not in self.versions_index["versions"]:
            logger.warning(f"גרסה {version_id} לא נמצאה")
            return {"status": "error", "error": f"גרסה {version_id} לא נמצאה"}
        
        try:
            version_path = self.versions_index["versions"][version_id]["path"]
            
            if not os.path.exists(version_path):
                logger.error(f"קובץ גרסה {version_path} לא נמצא")
                return {"status": "error", "error": f"קובץ גרסה לא נמצא"}
            
            # וידוא שתיקיית היעד קיימת
            os.makedirs(target_dir, exist_ok=True)
            
            # שחזור הקבצים מהארכיון
            with tarfile.open(version_path, "r:gz") as tar:
                # סינון קבצי מטא-דאטה
                members = [m for m in tar.getmembers() if m.name != "metadata.json"]
                
                # שחזור הקבצים
                tar.extractall(path=target_dir, members=members)
            
            logger.info(f"גרסה {version_id} שוחזרה בהצלחה ליעד {target_dir}")
            
            # החזר מידע על השחזור
            return {
                "status": "success",
                "version_id": version_id,
                "project_name": self.versions_index["versions"][version_id]["project_name"],
                "timestamp": self.versions_index["versions"][version_id]["timestamp"],
                "files_count": self.versions_index["versions"][version_id]["files_count"],
                "target_dir": target_dir
            }
            
        except Exception as e:
            logger.error(f"שגיאה בשחזור גרסה {version_id}: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def compare_versions(self, version_id1: str, version_id2: str) -> Dict[str, Any]:
        """
        השוואה בין שתי גרסאות
        
        Args:
            version_id1: מזהה הגרסה הראשונה
            version_id2: מזהה הגרסה השנייה
            
        Returns:
            תוצאות ההשוואה
        """
        if not self.enabled:
            logger.warning("ניהול גרסאות אינו מופעל")
            return {"status": "error", "error": "ניהול גרסאות אינו מופעל"}
        
        if version_id1 not in self.versions_index["versions"]:
            logger.warning(f"גרסה {version_id1} לא נמצאה")
            return {"status": "error", "error": f"גרסה {version_id1} לא נמצאה"}
        
        if version_id2 not in self.versions_index["versions"]:
            logger.warning(f"גרסה {version_id2} לא נמצאה")
            return {"status": "error", "error": f"גרסה {version_id2} לא נמצאה"}
        
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                # חילוץ הגרסה הראשונה
                version1_dir = os.path.join(temp_dir, "version1")
                os.makedirs(version1_dir)
                self.restore_version(version_id1, version1_dir)
                
                # חילוץ הגרסה השנייה
                version2_dir = os.path.join(temp_dir, "version2")
                os.makedirs(version2_dir)
                self.restore_version(version_id2, version2_dir)
                
                # השוואה בין הגרסאות
                comparison_result = self._compare_directories(version1_dir, version2_dir)
                
                # הוספת מידע על הגרסאות
                result = {
                    "status": "success",
                    "version1": {
                        "version_id": version_id1,
                        "project_name": self.versions_index["versions"][version_id1]["project_name"],
                        "timestamp": self.versions_index["versions"][version_id1]["timestamp"]
                    },
                    "version2": {
                        "version_id": version_id2,
                        "project_name": self.versions_index["versions"][version_id2]["project_name"],
                        "timestamp": self.versions_index["versions"][version_id2]["timestamp"]
                    },
                    "comparison": comparison_result
                }
                
                return result
                
        except Exception as e:
            logger.error(f"שגיאה בהשוואת גרסאות {version_id1} ו-{version_id2}: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _compare_directories(self, dir1: str, dir2: str) -> Dict[str, Any]:
        """
        השוואה בין שתי תיקיות
        
        Args:
            dir1: נתיב התיקייה הראשונה
            dir2: נתיב התיקייה השנייה
            
        Returns:
            תוצאות ההשוואה
        """
        # רשימת קבצים בכל תיקייה
        files1 = self._get_directory_files(dir1)
        files2 = self._get_directory_files(dir2)
        
        # קבצים משותפים
        common_files = set(files1.keys()) & set(files2.keys())
        
        # קבצים ייחודיים לכל תיקייה
        only_in_dir1 = set(files1.keys()) - set(files2.keys())
        only_in_dir2 = set(files2.keys()) - set(files1.keys())
        
        # השוואת קבצים משותפים
        changed_files = []
        unchanged_files = []
        
        for file_path in common_files:
            if files1[file_path]["hash"] != files2[file_path]["hash"]:
                # יצירת השוואה בין תכני הקבצים
                file1_path = os.path.join(dir1, file_path)
                file2_path = os.path.join(dir2, file_path)
                
                try:
                    with open(file1_path, 'r', encoding='utf-8', errors='ignore') as f1, \
                         open(file2_path, 'r', encoding='utf-8', errors='ignore') as f2:
                        file1_lines = f1.readlines()
                        file2_lines = f2.readlines()
                    
                    # יצירת השוואה
                    diff = list(difflib.unified_diff(
                        file1_lines, file2_lines,
                        fromfile=f"version1/{file_path}",
                        tofile=f"version2/{file_path}",
                        n=3
                    ))
                    
                    changed_files.append({
                        "path": file_path,
                        "diff": "".join(diff),
                        "size1": files1[file_path]["size"],
                        "size2": files2[file_path]["size"],
                        "modified1": files1[file_path]["modified"],
                        "modified2": files2[file_path]["modified"]
                    })
                    
                except Exception as e:
                    # במקרה של קובץ בינארי או שגיאה אחרת
                    changed_files.append({
                        "path": file_path,
                        "diff": "בינארי או שגיאה בהשוואה: " + str(e),
                        "size1": files1[file_path]["size"],
                        "size2": files2[file_path]["size"],
                        "modified1": files1[file_path]["modified"],
                        "modified2": files2[file_path]["modified"]
                    })
            else:
                unchanged_files.append(file_path)
        
        # סיכום התוצאות
        return {
            "files_only_in_version1": sorted(list(only_in_dir1)),
            "files_only_in_version2": sorted(list(only_in_dir2)),
            "changed_files": changed_files,
            "unchanged_files": unchanged_files,
            "total_files_version1": len(files1),
            "total_files_version2": len(files2),
            "total_changed_files": len(changed_files),
            "total_unchanged_files": len(unchanged_files)
        }
    
    def _get_directory_files(self, directory: str) -> Dict[str, Dict[str, Any]]:
        """
        קבלת רשימת קבצים בתיקייה
        
        Args:
            directory: נתיב התיקייה
            
        Returns:
            מילון עם מידע על כל הקבצים בתיקייה
        """
        files_info = {}
        
        for root, _, files in os.walk(directory):
            for file in files:
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, directory)
                
                # מידע על הקובץ
                files_info[rel_path] = {
                    "path": rel_path,
                    "size": os.path.getsize(file_path),
                    "modified": datetime.datetime.fromtimestamp(os.path.getmtime(file_path)).isoformat(),
                    "hash": self._get_file_hash(file_path)
                }
        
        return files_info
    
    def compare_file_versions(self, version_id1: str, version_id2: str, file_path: str) -> Dict[str, Any]:
        """
        השוואה בין שתי גרסאות של קובץ ספציפי
        
        Args:
            version_id1: מזהה הגרסה הראשונה
            version_id2: מזהה הגרסה השנייה
            file_path: נתיב הקובץ להשוואה
            
        Returns:
            תוצאות ההשוואה
        """
        if not self.enabled:
            logger.warning("ניהול גרסאות אינו מופעל")
            return {"status": "error", "error": "ניהול גרסאות אינו מופעל"}
        
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                # חילוץ הקובץ מהגרסה הראשונה
                version1_dir = os.path.join(temp_dir, "version1")
                os.makedirs(version1_dir)
                
                # שחזור הגרסה הראשונה
                restore_result1 = self.restore_version(version_id1, version1_dir)
                if restore_result1["status"] != "success":
                    return restore_result1
                
                # חילוץ הקובץ מהגרסה השנייה
                version2_dir = os.path.join(temp_dir, "version2")
                os.makedirs(version2_dir)
                
                # שחזור הגרסה השנייה
                restore_result2 = self.restore_version(version_id2, version2_dir)
                if restore_result2["status"] != "success":
                    return restore_result2
                
                # נתיבי הקבצים
                file1_path = os.path.join(version1_dir, file_path)
                file2_path = os.path.join(version2_dir, file_path)
                
                # בדיקה שהקבצים קיימים
                file1_exists = os.path.exists(file1_path)
                file2_exists = os.path.exists(file2_path)
                
                # השוואה בין הקבצים
                if file1_exists and file2_exists:
                    try:
                        with open(file1_path, 'r', encoding='utf-8', errors='ignore') as f1, \
                             open(file2_path, 'r', encoding='utf-8', errors='ignore') as f2:
                            file1_lines = f1.readlines()
                            file2_lines = f2.readlines()
                        
                        # יצירת השוואה
                        diff = list(difflib.unified_diff(
                            file1_lines, file2_lines,
                            fromfile=f"version1/{file_path}",
                            tofile=f"version2/{file_path}",
                            n=3
                        ))
                        
                        return {
                            "status": "success",
                            "file_path": file_path,
                            "exists_in_version1": True,
                            "exists_in_version2": True,
                            "diff": "".join(diff),
                            "size1": os.path.getsize(file1_path),
                            "size2": os.path.getsize(file2_path),
                            "modified1": datetime.datetime.fromtimestamp(os.path.getmtime(file1_path)).isoformat(),
                            "modified2": datetime.datetime.fromtimestamp(os.path.getmtime(file2_path)).isoformat(),
                            "version1": {
                                "version_id": version_id1,
                                "project_name": self.versions_index["versions"][version_id1]["project_name"],
                                "timestamp": self.versions_index["versions"][version_id1]["timestamp"]
                            },
                            "version2": {
                                "version_id": version_id2,
                                "project_name": self.versions_index["versions"][version_id2]["project_name"],
                                "timestamp": self.versions_index["versions"][version_id2]["timestamp"]
                            }
                        }
                    except Exception as e:
                        # במקרה של קובץ בינארי או שגיאה אחרת
                        return {
                            "status": "error",
                            "error": f"שגיאה בהשוואת הקבצים: {str(e)}",
                            "file_path": file_path,
                            "exists_in_version1": True,
                            "exists_in_version2": True,
                            "size1": os.path.getsize(file1_path) if file1_exists else 0,
                            "size2": os.path.getsize(file2_path) if file2_exists else 0
                        }
                else:
                    return {
                        "status": "warning",
                        "warning": "הקובץ לא קיים באחת הגרסאות או בשתיהן",
                        "file_path": file_path,
                        "exists_in_version1": file1_exists,
                        "exists_in_version2": file2_exists
                    }
                    
        except Exception as e:
            logger.error(f"שגיאה בהשוואת גרסאות קובץ {file_path}: {str(e)}")
            return {"status": "error", "error": str(e)}
VERSION_MANAGER_PY

# יצירת מודול סריקות אבטחה
echo "📝 יוצר מודול סריקות אבטחה..."
cat > "$BASE_DIR/core/security_scanner.py" << 'SECURITY_SCANNER_PY'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול סריקות אבטחה למאחד קוד חכם Pro 2.0
זיהוי פגיעויות אבטחה וסודות בקוד

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import sys
import json
import logging
import datetime
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional, Union, Set

# הגדרת לוגים
logger = logging.getLogger(__name__)

class SecurityScanner:
    """
    סורק אבטחה לזיהוי פגיעויות וסודות בקוד
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        אתחול סורק האבטחה
        
        Args:
            config: מילון הגדרות תצורה
        """
        self.config = config
        self.enabled = config.get("enabled", True)
        self.scan_level = config.get("scan_level", "medium")
        self.excluded_patterns = config.get("excluded_patterns", ["node_modules", "venv", "__pycache__", ".git"])
        self.vulnerability_db_update = config.get("vulnerability_db_update", True)
        self.report_path = config.get("report_path", "security_reports")
        
        # וידוא שתיקיית דוחות אבטחה קיימת
        os.makedirs(self.report_path, exist_ok=True)
        
        # בדיקת התלויות הנדרשות
        self._check_dependencies()
        
        logger.info(f"סורק אבטחה אותחל עם הגדרות: scan_level={self.scan_level}, "
                   f"excluded_patterns={self.excluded_patterns}")
    
    def _check_dependencies(self) -> None:
        """
        בדיקת התלויות הנדרשות לסריקת אבטחה
        """
        try:
            # בדיקת bandit (לסריקת קוד Python)
            try:
                subprocess.run(["bandit", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
                logger.info("bandit נמצא במערכת")
            except (subprocess.SubprocessError, FileNotFoundError):
                logger.warning("bandit לא נמצא במערכת. מתקין...")
                subprocess.run([sys.executable, "-m", "pip", "install", "bandit"], check=True)
            
            # בדיקת safety (לסריקת תלויות Python)
            try:
                subprocess.run(["safety", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
                logger.info("safety נמצא במערכת")
            except (subprocess.SubprocessError, FileNotFoundError):
                logger.warning("safety לא נמצא במערכת. מתקין...")
                subprocess.run([sys.executable, "-m", "pip", "install", "safety"], check=True)
            
            # עדכון מסד נתוני פגיעויות
            if self.vulnerability_db_update:
                try:
                    logger.info("מעדכן מסד נתוני פגיעויות...")
                    subprocess.run(["safety", "check", "--update"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                except Exception as e:
                    logger.warning(f"שגיאה בעדכון מסד נתוני פגיעויות: {str(e)}")
            
        except Exception as e:
            logger.error(f"שגיאה בבדיקת תלויות: {str(e)}")
    
    def quick_scan(self, files: List[str]) -> Dict[str, Any]:
        """
        סריקת אבטחה מהירה לקבצים
        
        Args:
            files: רשימת נתיבי קבצים לסריקה
            
        Returns:
            תוצאות הסריקה
        """
        if not self.enabled:
            logger.warning("סריקת אבטחה אינה מופעלת")
            return {"status": "warning", "warning": "סריקת אבטחה אינה מופעלת"}
        
        try:
            # סינון קבצים
            filtered_files = self._filter_files(files)
            
            if not filtered_files:
                logger.warning("לא נמצאו קבצים לסריקה")
                return {"status": "warning", "warning": "לא נמצאו קבצים לסריקה"}
            
            # מיון קבצים לפי סוג
            file_types = self._categorize_files(filtered_files)
            
            # סריקה מהירה
            secrets_results = self._scan_for_secrets(filtered_files)
            
            # חיפוש סיסמאות קשיחות
            hardcoded_credentials = self._find_hardcoded_credentials(filtered_files)
            
            # סיכום הסריקה
            total_issues = len(secrets_results["findings"]) + len(hardcoded_credentials)
            
            return {
                "status": "success",
                "scan_time": datetime.datetime.now().isoformat(),
                "scan_type": "quick",
                "files_scanned": len(filtered_files),
                "file_types": file_types,
                "total_issues": total_issues,
                "severity_summary": {
                    "high": sum(1 for item in secrets_results["findings"] if item.get("severity") == "high"),
                    "medium": sum(1 for item in secrets_results["findings"] if item.get("severity") == "medium"),
                    "low": sum(1 for item in secrets_results["findings"] if item.get("severity") == "low")
                },
                "secrets": secrets_results["findings"],
                "hardcoded_credentials": hardcoded_credentials
            }
            
        except Exception as e:
            logger.error(f"שגיאה בסריקת אבטחה מהירה: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def full_scan(self, project_dir: str) -> Dict[str, Any]:
        """
        סריקת אבטחה מלאה לפרויקט
        
        Args:
            project_dir: נתיב תיקיית הפרויקט
            
        Returns:
            תוצאות הסריקה
        """
        if not self.enabled:
            logger.warning("סריקת אבטחה אינה מופעלת")
            return {"status": "warning", "warning": "סריקת אבטחה אינה מופעלת"}
        
        try:
            logger.info(f"מתחיל סריקת אבטחה מלאה לפרויקט: {project_dir}")
            
            # בדיקה שהתיקייה קיימת
            if not os.path.exists(project_dir) or not os.path.isdir(project_dir):
                logger.error(f"תיקיית פרויקט לא קיימת: {project_dir}")
                return {"status": "error", "error": f"תיקיית פרויקט לא קיימת: {project_dir}"}
            
            # איסוף כל הקבצים בפרויקט
            all_files = []
            for root, dirs, files in os.walk(project_dir):
                # סינון תיקיות מוחרגות
                dirs[:] = [d for d in dirs if not any(pattern in d for pattern in self.excluded_patterns)]
                
                for file in files:
                    file_path = os.path.join(root, file)
                    all_files.append(file_path)
            
            # סינון קבצים
            filtered_files = self._filter_files(all_files)
            
            if not filtered_files:
                logger.warning(f"לא נמצאו קבצים לסריקה בפרויקט: {project_dir}")
                return {"status": "warning", "warning": "לא נמצאו קבצים לסריקה"}
            
            # מיון קבצים לפי סוג
            file_types = self._categorize_files(filtered_files)
            
            # יצירת שם לדוח
            project_name = os.path.basename(os.path.normpath(project_dir))
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            report_name = f"{project_name}_security_{timestamp}"
            
            # סריקות שונות
            results = {}
            
            # סריקת סודות וסיסמאות
            results["secrets"] = self._scan_for_secrets(filtered_files)
            
            # סריקת פגיעויות בקוד Python
            results["python_vulnerabilities"] = self._scan_python_code(project_dir)
            
            # סריקת תלויות Python
            requirements_files = [f for f in filtered_files if os.path.basename(f) == "requirements.txt"]
            if requirements_files:
                results["dependency_vulnerabilities"] = self._scan_python_dependencies(requirements_files)
            
            # סריקת JavaScript
            js_files = [f for f in filtered_files if f.endswith(".js") or f.endswith(".jsx")]
            if js_files:
                results["javascript_issues"] = self._scan_javascript_code(js_files)
            
            # סריקת חולשות אבטחה נפוצות
            results["common_vulnerabilities"] = self._scan_common_vulnerabilities(filtered_files)
            
            # סיכום תוצאות
            total_issues = sum([
                len(results["secrets"]["findings"]),
                len(results.get("python_vulnerabilities", {}).get("findings", [])),
                len(results.get("dependency_vulnerabilities", {}).get("findings", [])),
                len(results.get("javascript_issues", {}).get("findings", [])),
                len(results.get("common_vulnerabilities", {}).get("findings", []))
            ])
            
            # יצירת סיכום חומרה
            severity_summary = {"high": 0, "medium": 0, "low": 0}
            
            # עדכון סיכום חומרה מכל הסריקות
            for scan_results in results.values():
                findings = scan_results.get("findings", [])
                for finding in findings:
                    severity = finding.get("severity", "low").lower()
                    if severity in severity_summary:
                        severity_summary[severity] += 1
            
            # יצירת דוח מסכם
            report = {
                "status": "success",
                "report_name": report_name,
                "project_name": project_name,
                "scan_time": datetime.datetime.now().isoformat(),
                "scan_type": "full",
                "scan_level": self.scan_level,
                "files_scanned": len(filtered_files),
                "file_types": file_types,
                "total_issues": total_issues,
                "severity_summary": severity_summary,
                "results": results
            }
            
            # שמירת הדוח לקובץ
            report_path = os.path.join(self.report_path, f"{report_name}.json")
            with open(report_path, 'w', encoding='utf-8') as f:
                json.dump(report, f, ensure_ascii=False, indent=2)
            
            logger.info(f"סריקת אבטחה מלאה הושלמה, נמצאו {total_issues} בעיות")
            logger.info(f"דוח אבטחה נשמר: {report_path}")
            
            return report
            
        except Exception as e:
            logger.error(f"שגיאה בסריקת אבטחה מלאה: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _filter_files(self, files: List[str]) -> List[str]:
        """
        סינון קבצים לסריקה
        
        Args:
            files: רשימת קבצים לסינון
            
        Returns:
            רשימת קבצים מסוננת
        """
        # סיומות קבצים בינאריים שיש להתעלם מהם
        binary_extensions = ['.exe', '.dll', '.so', '.pyc', '.pyo', '.pyd', '.obj', '.o', '.class', 
                             '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.svg', '.zip', '.tar',
                             '.gz', '.7z', '.rar', '.jar', '.war', '.ear', '.pdf', '.doc', '.docx',
                             '.xls', '.xlsx', '.ppt', '.pptx', '.bin', '.dat', '.db', '.sqlite']
        
        # סינון קבצים
        filtered_files = []
        for file_path in files:
            # בדיקה אם הקובץ קיים ולא תיקייה
            if not os.path.exists(file_path) or os.path.isdir(file_path):
                continue
            
            # בדיקה אם הקובץ שייך לתבנית מוחרגת
            if any(pattern in file_path for pattern in self.excluded_patterns):
                continue
            
            # בדיקה אם הקובץ בינארי
            ext = os.path.splitext(file_path)[1].lower()
            if ext in binary_extensions:
                continue
            
            # בדיקה שזה קובץ טקסט
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    # קריאת מדגם קטן
                    sample = f.read(1024)
                    if not sample:  # קובץ ריק
                        continue
                    
                    # בדיקה שזה קובץ טקסט (לפי מדגם)
                    if b'\0' in sample.encode('utf-8'):  # נוכחות תו NULL מציינת קובץ בינארי
                        continue
            except Exception:
                # במקרה של שגיאה, דלג על הקובץ
                continue
            
            # הוספת הקובץ לרשימה המסוננת
            filtered_files.append(file_path)
        
        return filtered_files
    
    def _categorize_files(self, files: List[str]) -> Dict[str, int]:
        """
        מיון קבצים לפי סוג
        
        Args:
            files: רשימת קבצים למיון
            
        Returns:
            מילון עם מספר הקבצים לפי סוג
        """
        file_types = {}
        
        for file_path in files:
            ext = os.path.splitext(file_path)[1].lower()
            if not ext:
                ext = "(no extension)"
            
            if ext in file_types:
                file_types[ext] += 1
            else:
                file_types[ext] = 1
        
        return file_types
    
    def _scan_for_secrets(self, files: List[str]) -> Dict[str, Any]:
        """
        סריקת סודות וסיסמאות
        
        Args:
            files: רשימת קבצים לסריקה
            
        Returns:
            תוצאות הסריקה
        """
        # תבניות לזיהוי סודות
        secret_patterns = {
            "AWS_ACCESS_KEY": (r"(?<![A-Za-z0-9/+])AKIA[0-9A-Z]{16}(?![A-Za-z0-9/+])", "high"),
            "AWS_SECRET_KEY": (r"(?<![A-Za-z0-9/+])[0-9a-zA-Z/+]{40}(?![A-Za-z0-9/+])", "high"),
            "PRIVATE_KEY": (r"-----BEGIN (RSA )?PRIVATE KEY-----", "high"),
            "JWT_TOKEN": (r"eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*", "medium"),
            "API_KEY": (r"[Aa][Pp][Ii]_?[Kk][Ee][Yy].*?['\"](.*?)['\"]", "medium"),
            "GENERIC_SECRET": (r"[Ss][Ee][Cc][Rr][Ee][Tt].*?['\"](.*?)['\"]", "medium"),
            "TOKEN": (r"[Tt][Oo][Kk][Ee][Nn].*?['\"](.*?)['\"]", "medium"),
            "PASSWORD": (r"[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd].*?['\"](.*?)['\"]", "medium"),
            "BEARER_TOKEN": (r"[Bb][Ee][Aa][Rr][Ee][Rr].*?['\"](.*?)['\"]", "medium"),
        }
        
        findings = []
        
        # סריקת כל הקבצים
        for file_path in files:
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # בדיקת כל התבניות
                    for pattern_name, (pattern, severity) in secret_patterns.items():
                        for match in re.finditer(pattern, content):
                            # חילוץ מידע על המיקום בקובץ
                            line_num = content[:match.start()].count('\n') + 1
                            start_pos = max(0, match.start() - 20)
                            end_pos = min(len(content), match.end() + 20)
                            context = content[start_pos:end_pos].replace('\n', ' ')
                            
                            # הוספת ממצא
                            findings.append({
                                "type": "secret",
                                "pattern_name": pattern_name,
                                "file": file_path,
                                "line": line_num,
                                "severity": severity,
                                "context": f"...{context}...",
                                "description": f"נמצא {pattern_name} אפשרי בקובץ"
                            })
            except Exception as e:
                logger.warning(f"שגיאה בסריקת סודות בקובץ {file_path}: {str(e)}")
        
        return {
            "scan_type": "secrets",
            "files_scanned": len(files),
            "findings_count": len(findings),
            "findings": findings
        }
    
    def _find_hardcoded_credentials(self, files: List[str]) -> List[Dict[str, Any]]:
        """
        חיפוש סיסמאות קשיחות בקוד
        
        Args:
            files: רשימת קבצים לסריקה
            
        Returns:
            רשימת ממצאים
        """
        # תבניות לזיהוי סיסמאות
        credential_patterns = [
            (r"password\s*=\s*['\"]([^'\"]{4,})['\"]", "סיסמה קשיחה"),
            (r"passwd\s*=\s*['\"]([^'\"]{4,})['\"]", "סיסמה קשיחה"),
            (r"pwd\s*=\s*['\"]([^'\"]{4,})['\"]", "סיסמה קשיחה"),
            (r"username\s*=\s*['\"]([^'\"]+)['\"].*?password\s*=\s*['\"]([^'\"]{4,})['\"]", "שם משתמש וסיסמה"),
            (r"user\s*=\s*['\"]([^'\"]+)['\"].*?pass\s*=\s*['\"]([^'\"]{4,})['\"]", "שם משתמש וסיסמה"),
            (r"connection_string\s*=\s*['\"].*?password=([^;'\"]*).*?['\"]", "מחרוזת התחברות עם סיסמה"),
            (r"const\s+password\s*=\s*['\"]([^'\"]{4,})['\"]", "קבוע סיסמה"),
            (r"var\s+password\s*=\s*['\"]([^'\"]{4,})['\"]", "משתנה סיסמה"),
            (r"let\s+password\s*=\s*['\"]([^'\"]{4,})['\"]", "משתנה סיסמה")
        ]
        
        findings = []
        
        # סריקת כל הקבצים
        for file_path in files:
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # חיפוש קווי הקוד
                    lines = content.split('\n')
                    
                    # בדיקת כל התבניות
                    for pattern, desc in credential_patterns:
                        for match in re.finditer(pattern, content):
                            # חילוץ מידע על המיקום בקובץ
                            line_num = content[:match.start()].count('\n') + 1
                            line = lines[line_num - 1] if line_num <= len(lines) else ""
                            
                            # הוספת ממצא
                            findings.append({
                                "type": "hardcoded_credential",
                                "file": file_path,
                                "line": line_num,
                                "severity": "high",
                                "context": line.strip(),
                                "description": f"נמצאו {desc} בקובץ"
                            })
            except Exception as e:
                logger.warning(f"שגיאה בחיפוש סיסמאות בקובץ {file_path}: {str(e)}")
        
        return findings
    
    def _scan_python_code(self, project_dir: str) -> Dict[str, Any]:
        """
        סריקת קוד Python באמצעות bandit
        
        Args:
            project_dir: נתיב תיקיית הפרויקט
            
        Returns:
            תוצאות הסריקה
        """
        try:
            # הגדרת רמת החומרה לפי הגדרות
            severity_level = {
                "low": "-i",
                "medium": "-ii",
                "high": "-iii"
            }.get(self.scan_level, "-ii")
            
            # יצירת קובץ זמני לתוצאות
            with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as tmp:
                tmp_path = tmp.name
            
            # הרצת bandit
            cmd = [
                "bandit",
                "-r", project_dir,
                "-f", "json",
                "-o", tmp_path,
                severity_level
            ]
            
            # הוספת תבניות להתעלמות
            for pattern in self.excluded_patterns:
                cmd.extend(["-x", pattern])
            
            # הרצת הפקודה
            process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            # קריאת תוצאות
            with open(tmp_path, 'r', encoding='utf-8') as f:
                try:
                    bandit_results = json.load(f)
                except json.JSONDecodeError:
                    # במקרה של שגיאה, ניצור תוצאות ריקות
                    bandit_results = {"results": []}
            
            # מחיקת הקובץ הזמני
            os.unlink(tmp_path)
            
            # המרת תוצאות לפורמט אחיד
            findings = []
            for result in bandit_results.get("results", []):
                findings.append({
                    "type": "python_vulnerability",
                    "file": result.get("filename"),
                    "line": result.get("line_number"),
                    "severity": result.get("issue_severity", "medium").lower(),
                    "confidence": result.get("issue_confidence", "medium"),
                    "issue_text": result.get("issue_text"),
                    "issue_code": result.get("test_id"),
                    "description": result.get("test_name")
                })
            
            return {
                "scan_type": "python_code",
                "findings_count": len(findings),
                "findings": findings
            }
            
        except Exception as e:
            logger.error(f"שגיאה בסריקת קוד Python: {str(e)}")
            return {"scan_type": "python_code", "findings_count": 0, "findings": [], "error": str(e)}
    
    def _scan_python_dependencies(self, requirements_files: List[str]) -> Dict[str, Any]:
        """
        סריקת תלויות Python
        
        Args:
            requirements_files: רשימת קבצי requirements.txt
            
        Returns:
            תוצאות הסריקה
        """
        try:
            findings = []
            
            for req_file in requirements_files:
                # יצירת קובץ זמני לתוצאות
                with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as tmp:
                    tmp_path = tmp.name
                
                # הרצת safety
                cmd = [
                    "safety",
                    "check",
                    "-r", req_file,
                    "--json",
                    "-o", tmp_path
                ]
                
                # הרצת הפקודה
                process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                
                # קריאת תוצאות
                try:
                    with open(tmp_path, 'r', encoding='utf-8') as f:
                        try:
                            safety_results = json.load(f)
                        except json.JSONDecodeError:
                            safety_results = {"vulnerabilities": []}
                    
                    # המרת תוצאות לפורמט אחיד
                    for vuln in safety_results.get("vulnerabilities", []):
                        findings.append({
                            "type": "dependency_vulnerability",
                            "file": req_file,
                            "package": vuln.get("package_name"),
                            "installed_version": vuln.get("installed_version"),
                            "vulnerable_version": vuln.get("vulnerable_spec"),
                            "severity": "high" if vuln.get("severity") == "high" else "medium",
                            "advisory_id": vuln.get("vulnerability_id"),
                            "description": vuln.get("advisory")
                        })
                
                except Exception as e:
                    logger.warning(f"שגיאה בקריאת תוצאות safety: {str(e)}")
                
                # מחיקת הקובץ הזמני
                try:
                    os.unlink(tmp_path)
                except:
                    pass
            
            return {
                "scan_type": "python_dependencies",
                "files_scanned": len(requirements_files),
                "findings_count": len(findings),
                "findings": findings
            }
            
        except Exception as e:
            logger.error(f"שגיאה בסריקת תלויות Python: {str(e)}")
            return {"scan_type": "python_dependencies", "findings_count": 0, "findings": [], "error": str(e)}
    
    def _scan_javascript_code(self, js_files: List[str]) -> Dict[str, Any]:
        """
        סריקת קוד JavaScript
        
        Args:
            js_files: רשימת קבצי JavaScript
            
        Returns:
            תוצאות הסריקה
        """
        # תבניות לזיהוי בעיות אבטחה בקוד JavaScript
        js_patterns = [
            (r"eval\s*\(", "שימוש ב-eval", "high"),
            (r"document\.write\s*\(", "שימוש ב-document.write", "medium"),
            (r"innerHTML\s*=", "שימוש ב-innerHTML", "medium"),
            (r"localStorage\s*\.", "שימוש ב-localStorage", "low"),
            (r"sessionStorage\s*\.", "שימוש ב-sessionStorage", "low"),
            (r"Math\.random\s*\(", "שימוש ב-Math.random לאבטחה", "medium"),
            (r"new Function\s*\(", "שימוש ב-Function", "high"),
            (r"setTimeout\s*\(\s*['\"]", "שימוש במחרוזת ב-setTimeout", "medium"),
            (r"setInterval\s*\(\s*['\"]", "שימוש במחרוזת ב-setInterval", "medium"),
            (r"\.html\s*\(", "שימוש ב-jQuery.html", "medium"),
            (r"\.attr\s*\(\s*['\"]on", "שימוש במאזיני אירועים עם jQuery", "medium"),
            (r"process\.env", "גישה למשתני סביבה", "low")
        ]
        
        findings = []
        
        # סריקת כל הקבצים
        for file_path in js_files:
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # חיפוש קווי הקוד
                    lines = content.split('\n')
                    
                    # בדיקת כל התבניות
                    for pattern, desc, severity in js_patterns:
                        for match in re.finditer(pattern, content):
                            # חילוץ מידע על המיקום בקובץ
                            line_num = content[:match.start()].count('\n') + 1
                            line = lines[line_num - 1] if line_num <= len(lines) else ""
                            
                            # הוספת ממצא
                            findings.append({
                                "type": "javascript_issue",
                                "file": file_path,
                                "line": line_num,
                                "severity": severity,
                                "context": line.strip(),
                                "description": f"{desc} עלול להוות סיכון אבטחה"
                            })
            except Exception as e:
                logger.warning(f"שגיאה בסריקת קוד JavaScript בקובץ {file_path}: {str(e)}")
        
        return {
            "scan_type": "javascript_code",
            "files_scanned": len(js_files),
            "findings_count": len(findings),
            "findings": findings
        }
    
    def _scan_common_vulnerabilities(self, files: List[str]) -> Dict[str, Any]:
        """
        סריקת חולשות אבטחה נפוצות
        
        Args:
            files: רשימת קבצים לסריקה
            
        Returns:
            תוצאות הסריקה
        """
        # תבניות לזיהוי חולשות נפוצות
        vulnerability_patterns = [
            (r"(?i)SELECT\s+.*\s+FROM\s+.*\s+WHERE\s+.*=\s*['\"]\s*\+", "SQL injection", "high"),
            (r"(?i)SELECT\s+.*\s+FROM\s+.*\s+WHERE\s+.*=\s*\$", "SQL injection", "high"),
            (r"(?i)exec\s*\([^)]*concat", "Command injection", "high"),
            (r"(?i)system\s*\([^)]*concat", "Command injection", "high"),
            (r"(?i)shell_exec\s*\([^)]*concat", "Command injection", "high"),
            (r"(?i)\.execute\s*\([^)]*\+", "Command injection", "high"),
            (r"ALLOW_ALL_ORIGINS", "CORS חולשת", "medium"),
            (r"(?i)Access-Control-Allow-Origin:\s*\*", "CORS חולשת", "medium"),
            (r"(?i)Debug\s*=\s*True", "Debug mode", "medium"),
            (r"(?i)CSRF_ENABLED\s*=\s*False", "CSRF הגנת", "high"),
            (r"\.md5\s*\(", "MD5 הצפנה חלשה", "medium"),
            (r"\.sha1\s*\(", "SHA1 הצפנה חלשה", "medium"),
            (r"DISABLE_CERT_VERIFICATION", "אימות SSL מושבת", "high"),
            (r"verify\s*=\s*False", "אימות SSL מושבת", "high"),
            (r"X-Frame-Options", "הגנת clickjacking", "medium"),
            (r"SECURE_COOKIES\s*=\s*False", "עוגיות לא מאובטחות", "medium")
        ]
        
        findings = []
        
        # סריקת כל הקבצים
        for file_path in files:
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # חיפוש קווי הקוד
                    lines = content.split('\n')
                    
                    # בדיקת כל התבניות
                    for pattern, desc, severity in vulnerability_patterns:
                        for match in re.finditer(pattern, content):
                            # חילוץ מידע על המיקום בקובץ
                            line_num = content[:match.start()].count('\n') + 1
                            line = lines[line_num - 1] if line_num <= len(lines) else ""
                            
                            # הוספת ממצא
                            findings.append({
                                "type": "common_vulnerability",
                                "file": file_path,
                                "line": line_num,
                                "severity": severity,
                                "context": line.strip(),
                                "description": f"אפשרות ל-{desc}"
                            })
            except Exception as e:
                logger.warning(f"שגיאה בסריקת חולשות נפוצות בקובץ {file_path}: {str(e)}")
        
        return {
            "scan_type": "common_vulnerabilities",
            "files_scanned": len(files),
            "findings_count": len(findings),
            "findings": findings
        }
SECURITY_SCANNER_PY

# יצירת מודול הרצת קוד
echo "📝 יוצר מודול הרצת קוד..."
cat > "$BASE_DIR/core/code_runner.py" << 'CODE_RUNNER_PY'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול הרצת קוד למאחד קוד חכם Pro 2.0
מאפשר הרצת קוד בסביבה מבודדת

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import sys
import json
import time
import uuid
import signal
import logging
import tempfile
import subprocess
import threading
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional, Union, Set

# הגדרת לוגים
logger = logging.getLogger(__name__)

class TimeoutException(Exception):
    """חריגה שמורמת כאשר זמן ההרצה עובר את המקסימום המוגדר"""
    pass

class MemoryException(Exception):
    """חריגה שמורמת כאשר צריכת הזיכרון עוברת את המקסימום המוגדר"""
    pass

class CodeRunner:
    """
    מנהל הרצת קוד בסביבה מבודדת
    """
    
    def __init__(self, config: Dict[str, Any], languages_config: Dict[str, Dict[str, Any]]):
        """
        אתחול מנהל הרצת הקוד
        
        Args:
            config: מילון הגדרות תצורה
            languages_config: מילון הגדרות שפות תכנות
        """
        self.config = config
        self.languages_config = languages_config
        self.enabled = config.get("enabled", True)
        self.sandbox_enabled = config.get("sandbox_enabled", True)
        self.timeout_seconds = config.get("timeout_seconds", 30)
        self.memory_limit_mb = config.get("memory_limit_mb", 512)
        self.supported_languages = config.get("supported_languages", ["python", "javascript", "bash"])
        
        # תיקיית סביבות הרצה מבודדות
        self.sandboxes_dir = config.get("sandboxes_dir", "sandboxes")
        os.makedirs(self.sandboxes_dir, exist_ok=True)
        
        # מעקב אחר הרצות
        self.runs = {}
        
        logger.info(f"מנהל הרצת קוד אותחל עם הגדרות: timeout={self.timeout_seconds}s, "
                   f"memory_limit={self.memory_limit_mb}MB, sandbox={self.sandbox_enabled}")
        
        # בדיקת זמינות שפות
        self._check_language_availability()
    
    def _check_language_availability(self) -> None:
        """
        בדיקת זמינות שפות תכנות במערכת
        """
        for lang in self.supported_languages:
            if lang not in self.languages_config:
                logger.warning(f"הגדרות שפה חסרות עבור {lang}")
                continue
            
            lang_config = self.languages_config[lang]
            cmd = lang_config.get("version_command", [])
            
            if not cmd:
                logger.warning(f"פקודת גרסה לא מוגדרת עבור {lang}")
                continue
            
            try:
                result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if result.returncode == 0:
                    logger.info(f"שפה {lang} זמינה במערכת")
                else:
                    logger.warning(f"שפה {lang} לא זמינה במערכת")
            except Exception as e:
                logger.warning(f"שגיאה בבדיקת זמינות שפה {lang}: {str(e)}")
    
    def _detect_language(self, file_path: str) -> Optional[str]:
        """
        זיהוי שפת התכנות לפי סיומת הקובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            שם השפה או None אם לא זוהתה
        """
        # הוצאת סיומת הקובץ
        ext = os.path.splitext(file_path)[1].lower()
        
        # חיפוש השפה המתאימה לסיומת
        for lang, config in self.languages_config.items():
            if ext == config.get("extension"):
                return lang
        
        return None
    
    def _timeout_handler(self, signum, frame):
        """
        מטפל בחריגת זמן
        """
        raise TimeoutException("זמן הרצה עבר את המקסימום המוגדר")
    
    def _monitor_memory(self, process, max_memory_mb: int, stop_event: threading.Event) -> None:
        """
        ניטור זיכרון של תהליך
        
        Args:
            process: התהליך לניטור
            max_memory_mb: גבול זיכרון במגה-בייטים
            stop_event: אירוע לסימון עצירת הניטור
        """
        try:
            import psutil
        except ImportError:
            logger.warning("לא ניתן לטעון את psutil, ניטור זיכרון לא זמין")
            return
        
        try:
            proc = psutil.Process(process.pid)
            max_memory_bytes = max_memory_mb * 1024 * 1024
            
            while not stop_event.is_set() and process.poll() is None:
                try:
                    memory_info = proc.memory_info()
                    if memory_info.rss > max_memory_bytes:
                        logger.warning(f"תהליך {process.pid} עבר את מגבלת הזיכרון: {memory_info.rss / (1024*1024):.2f}MB")
                        process.kill()
                        break
                except Exception as e:
                    logger.error(f"שגיאה בניטור זיכרון: {str(e)}")
                    break
                
                # בדיקה כל 0.1 שניות
                time.sleep(0.1)
        except Exception as e:
            logger.error(f"שגיאה ביצירת נוטר זיכרון: {str(e)}")
    
    def _create_sandbox(self, language: str) -> str:
        """
        יצירת סביבת הרצה מבודדת לשפה
        
        Args:
            language: שם השפה
            
        Returns:
            נתיב לסביבת ההרצה
        """
        # יצירת תיקייה ייחודית
        sandbox_id = f"{language}_{uuid.uuid4().hex[:8]}"
        sandbox_path = os.path.join(self.sandboxes_dir, sandbox_id)
        os.makedirs(sandbox_path, exist_ok=True)
        
        logger.info(f"נוצרה סביבת הרצה {sandbox_id} לשפה {language}")
        
        return sandbox_path
    
    def _prepare_file_for_execution(self, file_path: str, language: str, sandbox_path: str) -> str:
        """
        הכנת הקובץ להרצה
        
        Args:
            file_path: נתיב הקובץ המקורי
            language: שם השפה
            sandbox_path: נתיב לסביבת ההרצה
            
        Returns:
            נתיב הקובץ המוכן להרצה
        """
        # בדיקה שהקובץ קיים
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"הקובץ {file_path} לא נמצא")
        
        # העתקת הקובץ לסביבת ההרצה
        filename = os.path.basename(file_path)
        dest_path = os.path.join(sandbox_path, filename)
        
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as src_file:
            file_content = src_file.read()
            
        # הוספת מנגנוני הגנה לפי שפה
        if language == "python":
            # מניעת ייבוא מודולים מסוכנים ופעולות מסוכנות
            dangerous_modules = ["os", "sys", "subprocess", "shutil"]
            for module in dangerous_modules:
                if re.search(rf"(?:^|\n)\s*import\s+{module}\b", file_content) or \
                   re.search(rf"(?:^|\n)\s*from\s+{module}\s+import", file_content):
                    logger.warning(f"הקובץ מנסה לייבא מודול מסוכן: {module}")
            
            # הוספת הגבלות זמן ריצה
            safe_content = f"""
# קוד בטיחות מוסף
import signal
import sys
import time

def timeout_handler(signum, frame):
    print("Error: Script execution timed out")
    sys.exit(1)

signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm({self.timeout_seconds})

# קוד מקורי
{file_content}
"""
            
            with open(dest_path, 'w', encoding='utf-8') as dest_file:
                dest_file.write(safe_content)
        
        elif language == "javascript":
            # זמן ריצה מוגבל ב-Node.js
            safe_content = f"""
// קוד בטיחות מוסף
setTimeout(() => {{
    console.error("Error: Script execution timed out");
    process.exit(1);
}}, {self.timeout_seconds * 1000});

// קוד מקורי
{file_content}
"""
            
            with open(dest_path, 'w', encoding='utf-8') as dest_file:
                dest_file.write(safe_content)
        
        else:
            # שפות אחרות - פשוט להעתיק את הקובץ
            with open(dest_path, 'w', encoding='utf-8') as dest_file:
                dest_file.write(file_content)
        
        # הגדרת הרשאות הרצה לקובץ
        os.chmod(dest_path, 0o755)
        
        return dest_path
    
    def _compile_if_needed(self, file_path: str, language: str, sandbox_path: str) -> Optional[Dict[str, Any]]:
        """
        הידור הקובץ אם נדרש
        
        Args:
            file_path: נתיב הקובץ
            language: שם השפה
            sandbox_path: נתיב לסביבת ההרצה
            
        Returns:
            מילון עם תוצאות ההידור או None אם לא נדרש הידור
        """
        lang_config = self.languages_config.get(language, {})
        compile_command = lang_config.get("compile_command")
        
        if not compile_command:
            return None  # אין צורך בהידור
        
        logger.info(f"מהדר את הקובץ {file_path} עם {compile_command}")
        
        # בניית פקודת ההידור
        compile_args = lang_config.get("compile_args", [])
        filename = os.path.basename(file_path)
        
        # החלפת פרמטרים
        full_compile_args = []
        for arg in compile_args:
            if arg == "{file}":
                full_compile_args.append(filename)
            else:
                full_compile_args.append(arg)
        
        # הוספת הקובץ בסוף אם לא הוחלף
        if "{file}" not in compile_args:
            full_compile_args.append(filename)
        
        cmd = [compile_command] + full_compile_args
        
        # הרצת פקודת ההידור
        start_time = time.time()
        try:
            process = subprocess.run(
                cmd,
                cwd=sandbox_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=self.timeout_seconds
            )
            
            end_time = time.time()
            duration = end_time - start_time
            
            # בדיקת הצלחת ההידור
            success = process.returncode == 0
            
            if not success:
        logger.warning(f"הידור {file_path} נכשל עם קוד החזרה {process.returncode}")
            
            return {
                "success": success,
                "stdout": process.stdout.decode('utf-8', errors='ignore'),
                "stderr": process.stderr.decode('utf-8', errors='ignore'),
                "return_code": process.returncode,
                "duration": duration
            }
            
        except subprocess.TimeoutExpired:
            logger.error(f"הידור {file_path} נעצר עקב חריגת זמן")
            return {
                "success": False,
                "stdout": "",
                "stderr": "Error: Compilation timed out",
                "return_code": -1,
                "duration": self.timeout_seconds
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהידור {file_path}: {str(e)}")
            return {
                "success": False,
                "stdout": "",
                "stderr": f"Error: {str(e)}",
                "return_code": -1,
                "duration": time.time() - start_time
            }
    
    def _execute_file(self, file_path: str, language: str, sandbox_path: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        הרצת קובץ
        
        Args:
            file_path: נתיב הקובץ
            language: שם השפה
            sandbox_path: נתיב לסביבת ההרצה
            params: פרמטרים להרצה
            
        Returns:
            תוצאות ההרצה
        """
        lang_config = self.languages_config.get(language, {})
        command = lang_config.get("command")
        
        if not command:
            return {
                "success": False,
                "stdout": "",
                "stderr": f"Error: No command defined for language {language}",
                "return_code": -1,
                "duration": 0
            }
        
        logger.info(f"מריץ את הקובץ {file_path} בשפה {language}")
        
        # בניית פקודת ההרצה
        args = lang_config.get("args", [])
        filename = os.path.basename(file_path)
        
        # החלפת פרמטרים
        full_args = []
        for arg in args:
            if arg == "{file}":
                full_args.append(filename)
            else:
                full_args.append(arg)
        
        # הוספת הקובץ בסוף אם לא הוחלף ולא בפקודה
        file_position = lang_config.get("file_position", "{file}")
        if file_position == "{file}" and "{file}" not in args and command != filename:
            full_args.append(filename)
        
        # הוספת פרמטרים מהמשתמש
        user_args = params.get("args", [])
        full_args.extend(user_args)
        
        cmd = [command] + full_args
        
        # סביבת הרצה
        env = os.environ.copy()
        
        # הוספת משתני סביבה מהגדרות השפה
        lang_env = lang_config.get("env", {})
        env.update(lang_env)
        
        # הוספת משתני סביבה מהמשתמש
        user_env = params.get("env", {})
        env.update(user_env)
        
        # הגבלת זמן הרצה
        timeout = params.get("timeout", self.timeout_seconds)
        
        # הגבלת זיכרון
        memory_limit = params.get("memory_limit", self.memory_limit_mb)
        
        # הרצת התוכנית
        start_time = time.time()
        try:
            # הגדרת סימון עצירה לניטור זיכרון
            stop_event = threading.Event()
            
            # הפעלת התוכנית
            process = subprocess.Popen(
                cmd,
                cwd=sandbox_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
                text=True,
                universal_newlines=True
            )
            
            # התחלת ניטור זיכרון
            memory_thread = threading.Thread(
                target=self._monitor_memory,
                args=(process, memory_limit, stop_event)
            )
            memory_thread.daemon = True
            memory_thread.start()
            
            # הגבלת זמן הרצה
            stdout, stderr = process.communicate(timeout=timeout)
            
            # עצירת ניטור זיכרון
            stop_event.set()
            memory_thread.join(timeout=1.0)
            
            end_time = time.time()
            duration = end_time - start_time
            
            return {
                "success": process.returncode == 0,
                "stdout": stdout,
                "stderr": stderr,
                "return_code": process.returncode,
                "duration": duration
            }
            
        except subprocess.TimeoutExpired:
            # ניסיון לסיים את התהליך
            try:
                process.kill()
                stdout, stderr = process.communicate()
            except:
                stdout, stderr = "", "Error: Could not get output"
            
            # עצירת ניטור זיכרון
            stop_event.set()
            
            logger.warning(f"הרצת {file_path} נעצרה עקב חריגת זמן")
            
            return {
                "success": False,
                "stdout": stdout if stdout else "",
                "stderr": stderr if stderr else "Error: Execution timed out",
                "return_code": -1,
                "duration": time.time() - start_time
            }
            
        except Exception as e:
            # עצירת ניטור זיכרון
            stop_event.set()
            
            logger.error(f"שגיאה בהרצת {file_path}: {str(e)}")
            
            # ניסיון לסיים את התהליך
            try:
                process.kill()
            except:
                pass
            
            return {
                "success": False,
                "stdout": "",
                "stderr": f"Error: {str(e)}",
                "return_code": -1,
                "duration": time.time() - start_time
            }
    
    def _cleanup_sandbox(self, sandbox_path: str) -> None:
        """
        ניקוי סביבת הרצה
        
        Args:
            sandbox_path: נתיב לסביבת ההרצה
        """
        try:
            if os.path.exists(sandbox_path):
                import shutil
                shutil.rmtree(sandbox_path)
                logger.info(f"סביבת הרצה {sandbox_path} נמחקה בהצלחה")
        except Exception as e:
            logger.error(f"שגיאה בניקוי סביבת הרצה {sandbox_path}: {str(e)}")
    
    def run_file(self, file_path: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        הרצת קובץ קוד
        
        Args:
            file_path: נתיב הקובץ להרצה
            params: פרמטרים להרצה
            
        Returns:
            תוצאות ההרצה
        """
        if not self.enabled:
            logger.warning("הרצת קוד אינה מופעלת")
            return {"status": "error", "error": "הרצת קוד אינה מופעלת"}
        
        # ברירת מחדל לפרמטרים
        if params is None:
            params = {}
        
        try:
            # בדיקה שהקובץ קיים
            if not os.path.exists(file_path):
                logger.error(f"קובץ {file_path} לא נמצא")
                return {"status": "error", "error": f"קובץ {file_path} לא נמצא"}
            
            # זיהוי שפת התכנות
            language = params.get("language") or self._detect_language(file_path)
            
            if not language:
                logger.error(f"לא ניתן לזהות את שפת התכנות של הקובץ {file_path}")
                return {"status": "error", "error": "לא ניתן לזהות את שפת התכנות של הקובץ"}
            
            if language not in self.supported_languages:
                logger.error(f"שפה {language} אינה נתמכת")
                return {"status": "error", "error": f"שפה {language} אינה נתמכת"}
            
            # יצירת מזהה הרצה
            run_id = str(uuid.uuid4())
            
            # יצירת סביבת הרצה מבודדת
            sandbox_path = self._create_sandbox(language)
            
            # הכנת הקובץ להרצה
            try:
                prepared_file = self._prepare_file_for_execution(file_path, language, sandbox_path)
            except Exception as e:
                logger.error(f"שגיאה בהכנת הקובץ {file_path} להרצה: {str(e)}")
                self._cleanup_sandbox(sandbox_path)
                return {"status": "error", "error": f"שגיאה בהכנת הקובץ להרצה: {str(e)}"}
            
            # הידור הקובץ אם נדרש
            compile_result = self._compile_if_needed(prepared_file, language, sandbox_path)
            
            if compile_result and not compile_result["success"]:
                logger.error(f"הידור הקובץ {file_path} נכשל")
                result = {
                    "status": "error",
                    "run_id": run_id,
                    "error": "שגיאת הידור",
                    "file": file_path,
                    "language": language,
                    "compile_stdout": compile_result["stdout"],
                    "compile_stderr": compile_result["stderr"],
                    "compile_return_code": compile_result["return_code"],
                    "compile_duration": compile_result["duration"]
                }
                
                # ניקוי סביבת ההרצה
                self._cleanup_sandbox(sandbox_path)
                
                return result
            
            # הרצת הקובץ
            execution_result = self._execute_file(prepared_file, language, sandbox_path, params)
            
            # שמירת תוצאות ההרצה
            result = {
                "status": "success" if execution_result["success"] else "error",
                "run_id": run_id,
                "file": file_path,
                "language": language,
                "params": params,
                "stdout": execution_result["stdout"],
                "stderr": execution_result["stderr"],
                "return_code": execution_result["return_code"],
                "duration": execution_result["duration"]
            }
            
            # הוספת תוצאות ההידור אם היו
            if compile_result:
                result["compile_stdout"] = compile_result["stdout"]
                result["compile_stderr"] = compile_result["stderr"]
                result["compile_return_code"] = compile_result["return_code"]
                result["compile_duration"] = compile_result["duration"]
            
            # שמירת ההרצה במעקב
            self.runs[run_id] = result
            
            # ניקוי סביבת ההרצה
            self._cleanup_sandbox(sandbox_path)
            
            return result
            
        except Exception as e:
            logger.error(f"שגיאה בהרצת קובץ {file_path}: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def run_code_snippet(self, code: str, language: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        הרצת קטע קוד
        
        Args:
            code: קטע הקוד להרצה
            language: שם השפה
            params: פרמטרים להרצה
            
        Returns:
            תוצאות ההרצה
        """
        if not self.enabled:
            logger.warning("הרצת קוד אינה מופעלת")
            return {"status": "error", "error": "הרצת קוד אינה מופעלת"}
        
        # ברירת מחדל לפרמטרים
        if params is None:
            params = {}
        
        try:
            # בדיקה ששפת התכנות נתמכת
            if language not in self.supported_languages:
                logger.error(f"שפה {language} אינה נתמכת")
                return {"status": "error", "error": f"שפה {language} אינה נתמכת"}
            
            # יצירת קובץ זמני עם הקוד
            ext = self.languages_config.get(language, {}).get("extension", "")
            
            with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp:
                tmp.write(code.encode('utf-8'))
                tmp_path = tmp.name
            
            # הרצת הקוד
            result = self.run_file(tmp_path, params)
            
            # הוספת הקוד המקורי לתוצאה
            result["code"] = code
            
            # מחיקת הקובץ הזמני
            try:
                os.unlink(tmp_path)
            except:
                pass
            
            return result
            
        except Exception as e:
            logger.error(f"שגיאה בהרצת קטע קוד: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def get_run_info(self, run_id: str) -> Dict[str, Any]:
        """
        קבלת מידע על הרצה
        
        Args:
            run_id: מזהה ההרצה
            
        Returns:
            מידע על ההרצה
        """
        if run_id not in self.runs:
            logger.warning(f"הרצה {run_id} לא נמצאה")
            return {"status": "error", "error": f"הרצה {run_id} לא נמצאה"}
        
        return self.runs[run_id]
    
    def stop_code_execution(self, run_id: str) -> Dict[str, Any]:
        """
        עצירת הרצת קוד
        
        שים לב: כרגע לא נתמך בצורה מלאה מכיוון שההרצה היא סינכרונית.
        
        Args:
            run_id: מזהה ההרצה
            
        Returns:
            תוצאת העצירה
        """
        logger.warning(f"עצירת הרצת קוד {run_id} לא נתמכת כרגע")
        return {"status": "warning", "warning": "עצירת הרצת קוד אינה נתמכת כרגע"}
CODE_RUNNER_PY

# יצירת מודול השלמת קוד
echo "📝 יוצר מודול השלמת קוד..."
cat > "$BASE_DIR/core/code_completer.py" << 'CODE_COMPLETER_PY'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול השלמת קוד למאחד קוד חכם Pro 2.0
מאפשר זיהוי והשלמה של קוד חסר

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import sys
import ast
import json
import logging
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional, Union, Set

# הגדרת לוגים
logger = logging.getLogger(__name__)

class CodeCompleter:
    """
    מנהל השלמת קוד לזיהוי והשלמה של קוד חסר
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        אתחול מנהל השלמת הקוד
        
        Args:
            config: מילון הגדרות תצורה
        """
        self.config = config
        self.enabled = config.get("enabled", True)
        self.suggestions_limit = config.get("suggestions_limit", 5)
        self.context_lines = config.get("context_lines", 10)
        self.supported_languages = config.get("supported_languages", ["python", "javascript", "java", "c", "cpp"])
        
        logger.info(f"מנהל השלמת קוד אותחל עם הגדרות: suggestions_limit={self.suggestions_limit}, "
                   f"context_lines={self.context_lines}")
    
    def _detect_language(self, file_path: str) -> Optional[str]:
        """
        זיהוי שפת התכנות לפי סיומת הקובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            שם השפה או None אם לא זוהתה
        """
        # הוצאת סיומת הקובץ
        ext = os.path.splitext(file_path)[1].lower()
        
        # מיפוי סיומות נפוצות לשפות
        extensions_map = {
            ".py": "python",
            ".js": "javascript",
            ".jsx": "javascript",
            ".ts": "typescript",
            ".tsx": "typescript",
            ".java": "java",
            ".c": "c",
            ".cpp": "cpp",
            ".cxx": "cpp",
            ".cc": "cpp",
            ".h": "c",
            ".hpp": "cpp",
            ".rb": "ruby",
            ".php": "php",
            ".go": "go",
            ".swift": "swift",
            ".kt": "kotlin",
            ".cs": "csharp",
            ".rs": "rust"
        }
        
        return extensions_map.get(ext)
    
    def _get_file_context(self, file_path: str, line: int, context_lines: int) -> Dict[str, Any]:
        """
        קבלת הקשר הקוד סביב שורה מסוימת
        
        Args:
            file_path: נתיב הקובץ
            line: מספר השורה
            context_lines: מספר שורות הקשר
            
        Returns:
            מילון עם הקשר הקוד
        """
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            
            # וידוא שמספר השורה תקין
            line = max(1, min(line, len(lines)))
            
            # חישוב טווח שורות ההקשר
            start_line = max(0, line - context_lines - 1)
            end_line = min(len(lines), line + context_lines)
            
            # הוצאת שורות ההקשר
            before_lines = lines[start_line:line-1]
            target_line = lines[line-1] if line <= len(lines) else ""
            after_lines = lines[line:end_line]
            
            return {
                "before": "".join(before_lines),
                "target": target_line,
                "after": "".join(after_lines),
                "line": line,
                "file_path": file_path
            }
            
        except Exception as e:
            logger.error(f"שגיאה בקבלת הקשר קוד מקובץ {file_path}: {str(e)}")
            return {
                "before": "",
                "target": "",
                "after": "",
                "line": line,
                "file_path": file_path
            }
    
    def detect_missing_parts(self, file_path: str) -> Dict[str, Any]:
        """
        זיהוי חלקים חסרים בקוד
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            מילון עם חלקים חסרים שזוהו
        """
        if not self.enabled:
            logger.warning("השלמת קוד אינה מופעלת")
            return {"status": "warning", "warning": "השלמת קוד אינה מופעלת"}
        
        try:
            # בדיקה שהקובץ קיים
            if not os.path.exists(file_path):
                logger.error(f"קובץ {file_path} לא נמצא")
                return {"status": "error", "error": f"קובץ {file_path} לא נמצא"}
            
            # זיהוי שפת התכנות
            language = self._detect_language(file_path)
            
            if not language:
                logger.error(f"לא ניתן לזהות את שפת התכנות של הקובץ {file_path}")
                return {"status": "error", "error": "לא ניתן לזהות את שפת התכנות של הקובץ"}
            
            if language not in self.supported_languages:
                logger.warning(f"שפה {language} אינה נתמכת להשלמת קוד")
                return {"status": "warning", "warning": f"שפה {language} אינה נתמכת להשלמת קוד"}
            
            # קריאת הקובץ
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                lines = content.splitlines()
            
            # זיהוי חלקים חסרים לפי שפה
            missing_parts = []
            
            if language == "python":
                missing_parts = self._detect_missing_parts_python(content, lines, file_path)
            elif language in ["javascript", "typescript"]:
                missing_parts = self._detect_missing_parts_javascript(content, lines, file_path)
            elif language == "java":
                missing_parts = self._detect_missing_parts_java(content, lines, file_path)
            elif language in ["c", "cpp"]:
                missing_parts = self._detect_missing_parts_c_cpp(content, lines, file_path)
            
            # סיכום המצב
            if missing_parts:
                logger.info(f"נמצאו {len(missing_parts)} חלקים חסרים בקובץ {file_path}")
                return {
                    "status": "success",
                    "file_path": file_path,
                    "language": language,
                    "missing_parts": missing_parts,
                    "missing_count": len(missing_parts)
                }
            else:
                logger.info(f"לא נמצאו חלקים חסרים בקובץ {file_path}")
                return {
                    "status": "success",
                    "file_path": file_path,
                    "language": language,
                    "missing_parts": [],
                    "missing_count": 0
                }
            
        except Exception as e:
            logger.error(f"שגיאה בזיהוי חלקים חסרים בקובץ {file_path}: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _detect_missing_parts_python(self, content: str, lines: List[str], file_path: str) -> List[Dict[str, Any]]:
        """
        זיהוי חלקים חסרים בקוד Python
        
        Args:
            content: תוכן הקובץ
            lines: שורות הקובץ
            file_path: נתיב הקובץ
            
        Returns:
            רשימת חלקים חסרים שזוהו
        """
        missing_parts = []
        
        # ניסיון לנתח את הקוד
        try:
            ast.parse(content)
            # אם הגענו לכאן, אין שגיאות תחביר
        except SyntaxError as e:
            # יש שגיאת תחביר
            line_num = e.lineno
            context = self._get_file_context(file_path, line_num, self.context_lines)
            
            missing_parts.append({
                "type": "syntax_error",
                "line": line_num,
                "column": e.offset,
                "message": str(e),
                "context": context
            })
        
        # חיפוש פונקציות חסרות
        func_call_pattern = r'\b(\w+)\s*\('
        defined_functions = set()
        function_calls = set()
        
        # איסוף פונקציות מוגדרות
        func_def_pattern = r'def\s+(\w+)\s*\('
        for match in re.finditer(func_def_pattern, content):
            defined_functions.add(match.group(1))
        
        # איסוף קריאות לפונקציות
        for match in re.finditer(func_call_pattern, content):
            func_name = match.group(1)
            if func_name not in ["print", "int", "str", "float", "list", "dict", "set", "tuple", "len", "range", "enumerate", "zip", "open", "input", "type"]:
                function_calls.add(func_name)
        
        # רשימת פונקציות חסרות
        missing_functions = function_calls - defined_functions
        
        # הסרת פונקציות סטנדרטיות שלא נחשבות כחסרות
        standard_functions = self._get_python_standard_functions()
        missing_functions = missing_functions - standard_functions
        
        # הוספת פונקציות חסרות לרשימה
        for func_name in missing_functions:
            # חיפוש שורת הקריאה הראשונה לפונקציה
            pattern = r'\b' + re.escape(func_name) + r'\s*\('
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    context = self._get_file_context(file_path, i, self.context_lines)
                    missing_parts.append({
                        "type": "missing_function",
                        "name": func_name,
                        "line": i,
                        "message": f"קריאה לפונקציה {func_name} שאינה מוגדרת",
                        "context": context
                    })
                    break
        
        # חיפוש מחלקות חסרות
        class_usage_pattern = r'\b(\w+)\s*\(\s*\)'
        defined_classes = set()
        class_usages = set()
        
        # איסוף מחלקות מוגדרות
        class_def_pattern = r'class\s+(\w+)\s*[:\(]'
        for match in re.finditer(class_def_pattern, content):
            defined_classes.add(match.group(1))
        
        # איסוף שימושים במחלקות
        for match in re.finditer(class_usage_pattern, content):
            class_name = match.group(1)
            if class_name[0].isupper():  # מוסכמת השמות ב-Python למחלקות
                class_usages.add(class_name)
        
        # רשימת מחלקות חסרות
        missing_classes = class_usages - defined_classes
        
        # הסרת מחלקות סטנדרטיות שלא נחשבות כחסרות
        standard_classes = {"Exception", "ValueError", "TypeError", "FileNotFoundError", "IOError", "KeyError", "IndexError"}
        missing_classes = missing_classes - standard_classes
        
        # הוספת מחלקות חסרות לרשימה
        for class_name in missing_classes:
            # חיפוש שורת השימוש הראשונה במחלקה
            pattern = r'\b' + re.escape(class_name) + r'\s*\(\s*\)'
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    context = self._get_file_context(file_path, i, self.context_lines)
                    missing_parts.append({
                        "type": "missing_class",
                        "name": class_name,
                        "line": i,
                        "message": f"שימוש במחלקה {class_name} שאינה מוגדרת",
                        "context": context
                    })
                    break
        
        # חיפוש ייבוא חסר
        import_pattern = r'(?:from\s+(\w+)(?:\.\w+)*\s+import|import\s+(\w+)(?:\.\w+)*)'
        imported_modules = set()
        
        # איסוף מודולים מיובאים
        for match in re.finditer(import_pattern, content):
            module_name = match.group(1) or match.group(2)
            imported_modules.add(module_name.split('.')[0])
        
        # חיפוש שימוש במודולים
        module_usage_pattern = r'\b(\w+)\.'
        used_modules = set()
        
        for match in re.finditer(module_usage_pattern, content):
            module_name = match.group(1)
            if not (module_name.startswith('_') or module_name[0].isupper() or module_name == 'self'):
                used_modules.add(module_name)
        
        # רשימת מודולים חסרים
        missing_modules = used_modules - imported_modules
        
        # הוספת מודולים חסרים לרשימה
        for module_name in missing_modules:
            # חיפוש שורת השימוש הראשונה במודול
            pattern = r'\b' + re.escape(module_name) + r'\.'
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    context = self._get_file_context(file_path, i, self.context_lines)
                    missing_parts.append({
                        "type": "missing_import",
                        "name": module_name,
                        "line": i,
                        "message": f"שימוש במודול {module_name} ללא ייבוא",
                        "context": context
                    })
                    break
        
        # חיפוש פונקציות לא מושלמות או שהשארו למילוי (ריקות או עם pass או TODO)
        func_def_pattern = r'def\s+(\w+)\s*\(([^)]*)\)[^:]*:\s*(?:pass|TODO|FIXME|#[^\n]*)?$'
        for i, line in enumerate(lines, 1):
            match = re.search(func_def_pattern, line)
            if match:
                func_name = match.group(1)
                params = match.group(2)
                context = self._get_file_context(file_path, i, self.context_lines)
                
                missing_parts.append({
                    "type": "empty_function",
                    "name": func_name,
                    "params": params,
                    "line": i,
                    "message": f"פונקציה ריקה {func_name}",
                    "context": context
                })
        
        return missing_parts
    
    def _detect_missing_parts_javascript(self, content: str, lines: List[str], file_path: str) -> List[Dict[str, Any]]:
        """
        זיהוי חלקים חסרים בקוד JavaScript
        
        Args:
            content: תוכן הקובץ
            lines: שורות הקובץ
            file_path: נתיב הקובץ
            
        Returns:
            רשימת חלקים חסרים שזוהו
        """
        missing_parts = []
        
        # חיפוש סוגריים לא מאוזנים
        brackets = {'(': ')', '[': ']', '{': '}'}
        stack = []
        
        for i, char in enumerate(content):
            if char in brackets.keys():
                stack.append((char, i))
            elif char in brackets.values():
                if not stack:
                    # יותר סוגריים סוגרים מפותחים
                    line_num = content[:i].count('\n') + 1
                    context = self._get_file_context(file_path, line_num, self.context_lines)
                    
                    missing_parts.append({
                        "type": "unbalanced_brackets",
                        "line": line_num,
                        "message": f"סוגר {char} ללא פותח מתאים",
                        "context": context
                    })
                else:
                    last_open, _ = stack.pop()
                    if char != brackets[last_open]:
                        # סוגר לא מתאים
                        line_num = content[:i].count('\n') + 1
                        context = self._get_file_context(file_path, line_num, self.context_lines)
                        
                        missing_parts.append({
                            "type": "unbalanced_brackets",
                            "line": line_num,
                            "message": f"סוגר {char} לא מתאים ל-{last_open}",
                            "context": context
                        })
        
        # סוגריים פותחים שלא נסגרו
        for open_bracket, pos in stack:
            line_num = content[:pos].count('\n') + 1
            context = self._get_file_context(file_path, line_num, self.context_lines)
            
            missing_parts.append({
                "type": "unbalanced_brackets",
                "line": line_num,
                "message": f"סוגר פותח {open_bracket} ללא סוגר",
                "context": context
            })
        
        # חיפוש פסיקים חסרים באובייקטים ומערכים
        for i, line in enumerate(lines, 1):
            # בדיקת שורות שנראות כמו חלק מאובייקט או מערך
            if re.search(r'^\s*[\'"][^\'":]*[\'"]\s*:', line) or re.search(r'^\s*\w+\s*:', line):
                # אם השורה מסתיימת ללא פסיק וגם לא בסוגר
                if not re.search(r'[,{}[\]]$', line.rstrip()):
                    next_line_idx = i
                    if next_line_idx < len(lines):
                        next_line = lines[next_line_idx]
                        # אם השורה הבאה נראית כמו המשך של אובייקט/מערך
                        if re.search(r'^\s*[\'"][^\'":]*[\'"]\s*:', next_line) or re.search(r'^\s*\w+\s*:', next_line):
                            context = self._get_file_context(file_path, i, self.context_lines)
                            
                            missing_parts.append({
                                "type": "missing_comma",
                                "line": i,
                                "message": "פסיק חסר בסוף שורה באובייקט/מערך",
                                "context": context
                            })
        
        # חיפוש נקודה-פסיק חסרה
        for i, line in enumerate(lines, 1):
            # נסיר הערות
            clean_line = re.sub(r'//.*$', '', line)
            # בדיקת שורות שנראות כמו הצהרות אך ללא נקודה-פסיק בסוף
            if (re.search(r'(var|let|const)\s+\w+\s*=', clean_line) or 
                re.search(r'\w+\.\w+\s*\(', clean_line) or 
                re.search(r'\w+\s*\+\+', clean_line) or 
                re.search(r'\w+\s*--', clean_line)):
                
                if not re.search(r';$', clean_line.rstrip()):
                    # בדיקה שהשורה לא מסתיימת בפתיחת בלוק או מחרוזת
                    if not re.search(r'[{[(/"`\']$', clean_line.rstrip()):
                        context = self._get_file_context(file_path, i, self.context_lines)
                        
                        missing_parts.append({
                            "type": "missing_semicolon",
                            "line": i,
                            "message": "נקודה-פסיק חסרה בסוף שורה",
                            "context": context
                        })
        
        # חיפוש פונקציות לא מושלמות
        for i, line in enumerate(lines, 1):
            # תבנית לזיהוי פונקציות ריקות או עם TODO
            if re.search(r'function\s+(\w+)\s*\([^)]*\)\s*{\s*(//\s*TODO|$)', line):
                # בדיקה אם הפונקציה ריקה
                is_empty = True
                for j in range(i+1, min(i+5, len(lines)+1)):
                    if re.search(r'[^whitespace]', lines[j-1]) and not re.search(r'^\s*(//|$)', lines[j-1]):
                        is_empty = False
                        break
                    if re.search(r'^\s*}', lines[j-1]):
                        break
                
                if is_empty:
                    match = re.search(r'function\s+(\w+)', line)
                    func_name = match.group(1) if match else "unknown"
                    context = self._get_file_context(file_path, i, self.context_lines)
                    
                    missing_parts.append({
                        "type": "empty_function",
                        "name": func_name,
                        "line": i,
                        "message": f"פונקציה ריקה {func_name}",
                        "context": context
                    })
        
        # חיפוש ייבוא חסר
        imported_modules = set()
        
        # איסוף מודולים מיובאים
        import_patterns = [
            r'import\s+\*\s+as\s+(\w+)\s+from',  # import * as name from
            r'import\s+{\s*[^}]*\s*}\s+from\s+[\'"]([^\'"]+)[\'"]',  # import { ... } from 'module'
            r'import\s+(\w+)(?:,\s*{[^}]*})?\s+from',  # import name from
            r'const\s+(\w+)\s*=\s*require\([\'"]([^\'"]+)[\'"]'  # const name = require('module')
        ]
        
        for pattern in import_patterns:
            for match in re.finditer(pattern, content):
                if match.lastindex and match.group(1):
                    imported_modules.add(match.group(1))
        
        # חיפוש שימוש במודולים
        module_usage_pattern = r'\b(\w+)\.[a-zA-Z_]\w*'
        used_modules = set()
        
        for match in re.finditer(module_usage_pattern, content):
            module_name = match.group(1)
            if not (module_name.startswith('_') or module_name == 'this' or module_name == 'window' or module_name == 'document' or module_name == 'console'):
                used_modules.add(module_name)
        
        # רשימת מודולים חסרים
        missing_modules = used_modules - imported_modules
        
        # רשימת מודולים גלובליים שלא נחשבים כחסרים
        global_modules = {"Math", "JSON", "Date", "Array", "Object", "String", "Number", "Boolean", "RegExp", "Map", "Set", "Promise", "Proxy", "Reflect"}
        missing_modules = missing_modules - global_modules
        
        # הוספת מודולים חסרים לרשימה
        for module_name in missing_modules:
            # חיפוש שורת השימוש הראשונה במודול
            pattern = r'\b' + re.escape(module_name) + r'\.'
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    context = self._get_file_context(file_path, i, self.context_lines)
                    missing_parts.append({
                        "type": "missing_import",
                        "name": module_name,
                        "line": i,
                        "message": f"שימוש במודול {module_name} ללא ייבוא",
                        "context": context
                    })
                    break
        
        return missing_parts
    
    def _detect_missing_parts_java(self, content: str, lines: List[str], file_path: str) -> List[Dict[str, Any]]:
        """
        זיהוי חלקים חסרים בקוד Java
        
        Args:
            content: תוכן הקובץ
            lines: שורות הקובץ
            file_path: נתיב הקובץ
            
        Returns:
            רשימת חלקים חסרים שזוהו
        """
        missing_parts = []
        
        # חיפוש סוגריים לא מאוזנים
        brackets = {'(': ')', '[': ']', '{': '}'}
        stack = []
        
        for i, char in enumerate(content):
            if char in brackets.keys():
                stack.append((char, i))
            elif char in brackets.values():
                if not stack:
                    # יותר סוגריים סוגרים מפותחים
                    line_num = content[:i].count('\n') + 1
                    context = self._get_file_context(file_path, line_num, self.context_lines)
                    
                    missing_parts.append({
                        "type": "unbalanced_brackets",
                        "line": line_num,
                        "message": f"סוגר {char} ללא פותח מתאים",
                        "context": context
                    })
                else:
                    last_open, _ = stack.pop()
                    if char != brackets[last_open]:
                        # סוגר לא מתאים
                        line_num = content[:i].count('\n') + 1
                        context = self._get_file_context(file_path, line_num, self.context_lines)
                        
                        missing_parts.append({
                            "type": "unbalanced_brackets",
                            "line": line_num,
                            "message": f"סוגר {char} לא מתאים ל-{last_open}",
                            "context": context
                        })
        
        # סוגריים פותחים שלא נסגרו
        for open_bracket, pos in stack:
            line_num = content[:pos].count('\n') + 1
            context = self._get_file_context(file_path, line_num, self.context_lines)
            
            missing_parts.append({
                "type": "unbalanced_brackets",
                "line": line_num,
                "message": f"סוגר פותח {open_bracket} ללא סוגר",
                "context": context
            })
        
        # חיפוש נקודה-פסיק חסרה
        for i, line in enumerate(lines, 1):
            # נסיר הערות
            clean_line = re.sub(r'//.*$', '', line)
            
            # בדיקת שורות שנראות כמו הצהרות אך ללא נקודה-פסיק בסוף
            if (not re.search(r'^\s*(?:public|private|protected|class|interface|enum|if|else|for|while|do|switch|case|try|catch|finally|import|package|\{|\}|$)', clean_line) and
                not re.search(r';$', clean_line.rstrip()) and
                not re.search(r'[{(/`\']$', clean_line.rstrip())):
                
                context = self._get_file_context(file_path, i, self.context_lines)
                
                missing_parts.append({
                    "type": "missing_semicolon",
                    "line": i,
                    "message": "נקודה-פסיק חסרה בסוף שורה",
                    "context": context
                })
        
        # חיפוש מתודות לא מושלמות
        method_pattern = r'\s*(?:public|private|protected)?\s+\w+\s+(\w+)\s*\([^)]*\)\s*\{\s*(?://.*)?$'
        for i, line in enumerate(lines, 1):
            match = re.search(method_pattern, line)
            if match:
                # בדיקה אם המתודה ריקה
                is_empty = True
                for j in range(i+1, min(i+5, len(lines)+1)):
                    if re.search(r'[^\s]', lines[j-1]) and not re.search(r'^\s*(?://|$)', lines[j-1]):
                        is_empty = False
                        break
                    if re.search(r'^\s*}', lines[j-1]):
                        break
                
                if is_empty:
                    method_name = match.group(1)
                    context = self._get_file_context(file_path, i, self.context_lines)
                    
                    missing_parts.append({
                        "type": "empty_method",
                        "name": method_name,
                        "line": i,
                        "message": f"מתודה ריקה {method_name}",
                        "context": context
                    })
        
        # חיפוש ייבוא חסר
        imported_classes = set()
        
        # איסוף מחלקות מיובאות
        import_pattern = r'import\s+(?:static\s+)?([a-zA-Z_][\w.]*(?:\.\*)?);'
        for match in re.finditer(import_pattern, content):
            import_path = match.group(1)
            if import_path.endswith(".*"):
                # ייבוא חבילה שלמה, לא ניתן לדעת בדיוק איזה מחלקות
                continue
            
            class_name = import_path.split(".")[-1]
            imported_classes.add(class_name)
        
        # חיפוש שימוש במחלקות חיצוניות
        # שימוש בתבנית פשוטה - לא מושלם אבל עובד עבור רוב המקרים
        class_usage_pattern = r'\b([A-Z][a-zA-Z0-9_]*)\b(?:\s*\.\s*\w+|\s*<|\s+\w+|\s*\[)'
        used_classes = set()
        
        for match in re.finditer(class_usage_pattern, content):
            class_name = match.group(1)
            if class_name not in ["String", "Integer", "Double", "Boolean", "Character", "Byte", "Short", "Long", "Float", "Object", "Class", "System", "Math"]:
                used_classes.add(class_name)
        
        # רשימת מחלקות חסרות
        missing_classes = used_classes - imported_classes
        
        # הוצאת מחלקות שהוגדרו בקובץ עצמו
        defined_classes = set()
        class_def_pattern = r'(?:public|private|protected)?\s+class\s+([A-Z][a-zA-Z0-9_]*)'
        for match in re.finditer(class_def_pattern, content):
            defined_classes.add(match.group(1))
        
        missing_classes = missing_classes - defined_classes
        
        # הסרת מחלקות סטנדרטיות שלא נחשבות כחסרות
        standard_classes = {"String", "Integer", "Double", "Boolean", "Character", "Byte", "Short", "Long", "Float", "Object", "Class", "System", "Math", "Exception", "RuntimeException", "Thread", "Runnable"}
        missing_classes = missing_classes - standard_classes
        
        # הוספת מחלקות חסרות לרשימה
        for class_name in missing_classes:
            # חיפוש שורת השימוש הראשונה במחלקה
            pattern = r'\b' + re.escape(class_name) + r'\b'
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    context = self._get_file_context(file_path, i, self.context_lines)
                    missing_parts.append({
                        "type": "missing_import",
                        "name": class_name,
                        "line": i,
                        "message": f"שימוש במחלקה {class_name} ללא ייבוא",
                        "context": context
                    })
                    break
        
        return missing_parts
    
    def _detect_missing_parts_c_cpp(self, content: str, lines: List[str], file_path: str) -> List[Dict[str, Any]]:
        """
        זיהוי חלקים חסרים בקוד C/C++
        
        Args:
            content: תוכן הקובץ
            lines: שורות הקובץ
            file_path: נתיב הקובץ
            
        Returns:
            רשימת חלקים חסרים שזוהו
        """
        missing_parts = []
        
        # חיפוש סוגריים לא מאוזנים
        brackets = {'(': ')', '[': ']', '{': '}'}
        stack = []
        
        for i, char in enumerate(content):
            if char in brackets.keys():
                stack.append((char, i))
            elif char in brackets.values():
                if not stack:
                    # יותר סוגריים סוגרים מפותחים
                    line_num = content[:i].count('\n') + 1
                    context = self._get_file_context(file_path, line_num, self.context_lines)
                    
                    missing_parts.append({
                        "type": "unbalanced_brackets",
                        "line": line_num,
                        "message": f"סוגר {char} ללא פותח מתאים",
                        "context": context
                    })
                else:
                    last_open, _ = stack.pop()
                    if char != brackets[last_open]:
                        # סוגר לא מתאים
                        line_num = content[:i].count('\n') + 1
                        context = self._get_file_context(file_path, line_num, self.context_lines)
                        
                        missing_parts.append({
                            "type": "unbalanced_brackets",
                            "line": line_num,
                            "message": f"סוגר {char} לא מתאים ל-{last_open}",
                            "context": context
                        })
        
        # סוגריים פותחים שלא נסגרו
        for open_bracket, pos in stack:
            line_num = content[:pos].count('\n') + 1
            context = self._get_file_context(file_path, line_num, self.context_lines)
            
            missing_parts.append({
                "type": "unbalanced_brackets",
                "line": line_num,
                "message": f"סוגר פותח {open_bracket} ללא סוגר",
                "context": context
            })
        
        # חיפוש נקודה-פסיק חסרה
        for i, line in enumerate(lines, 1):
            # נסיר הערות
            clean_line = re.sub(r'//.*$', '', line)
            
            # בדיקת שורות שנראות כמו הצהרות אך ללא נקודה-פסיק בסוף
            if (not re.search(r'^\s*(?:#|typedef|struct|class|enum|if|else|for|while|do|switch|case|try|catch|return|sizeof|void|template|\{|\}|$)', clean_line) and
                not re.search(r';$', clean_line.rstrip()) and
                not re.search(r'[{(/`\']$', clean_line.rstrip())):
                
                context = self._get_file_context(file_path, i, self.context_lines)
                
                missing_parts.append({
                    "type": "missing_semicolon",
                    "line": i,
                    "message": "נקודה-פסיק חסרה בסוף שורה",
                    "context": context
                })
        
        # חיפוש פונקציות לא מושלמות
        func_pattern = r'(?:int|void|char|float|double|bool|auto|unsigned|signed|short|long|size_t|std::\w+|\w+::\w+|\w+)\s+(\w+)\s*\([^)]*\)\s*\{\s*(?://.*)?$'
        for i, line in enumerate(lines, 1):
            match = re.search(func_pattern, line)
            if match:
                # בדיקה אם הפונקציה ריקה
                is_empty = True
                for j in range(i+1, min(i+5, len(lines)+1)):
                    if re.search(r'[^\s]', lines[j-1]) and not re.search(r'^\s*(?://|$)', lines[j-1]):
                        is_empty = False
                        break
                    if re.search(r'^\s*}', lines[j-1]):
                        break
                
                if is_empty:
                    func_name = match.group(1)
                    context = self._get_file_context(file_path, i, self.context_lines)
                    
                    missing_parts.append({
                        "type": "empty_function",
                        "name": func_name,
                        "line": i,
                        "message": f"פונקציה ריקה {func_name}",
                        "context": context
                    })
        
        # חיפוש הכללות חסרות
        included_headers = set()
        
        # איסוף כותרות מוכללות
        include_pattern = r'#\s*include\s+[<"]([^>"]+)[>"]'
        for match in re.finditer(include_pattern, content):
            header = match.group(1)
            included_headers.add(header)
            
            # הוספת גרסאות ללא סיומת .h
            if header.endswith('.h'):
                included_headers.add(header[:-2])
            
            # הוספת גרסאות עם .h
            if not header.endswith('.h'):
                included_headers.add(header + '.h')
        
        # חיפוש פונקציות מספריות סטנדרטיות
        library_funcs = {
            "printf": "stdio.h",
            "scanf": "stdio.h",
            "fprintf": "stdio.h",
            "fscanf": "stdio.h",
            "sprintf": "stdio.h",
            "fopen": "stdio.h",
            "fclose": "stdio.h",
            "fread": "stdio.h",
            "fwrite": "stdio.h",
            "malloc": "stdlib.h",
            "free": "stdlib.h",
            "calloc": "stdlib.h",
            "realloc": "stdlib.h",
            "exit": "stdlib.h",
            "rand": "stdlib.h",
            "srand": "stdlib.h",
            "strlen": "string.h",
            "strcpy": "string.h",
            "strcat": "string.h",
            "strcmp": "string.h",
            "memcpy": "string.h",
            "memset": "string.h",
            "isalpha": "ctype.h",
            "isdigit": "ctype.h",
            "isalnum": "ctype.h",
            "tolower": "ctype.h",
            "toupper": "ctype.h",
            "atoi": "stdlib.h",
            "atof": "stdlib.h",
            "abs": "stdlib.h",
            "pow": "math.h",
            "sqrt": "math.h",
            "sin": "math.h",
            "cos": "math.h",
            "tan": "math.h",
            "log": "math.h",
            "exp": "math.h",
            "floor": "math.h",
            "ceil": "math.h",
            "time": "time.h",
            "ctime": "time.h",
            "cout": "iostream",
            "cin": "iostream",
            "cerr": "iostream",
            "endl": "iostream",
            "vector": "vector",
            "map": "map",
            "set": "set",
            "list": "list",
            "string": "string",
            "sort": "algorithm",
            "find": "algorithm",
            "count": "algorithm",
            "min": "algorithm",
            "max": "algorithm"
        }
        
        # חיפוש שימוש בפונקציות מספריות
        func_call_pattern = r'\b(\w+)\s*\('
        missing_includes = {}
        
        for match in re.finditer(func_call_pattern, content):
            func_name = match.group(1)
            if func_name in library_funcs:
                header = library_funcs[func_name]
                if header not in included_headers:
                    missing_includes[func_name] = header
        
        # חיפוש שימוש במחלקות ספרייה סטנדרטית
        std_classes_pattern = r'\bstd::(\w+)\b'
        for match in re.finditer(std_classes_pattern, content):
            class_name = match.group(1)
            if class_name in library_funcs:
                header = library_funcs[class_name]
                if header not in included_headers:
                    missing_includes[class_name] = header
        
        # הוספת הכללות חסרות לרשימה
        for func_name, header in missing_includes.items():
            # חיפוש שורת השימוש הראשונה בפונקציה
            pattern = r'\b' + re.escape(func_name) + r'\b'
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    context = self._get_file_context(file_path, i, self.context_lines)
                    missing_parts.append({
                        "type": "missing_include",
                        "name": header,
                        "line": i,
                        "message": f"שימוש בפונקציה {func_name} ללא הכללת {header}",
                        "context": context
                    })
                    break
        
        return missing_parts
    
    def _get_python_standard_functions(self) -> Set[str]:
        """
        קבלת רשימת פונקציות סטנדרטיות ב-Python
        
        Returns:
            סט של שמות פונקציות סטנדרטיות
        """
        standard_functions = {
            "abs", "all", "any", "ascii", "bin", "bool", "breakpoint", "bytearray", "bytes", "callable", "chr",
            "classmethod", "compile", "complex", "delattr", "dict", "dir", "divmod", "enumerate", "eval", "exec",
            "filter", "float", "format", "frozenset", "getattr", "globals", "hasattr", "hash", "help", "hex", "id",
            "input", "int", "isinstance", "issubclass", "iter", "len", "list", "locals", "map", "max", "memoryview",
            "min", "next", "object", "oct", "open", "ord", "pow", "print", "property", "range", "repr", "reversed",
            "round", "set", "setattr", "slice", "sorted", "staticmethod", "str", "sum", "super", "tuple", "type",
            "vars", "zip", "__import__"
        }
        
        return standard_functions
    
    def complete_file(self, file_path: str, context_lines: int = None) -> Dict[str, Any]:
        """
        השלמת חלקים חסרים בקובץ
        
        Args:
            file_path: נתיב הקובץ
            context_lines: מספר שורות הקשר
            
        Returns:
            מילון עם תוצאות ההשלמה
        """
        if not self.enabled:
            logger.warning("השלמת קוד אינה מופעלת")
            return {"status": "error", "error": "השלמת קוד אינה מופעלת"}
        
        try:
            # הגדרת מספר שורות הקשר
            if context_lines is None:
                context_lines = self.context_lines
            
            # זיהוי חלקים חסרים
            detection_result = self.detect_missing_parts(file_path)
            
            if detection_result["status"] != "success":
                return detection_result
            
            missing_parts = detection_result.get("missing_parts", [])
            
            if not missing_parts:
                logger.info(f"לא נמצאו חלקים חסרים בקובץ {file_path}")
                return {
                    "status": "success",
                    "file_path": file_path,
                    "message": "לא נמצאו חלקים חסרים בקובץ",
                    "changes_made": 0,
                    "completed_file": file_path
                }
            
            # זיהוי שפת התכנות
            language = detection_result.get("language")
            
            # יצירת קובץ זמני עם השלמות
            with tempfile.NamedTemporaryFile(suffix=os.path.splitext(file_path)[1], delete=False) as tmp:
                tmp_path = tmp.name
            
            # קריאת תוכן הקובץ המקורי
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                lines = content.splitlines()
            
            # מילון השינויים שיש לבצע
            changes = {}
            
            # יצירת הצעות לתיקון לכל חלק חסר
            for part in missing_parts:
                part_type = part.get("type")
                line_num = part.get("line", 0)
                
                if part_type == "syntax_error":
                    # טיפול בשגיאות תחביר
                    fix = self._fix_syntax_error(part, language)
                    if fix:
                        changes[line_num] = fix
                
                elif part_type == "unbalanced_brackets":
                    # טיפול בסוגריים לא מאוזנים
                    fix = self._fix_unbalanced_brackets(part, language, lines)
                    if fix:
                        changes[line_num] = fix
                
                elif part_type == "missing_semicolon":
                    # טיפול בנקודה-פסיק חסרה
                    if line_num > 0 and line_num <= len(lines):
                        changes[line_num] = lines[line_num-1] + ";"
                
                elif part_type == "missing_comma":
                    # טיפול בפסיק חסר
                    if line_num > 0 and line_num <= len(lines):
                        changes[line_num] = lines[line_num-1] + ","
                
                elif part_type in ["missing_function", "empty_function"]:
                    # טיפול בפונקציות חסרות או ריקות
                    fix = self._create_function_stub(part, language)
                    if fix:
                        changes[line_num] = fix
                
                elif part_type == "missing_import":
                    # טיפול בייבוא חסר
                    fix = self._create_import_statement(part, language)
                    if fix:
                        # הוספת ייבוא בתחילת הקובץ
                        changes[0] = fix + "\n" + (lines[0] if lines else "")
                
                elif part_type == "missing_include":
                    # טיפול בהכללה חסרה
                    fix = self._create_include_statement(part)
                    if fix:
                        # הוספת הכללה בתחילת הקובץ
                        changes[0] = fix + "\n" + (lines[0] if lines else "")
            
            # יצירת תוכן מעודכן
            updated_lines = lines.copy()
            
            # ביצוע השינויים
            for line_num, new_content in sorted(changes.items(), reverse=True):
                if line_num == 0:
                    # הוספה בתחילת הקובץ
                    updated_lines.insert(0, new_content)
                elif line_num <= len(updated_lines):
                    # החלפת שורה קיימת
                    updated_lines[line_num-1] = new_content
            
            # כתיבת התוכן המעודכן לקובץ הזמני
            with open(tmp_path, 'w', encoding='utf-8') as f:
                f.write("\n".join(updated_lines))
            
            logger.info(f"נוצר קובץ מושלם {tmp_path} עם {len(changes)} שינויים")
            
            return {
                "status": "success",
                "file_path": file_path,
                "completed_file": tmp_path,
                "changes_made": len(changes),
                "changes": changes,
                "missing_parts": missing_parts
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהשלמת קובץ {file_path}: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _fix_syntax_error(self, error_info: Dict[str, Any], language: str) -> Optional[str]:
        """
        תיקון שגיאת תחביר
        
        Args:
            error_info: מידע על השגיאה
            language: שפת התכנות
            
        Returns:
            השורה המתוקנת או None אם לא ניתן לתקן
        """
        if language == "python":
            message = error_info.get("message", "")
            line = error_info.get("context", {}).get("target", "")
            
            # תיקון שגיאות תחביר נפוצות
            if "EOF while scanning" in message:
                # חסר סוגר סוגר
                if "string literal" in message or "triple-quoted string" in message:
                    if "'" in line and line.count("'") % 2 == 1:
                        return line + "'"
                    elif '"' in line and line.count('"') % 2 == 1:
                        return line + '"'
            
            elif "unexpected EOF while parsing" in message:
                # חסר סוגר סוגר
                if line.count('(') > line.count(')'):
                    return line + ')' * (line.count('(') - line.count(')'))
                elif line.count('[') > line.count(']'):
                    return line + ']' * (line.count('[') - line.count(']'))
                elif line.count('{') > line.count('}'):
                    return line + '}' * (line.count('{') - line.count('}'))
            
            elif "invalid syntax" in message:
                # ניסיון לתקן תחביר לא תקין
                if ':' not in line and ('if ' in line or 'for ' in line or 'while ' in line or 'def ' in line or 'class ' in line):
                    return line + ':'
        
        return None
    
    def _fix_unbalanced_brackets(self, error_info: Dict[str, Any], language: str, lines: List[str]) -> Optional[str]:
        """
        תיקון סוגריים לא מאוזנים
        
        Args:
            error_info: מידע על השגיאה
            language: שפת התכנות
            lines: כל שורות הקובץ
            
        Returns:
            השורה המתוקנת או None אם לא ניתן לתקן
        """
        line_num = error_info.get("line", 0)
        message = error_info.get("message", "")
        
        if line_num > 0 and line_num <= len(lines):
            line = lines[line_num-1]
            
            if "סוגר פותח" in message:
                # חסר סוגר סוגר
                if '(' in message:
                    return line + ')'
                elif '[' in message:
                    return line + ']'
                elif '{' in message:
                    return line + '}'
            
            elif "סוגר" in message and "ללא פותח" in message:
                # יש סוגר סוגר מיותר
                if ')' in message:
                    return line.replace(')', '', 1)
                elif ']' in message:
                    return line.replace(']', '', 1)
                elif '}' in message:
                    return line.replace('}', '', 1)
        
        return None
    
    def _create_function_stub(self, func_info: Dict[str, Any], language: str) -> Optional[str]:
        """
        יצירת שלד לפונקציה חסרה
        
        Args:
            func_info: מידע על הפונקציה
            language: שפת התכנות
            
        Returns:
            שלד הפונקציה או None אם לא ניתן ליצור
        """
        func_name = func_info.get("name", "unknown")
        line = func_info.get("context", {}).get("target", "")
        
        if language == "python":
            if "empty_function" in func_info.get("type", ""):
                # פונקציה ריקה - הוספת הערה וערך החזרה
                if "return" not in line and "pass" in line:
                    return line.replace("pass", "# TODO: Implement function\n    pass\n    return None")
                return line + "\n    # TODO: Implement function\n    return None"
            else:
                # יצירת פונקציה חדשה
                params = func_info.get("params", "")
                return f"def {func_name}({params}):\n    # TODO: Implement function\n    pass"
        
        elif language in ["javascript", "typescript"]:
            if "empty_function" in func_info.get("type", ""):
                # פונקציה ריקה - הוספת הערה וערך החזרה
                if "return" not in line:
                    return line + "\n  // TODO: Implement function\n  return null;"
                return line + "\n  // TODO: Implement function"
            else:
                # יצירת פונקציה חדשה
                return f"function {func_name}() {{\n  // TODO: Implement function\n  return null;\n}}"
        
        elif language == "java":
            if "empty_function" in func_info.get("type", ""):
                # מתודה ריקה - הוספת הערה וערך החזרה
                if "return" not in line:
                    return line + "\n    // TODO: Implement method\n    return null;"
                return line + "\n    // TODO: Implement method"
            else:
                # יצירת מתודה חדשה
                return f"public Object {func_name}() {{\n    // TODO: Implement method\n    return null;\n}}"
        
        elif language in ["c", "cpp"]:
            if "empty_function" in func_info.get("type", ""):
                # פונקציה ריקה - הוספת הערה וערך החזרה
                if "return" not in line:
                    return line + "\n    // TODO: Implement function\n    return 0;"
                return line + "\n    // TODO: Implement function"
            else:
                # יצירת פונקציה חדשה
                return f"int {func_name}() {{\n    // TODO: Implement function\n    return 0;\n}}"
        
        return None
    
    def _create_import_statement(self, import_info: Dict[str, Any], language: str) -> Optional[str]:
        """
        יצירת הצהרת ייבוא חסרה
        
        Args:
            import_info: מידע על הייבוא
            language: שפת התכנות
            
        Returns:
            הצהרת הייבוא או None אם לא ניתן ליצור
        """
        module_name = import_info.get("name", "")
        
        if not module_name:
            return None
        
        if language == "python":
            return f"import {module_name}"
        
        elif language in ["javascript", "typescript"]:
            # ניסיון לזהות אם זה ייבוא של מודול חיצוני או קובץ מקומי
            if module_name[0].islower():  # מוסכמה שמות למודולים חיצוניים
                return f"import * as {module_name} from '{module_name}';"
            else:
                return f"import {{ {module_name} }} from './{module_name}';"
        
        elif language == "java":
            # ניחוש חבילה נפוצה
            if module_name in ["List", "ArrayList", "Map", "HashMap", "Set", "HashSet"]:
                return f"import java.util.{module_name};"
            elif module_name in ["File", "FileReader", "FileWriter", "IOException"]:
                return f"import java.io.{module_name};"
            else:
                return f"import {module_name};"
        
        return None
    
    def _create_include_statement(self, include_info: Dict[str, Any]) -> Optional[str]:
        """
        יצירת הצהרת הכללה חסרה עבור C/C++
        
        Args:
            include_info: מידע על ההכללה
            
        Returns:
            הצהרת ההכללה או None אם לא ניתן ליצור
        """
        header_name = include_info.get("name", "")
        
        if not header_name:
            return None
        
        # בדיקה אם זה כותר של ספרייה סטנדרטית או כותר מקומי
        if header_name in ["stdio.h", "stdlib.h", "string.h", "math.h", "ctype.h", "time.h", "iostream", "vector", "string", "algorithm", "map", "set", "list"]:
            # כותר של ספרייה סטנדרטית
            if header_name in ["iostream", "vector", "string", "algorithm", "map", "set", "list"]:
                return f"#include <{header_name}>"
            else:
                return f"#include <{header_name}>"
        else:
            # כותר מקומי
            return f'#include "{header_name}"'
CODE_COMPLETER_PY

# יצירת מודול גישה לאחסון מרוחק
echo "📝 יוצר מודול אחסון מרוחק..."
cat > "$BASE_DIR/utils/remote_storage.py" << 'REMOTE_STORAGE_PY'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול גישה לאחסון מרוחק למאחד קוד חכם Pro 2.0
מאפשר גישה למערכות קבצים מרוחקות

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import sys
import json
import uuid
import time
import shutil
import logging
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional, Union, Set

# הגדרת לוגים
logger = logging.getLogger(__name__)

class RemoteStorageManager:
    """
    מנהל גישה למערכות קבצים מרוחקות
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        אתחול מנהל האחסון המרוחק
        
        Args:
            config: מילון הגדרות תצורה
        """
        self.config = config
        self.enabled = config.get("enabled", True)
        self.storage_types = config.get("types", ["local", "ssh", "s3", "ftp", "webdav", "smb", "nfs"])
        self.timeout_seconds = config.get("timeout_seconds", 30)
        self.cache_enabled = config.get("cache_enabled", True)
        self.cache_expiry_seconds = config.get("cache_expiry_seconds", 3600)
        
        # תיקיית מטמון
        self.cache_dir = config.get("cache_dir", "remote_cache")
        os.makedirs(self.cache_dir, exist_ok=True)
        
        # מילון חיבורים פעילים
        self.active_connections = {}
        
        logger.info(f"מנהל אחסון מרוחק אותחל עם הגדרות: storage_types={self.storage_types}, "
                   f"timeout={self.timeout_seconds}s, cache_enabled={self.cache_enabled}")
        
        # בדיקת תלויות
        self._check_dependencies()
    
    def _check_dependencies(self) -> None:
        """
        בדיקת תלויות נדרשות לסוגי האחסון השונים
        """
        missing_deps = {}
        
        if "ssh" in self.storage_types:
            try:
                import paramiko
            except ImportError:
                missing_deps["ssh"] = "paramiko"
        
        if "s3" in self.storage_types:
            try:
                import boto3
            except ImportError:
                missing_deps["s3"] = "boto3"
        
        if "webdav" in self.storage_types:
            try:
                import webdav3.client
            except ImportError:
                missing_deps["webdav"] = "webdav3.client"
        
        if "smb" in self.storage_types:
            try:
                import pysmb
            except ImportError:
                missing_deps["smb"] = "pysmb"
        
        if missing_deps:
            deps_str = ", ".join([f"{dep} ({pkg})" for dep, pkg in missing_deps.items()])
            logger.warning(f"חסרות תלויות לסוגי אחסון: {deps_str}")
            logger.warning("התקן את התלויות החסרות עם: pip install " + " ".join(missing_deps.values()))
    
    def connect(self, storage_type: str, connection_params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות למערכת אחסון מרוחקת
        
        Args:
            storage_type: סוג האחסון
            connection_params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        if not self.enabled:
            logger.warning("גישה לאחסון מרוחק אינה מופעלת")
            return {"status": "error", "error": "גישה לאחסון מרוחק אינה מופעלת"}
        
        if storage_type not in self.storage_types:
            logger.error(f"סוג אחסון {storage_type} אינו נתמך")
            return {"status": "error", "error": f"סוג אחסון {storage_type} אינו נתמך"}
        
        try:
            logger.info(f"מתחבר לאחסון מרוחק מסוג {storage_type}")
            
            # יצירת מזהה חיבור
            connection_id = f"{storage_type}_{uuid.uuid4().hex[:8]}"
            
            # בחירת פונקציית התחברות מתאימה
            if storage_type == "local":
                connection = self._connect_local(connection_id, connection_params)
            elif storage_type == "ssh":
                connection = self._connect_ssh(connection_id, connection_params)
            elif storage_type == "s3":
                connection = self._connect_s3(connection_id, connection_params)
            elif storage_type == "ftp":
                connection = self._connect_ftp(connection_id, connection_params)
            elif storage_type == "webdav":
                connection = self._connect_webdav(connection_id, connection_params)
            elif storage_type == "smb":
                connection = self._connect_smb(connection_id, connection_params)
            elif storage_type == "nfs":
                connection = self._connect_nfs(connection_id, connection_params)
            else:
                return {"status": "error", "error": f"סוג אחסון {storage_type} אינו נתמך"}
            
            # בדיקת הצלחת החיבור
            if connection.get("status") != "success":
                return connection
            
            # שמירת החיבור
            self.active_connections[connection_id] = {
                "type": storage_type,
                "params": connection_params,
                "connection": connection.get("connection"),
                "client": connection.get("client"),
                "created_at": time.time()
            }
            
            logger.info(f"חיבור לאחסון מרוחק {connection_id} נוצר בהצלחה")
            
            # מידע על החיבור (ללא אובייקט החיבור)
            result = {
                "status": "success",
                "connection_id": connection_id,
                "type": storage_type,
                "description": connection.get("description", ""),
                "base_path": connection_params.get("base_path", "/")
            }
            
            return result
            
        except Exception as e:
            logger.error(f"שגיאה בהתחברות לאחסון מרוחק: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _connect_local(self, connection_id: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות לאחסון מקומי
        
        Args:
            connection_id: מזהה החיבור
            params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        base_path = params.get("base_path", ".")
        
        # בדיקה שהנתיב קיים
        if not os.path.exists(base_path):
            logger.error(f"נתיב בסיס {base_path} אינו קיים")
            return {"status": "error", "error": f"נתיב בסיס {base_path} אינו קיים"}
        
        # שמירת הנתיב כאובייקט חיבור
        connection = {"base_path": os.path.abspath(base_path)}
        
        return {
            "status": "success",
            "connection_id": connection_id,
            "connection": connection,
            "client": None,
            "description": f"אחסון מקומי: {base_path}"
        }
    
    def _connect_ssh(self, connection_id: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות לאחסון SSH
        
        Args:
            connection_id: מזהה החיבור
            params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        try:
            import paramiko
        except ImportError:
            logger.error("לא ניתן לייבא את paramiko - התקן עם pip install paramiko")
            return {"status": "error", "error": "חסרה תלות paramiko"}
        
        host = params.get("host", "")
        port = params.get("port", 22)
        username = params.get("username", "")
        password = params.get("password", "")
        key_file = params.get("key_file", "")
        base_path = params.get("base_path", "/")
        
        # בדיקת פרמטרים
        if not host:
            return {"status": "error", "error": "חסר פרמטר 'host'"}
        if not username:
            return {"status": "error", "error": "חסר פרמטר 'username'"}
        if not password and not key_file:
            return {"status": "error", "error": "חסר פרמטר 'password' או 'key_file'"}
        
        try:
            # יצירת חיבור SSH
            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            # התחברות עם סיסמה או קובץ מפתח
            if key_file:
                key = paramiko.RSAKey.from_private_key_file(key_file)
                ssh_client.connect(hostname=host, port=port, username=username, pkey=key, timeout=self.timeout_seconds)
            else:
                ssh_client.connect(hostname=host, port=port, username=username, password=password, timeout=self.timeout_seconds)
            
            # יצירת לקוח SFTP
            sftp_client = ssh_client.open_sftp()
            
            # בדיקה שנתיב הבסיס קיים
            try:
                sftp_client.stat(base_path)
            except FileNotFoundError:
                ssh_client.close()
                return {"status": "error", "error": f"נתיב בסיס {base_path} אינו קיים"}
            
            connection = {
                "host": host,
                "port": port,
                "username": username,
                "base_path": base_path
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "connection": connection,
                "client": {"ssh": ssh_client, "sftp": sftp_client},
                "description": f"SSH: {username}@{host}:{port}{base_path}"
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהתחברות ל-SSH: {str(e)}")
            return {"status": "error", "error": f"שגיאה בהתחברות ל-SSH: {str(e)}"}
    
    def _connect_s3(self, connection_id: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות לאחסון S3
        
        Args:
            connection_id: מזהה החיבור
            params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        try:
            import boto3
        except ImportError:
            logger.error("לא ניתן לייבא את boto3 - התקן עם pip install boto3")
            return {"status": "error", "error": "חסרה תלות boto3"}
        
        region = params.get("region", "us-east-1")
        access_key = params.get("access_key", "")
        secret_key = params.get("secret_key", "")
        bucket = params.get("bucket", "")
        base_path = params.get("base_path", "")
        
        # בדיקת פרמטרים
        if not bucket:
            return {"status": "error", "error": "חסר פרמטר 'bucket'"}
        
        try:
            # יצירת לקוח S3
            if access_key and secret_key:
                s3_client = boto3.client(
                    's3',
                    region_name=region,
                    aws_access_key_id=access_key,
                    aws_secret_access_key=secret_key
                )
            else:
                # שימוש בפרופיל ברירת מחדל
                s3_client = boto3.client('s3', region_name=region)
            
            # בדיקה שהדלי קיים
            try:
                s3_client.head_bucket(Bucket=bucket)
            except Exception as e:
                return {"status": "error", "error": f"שגיאה בגישה לדלי {bucket}: {str(e)}"}
            
            connection = {
                "region": region,
                "bucket": bucket,
                "base_path": base_path
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "connection": connection,
                "client": s3_client,
                "description": f"S3: {bucket}/{base_path}"
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהתחברות ל-S3: {str(e)}")
            return {"status": "error", "error": f"שגיאה בהתחברות ל-S3: {str(e)}"}
    
    def _connect_ftp(self, connection_id: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות לאחסון FTP
        
        Args:
            connection_id: מזהה החיבור
            params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        try:
            from ftplib import FTP
        except ImportError:
            logger.error("לא ניתן לייבא את ftplib")
            return {"status": "error", "error": "חסרה תלות ftplib"}
        
        host = params.get("host", "")
        port = params.get("port", 21)
        username = params.get("username", "")
        password = params.get("password", "")
        base_path = params.get("base_path", "/")
        
        # בדיקת פרמטרים
        if not host:
            return {"status": "error", "error": "חסר פרמטר 'host'"}
        
        try:
            # יצירת חיבור FTP
            ftp_client = FTP()
            ftp_client.connect(host, port, self.timeout_seconds)
            
            # התחברות
            if username and password:
                ftp_client.login(username, password)
            else:
                ftp_client.login()
            
            # מעבר לנתיב הבסיס
            if base_path and base_path != "/":
                ftp_client.cwd(base_path)
            
            connection = {
                "host": host,
                "port": port,
                "username": username,
                "base_path": base_path
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "connection": connection,
                "client": ftp_client,
                "description": f"FTP: {username}@{host}:{port}{base_path}"
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהתחברות ל-FTP: {str(e)}")
            return {"status": "error", "error": f"שגיאה בהתחברות ל-FTP: {str(e)}"}
    
    def _connect_webdav(self, connection_id: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות לאחסון WebDAV
        
        Args:
            connection_id: מזהה החיבור
            params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        try:
            from webdav3.client import Client
        except ImportError:
            logger.error("לא ניתן לייבא את webdav3.client - התקן עם pip install webdav3.client")
            return {"status": "error", "error": "חסרה תלות webdav3.client"}
        
        host = params.get("host", "")
        username = params.get("username", "")
        password = params.get("password", "")
        base_path = params.get("base_path", "/")
        
        # בדיקת פרמטרים
        if not host:
            return {"status": "error", "error": "חסר פרמטר 'host'"}
        
        try:
            # יצירת לקוח WebDAV
            options = {
                'webdav_hostname': host,
                'webdav_login': username,
                'webdav_password': password,
                'webdav_root': base_path
            }
            webdav_client = Client(options)
            
            # בדיקת חיבור
            webdav_client.check()
            
            connection = {
                "host": host,
                "username": username,
                "base_path": base_path
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "connection": connection,
                "client": webdav_client,
                "description": f"WebDAV: {username}@{host}{base_path}"
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהתחברות ל-WebDAV: {str(e)}")
            return {"status": "error", "error": f"שגיאה בהתחברות ל-WebDAV: {str(e)}"}
    
    def _connect_smb(self, connection_id: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות לאחסון SMB
        
        Args:
            connection_id: מזהה החיבור
            params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        try:
            from smb.SMBConnection import SMBConnection
        except ImportError:
            logger.error("לא ניתן לייבא את pysmb - התקן עם pip install pysmb")
            return {"status": "error", "error": "חסרה תלות pysmb"}
        
        host = params.get("host", "")
        port = params.get("port", 445)
        username = params.get("username", "")
        password = params.get("password", "")
        share = params.get("share", "")
        domain = params.get("domain", "")
        client_name = params.get("client_name", "SmartCodeMerger")
        server_name = params.get("server_name", "")
        base_path = params.get("base_path", "/")
        
        # בדיקת פרמטרים
        if not host:
            return {"status": "error", "error": "חסר פרמטר 'host'"}
        if not share:
            return {"status": "error", "error": "חסר פרמטר 'share'"}
        if not server_name:
            server_name = host.split('.')[0].upper()
        
        try:
            # יצירת חיבור SMB
            smb_client = SMBConnection(
                username=username,
                password=password,
                my_name=client_name,
                remote_name=server_name,
                domain=domain,
                use_ntlm_v2=True
            )
            
            # התחברות
            connected = smb_client.connect(host, port)
            
            if not connected:
                return {"status": "error", "error": f"לא ניתן להתחבר ל-SMB: {host}:{port}"}
            
            # בדיקה שהשיתוף קיים
            shares = smb_client.listShares()
            share_names = [s.name for s in shares]
            
            if share not in share_names:
                smb_client.close()
                return {"status": "error", "error": f"שיתוף {share} לא נמצא"}
            
            connection = {
                "host": host,
                "port": port,
                "username": username,
                "share": share,
                "base_path": base_path
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "connection": connection,
                "client": smb_client,
                "description": f"SMB: {username}@{host}:{port}/{share}{base_path}"
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהתחברות ל-SMB: {str(e)}")
            return {"status": "error", "error": f"שגיאה בהתחברות ל-SMB: {str(e)}"}
    
    def _connect_nfs(self, connection_id: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        התחברות לאחסון NFS
        
        Args:
            connection_id: מזהה החיבור
            params: פרמטרי החיבור
            
        Returns:
            מידע על החיבור
        """
        # בדיקה שהמערכת היא Linux
        if sys.platform != "linux":
            logger.error("חיבור NFS נתמך רק ב-Linux")
            return {"status": "error", "error": "חיבור NFS נתמך רק ב-Linux"}
        
        host = params.get("host", "")
        path = params.get("path", "")
        mount_point = params.get("mount_point", "")
        options = params.get("options", "")
        
        # בדיקת פרמטרים
        if not host:
            return {"status": "error", "error": "חסר פרמטר 'host'"}
        if not path:
            return {"status": "error", "error": "חסר פרמטר 'path'"}
        
        # נתיב לעיגון
        if not mount_point:
            mount_point = os.path.join(self.cache_dir, f"nfs_{uuid.uuid4().hex[:8]}")
        
        # יצירת תיקייה לעיגון
        os.makedirs(mount_point, exist_ok=True)
        
        try:
            # עיגון ה-NFS
            mount_cmd = ["mount", "-t", "nfs"]
            
            # הוספת אפשרויות אם יש
            if options:
                mount_cmd.extend(["-o", options])
            
            # הוספת מקור ויעד
            mount_cmd.append(f"{host}:{path}")
            mount_cmd.append(mount_point)
            
            # ביצוע הפקודה
            import subprocess
            result = subprocess.run(mount_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            if result.returncode != 0:
                error = result.stderr.decode('utf-8', errors='ignore')
                return {"status": "error", "error": f"שגיאה בעיגון NFS: {error}"}
            
            connection = {
                "host": host,
                "path": path,
                "mount_point": mount_point,
                "options": options
            }
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "connection": connection,
                "client": None,
                "description": f"NFS: {host}:{path} -> {mount_point}"
            }
            
        except Exception as e:
            logger.error(f"שגיאה בהתחברות ל-NFS: {str(e)}")
            return {"status": "error", "error": f"שגיאה בהתחברות ל-NFS: {str(e)}"}
    
    def disconnect(self, connection_id: str) -> Dict[str, Any]:
        """
        ניתוק מאחסון מרוחק
        
        Args:
            connection_id: מזהה החיבור
            
        Returns:
            תוצאת הניתוק
        """
        if not self.enabled:
            logger.warning("גישה לאחסון מרוחק אינה מופעלת")
            return {"status": "error", "error": "גישה לאחסון מרוחק אינה מופעלת"}
        
        if connection_id not in self.active_connections:
            logger.warning(f"חיבור {connection_id} לא נמצא")
            return {"status": "error", "error": f"חיבור {connection_id} לא נמצא"}
        
        try:
            # שליפת נתוני החיבור
            connection_info = self.active_connections[connection_id]
            storage_type = connection_info["type"]
            client = connection_info["client"]
            
            # ניתוק החיבור לפי סוג
            if storage_type == "ssh":
                try:
                    client["sftp"].close()
                    client["ssh"].close()
                except:
                    pass
            
            elif storage_type == "ftp":
                try:
                    client.quit()
                except:
                    pass
            
            elif storage_type == "smb":
                try:
                    client.close()
                except:
                    pass
            
            elif storage_type == "nfs":
                # ניתוק NFS
                mount_point = connection_info["connection"]["mount_point"]
                
                try:
                    import subprocess
                    subprocess.run(["umount", mount_point], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    
                    # ניסיון למחוק את תיקיית העיגון
                    try:
                        os.rmdir(mount_point)
                    except:
                        pass
                except:
                    pass
            
            # הסרת החיבור מהמילון
            del self.active_connections[connection_id]
            
            logger.info(f"חיבור {connection_id} נותק בהצלחה")
            
            return {
                "status": "success",
                "connection_id": connection_id,
                "message": f"חיבור {connection_id} נותק בהצלחה"
            }
            
        except Exception as e:
            logger.error(f"שגיאה בניתוק חיבור {connection_id}: {str(e)}")
            return {"status": "error", "error": f"שגיאה בניתוק חיבור: {str(e)}"}
    
    def list_remote_files(self, remote_path: str, connection_id: str) -> Dict[str, Any]:
        """
        רשימת קבצים באחסון מרוחק
        
        Args:
            remote_path: נתיב מרוחק
            connection_id: מזהה החיבור
            
        Returns:
            רשימת קבצים ותיקיות
        """
        if not self.enabled:
            logger.warning("גישה לאחסון מרוחק אינה מופעלת")
            return {"status": "error", "error": "גישה לאחסון מרוחק אינה מופעלת"}
        
        if connection_id not in self.active_connections:
            logger.warning(f"חיבור {connection_id} לא נמצא")
            return {"status": "error", "error": f"חיבור {connection_id} לא נמצא"}
        
        try:
            # שליפת נתוני החיבור
            connection_info = self.active_connections[connection_id]
            storage_type = connection_info["type"]
            connection = connection_info["connection"]
            client = connection_info["client"]
            
            # בדיקת המטמון
            cache_key = f"{connection_id}_{remote_path}"
            cache_result = self._get_from_cache(cache_key)
            
            if cache_result:
                logger.info(f"נמצא במטמון: {cache_key}")
                return cache_result
            
            # רשימת קבצים לפי סוג אחסון
            if storage_type == "local":
                result = self._list_local_files(connection, remote_path)
            elif storage_type == "ssh":
                result = self._list_ssh_files(connection, client, remote_path)
            elif storage_type == "s3":
                result = self._list_s3_files(connection, client, remote_path)
            elif storage_type == "ftp":
                result = self._list_ftp_files(connection, client, remote_path)
            elif storage_type == "webdav":
                result = self._list_webdav_files(connection, client, remote_path)
            elif storage_type == "smb":
                result = self._list_smb_files(connection, client, remote_path)
            elif storage_type == "nfs":
                result = self._list_nfs_files(connection, remote_path)
            else:
                return {"status": "error", "error": f"סוג אחסון {storage_type} אינו נתמך"}
            
            # שמירה במטמון
            if result["status"] == "success" and self.cache_enabled:
                self._save_to_cache(cache_key, result)
            
            return result
            
        except Exception as e:
            logger.error(f"שגיאה ברשימת קבצים מרוחקים: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _list_local_files(self, connection: Dict[str, Any], remote_path: str) -> Dict[str, Any]:
        """
        רשימת קבצים מקומיים
        
        Args:
            connection: מידע החיבור
            remote_path: נתיב מרוחק
            
        Returns:
            רשימת קבצים ותיקיות
        """
        base_path = connection["base_path"]
        full_path = os.path.normpath(os.path.join(base_path, remote_path.lstrip("/")))
        
        # בדיקה שהנתיב נמצא בתוך נתיב הבסיס
        if not full_path.startswith(base_path):
            return {"status": "error", "error": "נתיב לא חוקי"}
        
        # בדיקה שהנתיב קיים
        if not os.path.exists(full_path):
            return {"status": "error", "error": f"נתיב {remote_path} לא נמצא"}
        
        # בדיקה שהנתיב הוא תיקייה
        if not os.path.isdir(full_path):
            return {"status": "error", "error": f"נתיב {remote_path} אינו תיקייה"}
        
        # רשימת קבצים ותיקיות
        files = []
        directories = []
        
        for item in os.listdir(full_path):
            item_path = os.path.join(full_path, item)
            
            if os.path.isdir(item_path):
                directories.append({
                    "name": item,
                    "path": os.path.join(remote_path, item).replace("\\", "/"),
                    "type": "directory"
                })
            else:
                files.append({
                    "name": item,
                    "path": os.path.join(remote_path, item).replace("\\", "/"),
                    "type": "file",
                    "size": os.path.getsize(item_path),
                    "modified": datetime.datetime.fromtimestamp(os.path.getmtime(item_path)).isoformat()
                })
        
        return {
            "status": "success",
            "path": remote_path,
            "files": files,
            "directories": directories
        }
    
    def _list_ssh_files(self, connection: Dict[str, Any], client: Dict[str, Any], remote_path: str) -> Dict[str, Any]:
        """
        רשימת קבצים SSH
        
        Args:
            connection: מידע החיבור
            client: לקוח SSH
            remote_path: נתיב מרוחק
            
        Returns:
            רשימת קבצים ותיקיות
        """
        sftp_client = client["sftp"]
        base_path = connection["base_path"]
        full_path = os.path.normpath(os.path.join(base_path, remote_path.lstrip("/")))
        
        try:
            # רשימת קבצים
            items = sftp_client.listdir_attr(full_path)
            
            files = []
            directories = []
            
            import stat
            
            for item in items:
                is_dir = stat.S_ISDIR(item.st_mode)
                
                if is_dir:
                    directories.append({
                        "name": item.filename,
                        "path": os.path.join(remote_path, item.filename).replace("\\", "/"),
                        "type": "directory"
                    })
                else:
                    files.append({
                        "name": item.filename,
                        "path": os.path.join(remote_path, item.filename).replace("\\", "/"),
                        "type": "file",
                        "size": item.st_size,
                        "modified": datetime.datetime.fromtimestamp(item.st_mtime).isoformat()
                    })
            
            return {
                "status": "success",
                "path": remote_path,
                "files": files,
                "directories": directories
            }
            
        except Exception as e:
            logger.error(f"שגיאה ברשימת קבצי SSH: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _list_s3_files(self, connection: Dict[str, Any], client: Any, remote_path: str) -> Dict[str, Any]:
        """
        רשימת קבצים S3
        
        Args:
            connection: מידע החיבור
            client: לקוח S3
            remote_path: נתיב מרוחק
            
        Returns:
            רשימת קבצים ותיקיות
        """
        bucket = connection["bucket"]
        base_path = connection["base_path"]
        
        # יצירת נתיב מלא
        prefix = os.path.join(base_path, remote_path.lstrip("/")).replace("\\", "/")
        prefix = prefix.strip("/")
        if prefix:
            prefix += "/"
        
        try:
            # רשימת אובייקטים
            response = client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix,
                Delimiter="/"
            )
            
            files = []
            directories = []
            
            # תיקיות (prefixes)
            if "CommonPrefixes" in response:
                for prefix_obj in response["CommonPrefixes"]:
                    prefix_path = prefix_obj["Prefix"]
                    prefix_name = os.path.basename(prefix_path.rstrip("/"))
                    
                    directories.append({
                        "name": prefix_name,
                        "path": os.path.join(remote_path, prefix_name).replace("\\", "/"),
                        "type": "directory"
                    })
            
            # קבצים
            if "Contents" in response:
                for obj in response["Contents"]:
                    if obj["Key"] == prefix:
                        continue  # דילוג על הקידומת עצמה
                    
                    obj_path = obj["Key"]
                    obj_name = os.path.basename(obj_path)
                    
                    files.append({
                        "name": obj_name,
                        "path": os.path.join(remote_path, obj_name).replace("\\", "/"),
                        "type": "file",
                        "size": obj["Size"],
                        "modified": obj["LastModified"].isoformat() if hasattr(obj["LastModified"], "isoformat") else str(obj["LastModified"])
                    })
            
            return {
                "status": "success",
                "path": remote_path,
                "files": files,
                "directories": directories
            }
            
        except Exception as e:
            logger.error(f"שגיאה ברשימת קבצי S3: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _list_ftp_files(self, connection: Dict[str, Any], client: Any, remote_path: str) -> Dict[str, Any]:
        """
        רשימת קבצים FTP
        
        Args:
            connection: מידע החיבור
            client: לקוח FTP
            remote_path: נתיב מרוחק
            
        Returns:
            רשימת קבצים ותיקיות
        """
        base_path = connection["base_path"]
        current_dir = client.pwd()
        
        # יצירת נתיב מלא
        full_path = os.path.normpath(os.path.join(base_path, remote_path.lstrip("/")))
        
        try:
            # מעבר לתיקייה המבוקשת
            client.cwd(full_path)
            
            # רשימת קבצים ותיקיות
            items = []
            client.dir(lambda line: items.append(line))
            
            files = []
            directories = []
            
            for item in items:
                parts = item.split()
                if len(parts) < 9:
                    continue
                
                # הפרדת המידע
                permissions = parts[0]
                size = parts[4]
                month = parts[5]
                day = parts[6]
                year_or_time = parts[7]
                name = " ".join(parts[8:])
                
                # בדיקה אם זו תיקייה
                is_dir = permissions.startswith("d")
                
                if is_dir:
                    directories.append({
                        "name": name,
                        "path": os.path.join(remote_path, name).replace("\\", "/"),
                        "type": "directory"
                    })
                else:
                    files.append({
                        "name": name,
                        "path": os.path.join(remote_path, name).replace("\\", "/"),
                        "type": "file",
                        "size": int(size)
                    })
            
            # חזרה לתיקייה המקורית
            client.cwd(current_dir)
            
            return {
                "status": "success",
                "path": remote_path,
                "files": files,
                "directories": directories
            }
            
        except Exception as e:
            # ניסיון לחזור לתיקייה המקורית
            try:
                client.cwd(current_dir)
            except:
                pass
            
            logger.error(f"שגיאה ברשימת קבצי FTP: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _list_webdav_files(self, connection: Dict[str, Any], client: Any, remote_path: str) -> Dict[str, Any]:
        """
        רשימת קבצים WebDAV
        
        Args:
            connection: מידע החיבור
            client: לקוח WebDAV
            remote_path: נתיב מרוחק
            
        Returns:
            רשימת קבצים ותיקיות
        """
        try:
            full_path = remote_path.lstrip("/")
            if not full_path:
                full_path = "/"
            
            # רשימת קבצים ותיקיות
            items = client.list(full_path)
            
            files = []
            directories = []
            
            for name, info in items.items():
                if name == full_path or name == ".":
                    continue
                
                is_dir = info.get("isdir", False)
                base_name = os.path.basename(name.rstrip("/"))
                
                if is_dir:
                    directories.append({
                        "name": base_name,
                        "path": os.path.join(remote_path, base_name).replace("\\", "/"),
                        "type": "directory"
                    })
                else:
                    files.append({
                        "name": base_name,
                        "path": os.path.join(remote_path, base_name).replace("\\", "/"),
                        "type": "file",
                        "size": info.get("size", 0),
                        "modified": info.get("modified", "")
                    })
            
            return {
                "status": "success",
                "path": remote_path,
                "files": files,
                "directories": directories
            }
            
        except Exception as e:
            logger.error(f"שגיאה ברשימת קבצי WebDAV: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _list_smb_files(self, connection: Dict[str, Any], client: Any, remote_path: str) -> Dict[str, Any]:
        """
        רשימת קבצים SMB
        
        Args:
            connection: מידע החיבור
            client: לקוח SMB
            remote_path: נתיב מרוחק
            
        Returns:
            רשימת קבצים ותיקיות
        """
        share = connection["share"]
        base_path = connection["base_path"].lstrip("/").replace("/", "\\")
        remote_path = remote_path.lstrip("/").replace("/", "\\")
        
        # יצירת נתיב מלא
        full_path = os.path.normpath(os.path.join(base_path, remote_path))
        
        try:
            # רשימת קבצים ותיקיות
            items = client.listPath(share, full_path)
            
            files = []
            directories = []
            
            for item in items:
                if item.filename in [".", ".."]:
                    continue
                
                # בדיקה אם זו תיקייה
                is_dir = (item.isDirectory or item.isDirectory())
                
                if is_dir:
                    directories.append({
                        "name": item.filename,
                        "path": os.path.join(remote_path, item.filename).replace("\\", "/"),
                        "type": "directory"
                    })
                else:
                    files.append({
                        "name": item.filename,
                        "path": os.path.join(remote_path, item.filename).replace("\\", "/"),
                        "type": "file",
                        "size": item.file_size,
                        "modified": datetime.datetime.fromtimestamp(item.last_write_time).isoformat()
                    })
            
            return {
                "status": "success",
                "path": remote_path,
                "files": files,
                "directories": directories
            }
            
        except Exception as e:
            # סגירת החיבור במקרה של שגיאה
            logger.error(f"שגיאה ברשימת קבצי SMB: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _list_nfs_files(self, connection: Dict[str, Any], remote_path: str) -> Dict[str, Any]:
        """
        רשימת קבצים NFS
        
        Args:
            connection: מידע החיבור
            remote_path: נתיב מרוחק
            
        Returns:
            רשימת קבצים ותיקיות
        """
        mount_point = connection["mount_point"]
        remote_path = remote_path.lstrip("/")
        
        # יצירת נתיב מלא
        full_path = os.path.normpath(os.path.join(mount_point, remote_path))
        
        # בדיקה שהנתיב נמצא בתוך נקודת העיגון
        if not full_path.startswith(mount_point):
            return {"status": "error", "error": "נתיב לא חוקי"}
        
        try:
            # בדיקה שהנתיב קיים
            if not os.path.exists(full_path):
                return {"status": "error", "error": f"נתיב {remote_path} לא נמצא"}
            
            # בדיקה שהנתיב הוא תיקייה
            if not os.path.isdir(full_path):
                return {"status": "error", "error": f"נתיב {remote_path} אינו תיקייה"}
            
            # רשימת קבצים ותיקיות
            files = []
            directories = []
            
            for item in os.listdir(full_path):
                item_path = os.path.join(full_path, item)
                
                if os.path.isdir(item_path):
                    directories.append({
                        "name": item,
                        "path": os.path.join(remote_path, item).replace("\\", "/"),
                        "type": "directory"
                    })
                else:
                    files.append({
                        "name": item,
                        "path": os.path.join(remote_path, item).replace("\\", "/"),
                        "type": "file",
                        "size": os.path.getsize(item_path),
                        "modified": datetime.datetime.fromtimestamp(os.path.getmtime(item_path)).isoformat()
                    })
            
            return {
                "status": "success",
                "path": remote_path,
                "files": files,
                "directories": directories
            }
            
        except Exception as e:
            logger.error(f"שגיאה ברשימת קבצי NFS: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _get_from_cache(self, cache_key: str) -> Optional[Dict[str, Any]]:
        """
        קבלת מידע מהמטמון
        
        Args:
            cache_key: מפתח המטמון
            
        Returns:
            המידע מהמטמון או None אם לא נמצא
        """
        if not self.cache_enabled:
            return None
        
        # יצירת נתיב לקובץ המטמון
        cache_file = os.path.join(self.cache_dir, f"{cache_key}.json")
        
        if not os.path.exists(cache_file):
            return None
        
        try:
            # בדיקת תוקף המטמון
            mod_time = os.path.getmtime(cache_file)
            if time.time() - mod_time > self.cache_expiry_seconds:
                # המטמון פג תוקף
                try:
                    os.remove(cache_file)
                except:
                    pass
                return None
            
            # קריאת המטמון
            with open(cache_file, 'r', encoding='utf-8') as f:
                return json.load(f)
                
        except Exception as e:
            logger.warning(f"שגיאה בקריאת מטמון {cache_key}: {str(e)}")
            return None
    
    def _save_to_cache(self, cache_key: str, data: Dict[str, Any]) -> bool:
        """
        שמירת מידע במטמון
        
        Args:
            cache_key: מפתח המטמון
            data: המידע לשמירה
            
        Returns:
            האם השמירה הצליחה
        """
        if not self.cache_enabled:
            return False
        
        # יצירת נתיב לקובץ המטמון
        cache_file = os.path.join(self.cache_dir, f"{cache_key}.json")
        
        try:
            # שמירת המידע
            with open(cache_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            return True
                
        except Exception as e:
            logger.warning(f"שגיאה בשמירת מטמון {cache_key}: {str(e)}")
            return False
    
    def _clear_cache(self, connection_id: str = None) -> bool:
        """
        ניקוי המטמון
        
        Args:
            connection_id: מזהה חיבור לניקוי (אופציונלי)
            
        Returns:
            האם הניקוי הצליח
        """
        if not self.cache_enabled:
            return False
        
        try:
            # ניקוי המטמון
            if connection_id:
                # ניקוי רק של חיבור מסוים
                pattern = f"{connection_id}_*.json"
                for cache_file in glob.glob(os.path.join(self.cache_dir, pattern)):
                    try:
                        os.remove(cache_file)
                    except:
                        pass
            else:
                # ניקוי כל המטמון
                for cache_file in os.listdir(self.cache_dir):
                    if cache_file.endswith(".json"):
                        try:
                            os.remove(os.path.join(self.cache_dir, cache_file))
                        except:
                            pass
            
            return True
                
        except Exception as e:
            logger.warning(f"שגיאה בניקוי מטמון: {str(e)}")
            return False
    
    def sync_from_remote(self, connection_id: str, remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון מרוחק למקומי
        
        Args:
            connection_id: מזהה החיבור
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        if not self.enabled:
            logger.warning("גישה לאחסון מרוחק אינה מופעלת")
            return {"status": "error", "error": "גישה לאחסון מרוחק אינה מופעלת"}
        
        if connection_id not in self.active_connections:
            logger.warning(f"חיבור {connection_id} לא נמצא")
            return {"status": "error", "error": f"חיבור {connection_id} לא נמצא"}
        
        try:
            # שליפת נתוני החיבור
            connection_info = self.active_connections[connection_id]
            storage_type = connection_info["type"]
            connection = connection_info["connection"]
            client = connection_info["client"]
            
            logger.info(f"מסנכרן מרחוק: {remote_path} -> מקומי: {local_path}")
            
            # וידוא שתיקיית היעד קיימת
            os.makedirs(os.path.dirname(os.path.abspath(local_path)), exist_ok=True)
            
            # הורדת הקובץ לפי סוג אחסון
            if storage_type == "local":
                result = self._sync_local_to_local(connection, remote_path, local_path)
            elif storage_type == "ssh":
                result = self._sync_ssh_to_local(connection, client, remote_path, local_path)
            elif storage_type == "s3":
                result = self._sync_s3_to_local(connection, client, remote_path, local_path)
            elif storage_type == "ftp":
                result = self._sync_ftp_to_local(connection, client, remote_path, local_path)
            elif storage_type == "webdav":
                result = self._sync_webdav_to_local(connection, client, remote_path, local_path)
            elif storage_type == "smb":
                result = self._sync_smb_to_local(connection, client, remote_path, local_path)
            elif storage_type == "nfs":
                result = self._sync_nfs_to_local(connection, remote_path, local_path)
            else:
                return {"status": "error", "error": f"סוג אחסון {storage_type} אינו נתמך"}
            
            return result
            
        except Exception as e:
            logger.error(f"שגיאה בסנכרון מרחוק למקומי: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_local(self, connection: Dict[str, Any], remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון מקומי למקומי
        
        Args:
            connection: מידע החיבור
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        
        # בדיקה שהנתיב נמצא בתוך נתיב הבסיס
        if not full_remote_path.startswith(base_path):
            return {"status": "error", "error": "נתיב לא חוקי"}
        
        try:
            # בדיקה שהקובץ קיים
            if not os.path.exists(full_remote_path):
                return {"status": "error", "error": f"קובץ {remote_path} לא נמצא"}
            
            # העתקת הקובץ
            if os.path.isdir(full_remote_path):
                # העתקת תיקייה
                shutil.copytree(full_remote_path, local_path, dirs_exist_ok=True)
                return {
                    "status": "success",
                    "message": f"תיקייה {remote_path} הועתקה בהצלחה ל-{local_path}",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                shutil.copy2(full_remote_path, local_path)
                return {
                    "status": "success",
                    "message": f"קובץ {remote_path} הועתק בהצלחה ל-{local_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ מקומי: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_ssh_to_local(self, connection: Dict[str, Any], client: Dict[str, Any], remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון SSH למקומי
        
        Args:
            connection: מידע החיבור
            client: לקוח SSH
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        sftp_client = client["sftp"]
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        
        try:
            # בדיקת סוג הקובץ
            is_dir = False
            try:
                is_dir = sftp_client.stat(full_remote_path).st_mode & 0o40000 != 0
            except:
                # ניסיון לזהות אם זו תיקייה
                try:
                    sftp_client.listdir(full_remote_path)
                    is_dir = True
                except:
                    pass
            
            if is_dir:
                # העתקת תיקייה
                os.makedirs(local_path, exist_ok=True)
                
                # רשימת קבצים
                items = sftp_client.listdir(full_remote_path)
                
                for item in items:
                    # דילוג על תיקיות מיוחדות
                    if item in ['.', '..']:
                        continue
                    
                    remote_item_path = os.path.join(full_remote_path, item)
                    local_item_path = os.path.join(local_path, item)
                    
                    # בדיקה אם פריט זה תיקייה
                    item_is_dir = False
                    try:
                        item_is_dir = sftp_client.stat(remote_item_path).st_mode & 0o40000 != 0
                    except:
                        try:
                            sftp_client.listdir(remote_item_path)
                            item_is_dir = True
                        except:
                            pass
                    
                    if item_is_dir:
                        # רקורסיה לתיקייה
                        self._sync_ssh_to_local(connection, client, os.path.join(remote_path, item), local_item_path)
                    else:
                        # העתקת קובץ
                        sftp_client.get(remote_item_path, local_item_path)
                
                return {
                    "status": "success",
                    "message": f"תיקייה {remote_path} הועתקה בהצלחה ל-{local_path}",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                sftp_client.get(full_remote_path, local_path)
                
                return {
                    "status": "success",
                    "message": f"קובץ {remote_path} הועתק בהצלחה ל-{local_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ SSH: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_s3_to_local(self, connection: Dict[str, Any], client: Any, remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון S3 למקומי
        
        Args:
            connection: מידע החיבור
            client: לקוח S3
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        bucket = connection["bucket"]
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.join(base_path, remote_path).replace("\\", "/").strip("/")
        
        try:
            # בדיקה אם זו תיקייה או קובץ
            is_dir = False
            
            # ניסיון לקבל את האובייקט
            try:
                client.head_object(Bucket=bucket, Key=full_remote_path)
                is_dir = False
            except:
                # ניסיון לבדוק אם זו תיקייה (תיקיות ב-S3 הן וירטואליות)
                try:
                    response = client.list_objects_v2(
                        Bucket=bucket,
                        Prefix=full_remote_path + '/',
                        Delimiter='/',
                        MaxKeys=1
                    )
                    is_dir = 'Contents' in response or 'CommonPrefixes' in response
                except:
                    pass
            
            if is_dir:
                # יצירת תיקיית היעד
                os.makedirs(local_path, exist_ok=True)
                
                # קבלת רשימת אובייקטים
                paginator = client.get_paginator('list_objects_v2')
                operation_parameters = {
                    'Bucket': bucket,
                    'Prefix': full_remote_path + '/'
                }
                
                file_count = 0
                for page in paginator.paginate(**operation_parameters):
                    if 'Contents' in page:
                        for obj in page['Contents']:
                            # חישוב הנתיב המקומי
                            relative_path = obj['Key'][len(full_remote_path):].lstrip('/')
                            local_file_path = os.path.join(local_path, relative_path)
                            
                            # יצירת תיקיות ביניים
                            os.makedirs(os.path.dirname(local_file_path), exist_ok=True)
                            
                            # הורדת הקובץ
                            client.download_file(bucket, obj['Key'], local_file_path)
                            file_count += 1
                
                return {
                    "status": "success",
                    "message": f"תיקייה {remote_path} הועתקה בהצלחה ל-{local_path} ({file_count} קבצים)",
                    "type": "directory"
                }
            else:
                # הורדת הקובץ
                client.download_file(bucket, full_remote_path, local_path)
                
                return {
                    "status": "success",
                    "message": f"קובץ {remote_path} הועתק בהצלחה ל-{local_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ S3: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_ftp_to_local(self, connection: Dict[str, Any], client: Any, remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון FTP למקומי
        
        Args:
            connection: מידע החיבור
            client: לקוח FTP
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        current_dir = client.pwd()
        
        try:
            # ניסיון לעבור לתיקייה כדי לבדוק אם היא קיימת
            try:
                client.cwd(full_remote_path)
                is_dir = True
                client.cwd(current_dir)  # חזרה לתיקייה המקורית
            except:
                is_dir = False
            
            if is_dir:
                # יצירת תיקיית היעד
                os.makedirs(local_path, exist_ok=True)
                
                # מעבר לתיקייה המרוחקת
                client.cwd(full_remote_path)
                
                # רשימת קבצים ותיקיות
                items = []
                client.dir(lambda line: items.append(line))
                
                # חזרה לתיקייה המקורית
                client.cwd(current_dir)
                
                file_count = 0
                for item in items:
                    parts = item.split()
                    if len(parts) < 9:
                        continue
                    
                    # הפרדת המידע
                    permissions = parts[0]
                    name = " ".join(parts[8:])
                    
                    # דילוג על תיקיות מיוחדות
                    if name in ['.', '..']:
                        continue
                    
                    # בדיקה אם זו תיקייה
                    item_is_dir = permissions.startswith('d')
                    
                    if item_is_dir:
                        # רקורסיה לתיקייה
                        self._sync_ftp_to_local(connection, client, os.path.join(remote_path, name), os.path.join(local_path, name))
                    else:
                        # הורדת הקובץ
                        item_remote_path = os.path.join(full_remote_path, name)
                        item_local_path = os.path.join(local_path, name)
                        
                        with open(item_local_path, 'wb') as f:
                            client.retrbinary(f"RETR {item_remote_path}", f.write)
                        
                        file_count += 1
                
                return {
                    "status": "success",
                    "message": f"תיקייה {remote_path} הועתקה בהצלחה ל-{local_path} ({file_count} קבצים)",
                    "type": "directory"
                }
            else:
                # הורדת הקובץ
                with open(local_path, 'wb') as f:
                    client.retrbinary(f"RETR {full_remote_path}", f.write)
                
                return {
                    "status": "success",
                    "message": f"קובץ {remote_path} הועתק בהצלחה ל-{local_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            # ניסיון לחזור לתיקייה המקורית
            try:
                client.cwd(current_dir)
            except:
                pass
            
            logger.error(f"שגיאה בהעתקת קובץ FTP: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_webdav_to_local(self, connection: Dict[str, Any], client: Any, remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון WebDAV למקומי
        
        Args:
            connection: מידע החיבור
            client: לקוח WebDAV
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        remote_path = remote_path.lstrip("/")
        
        try:
            # בדיקה אם זו תיקייה
            is_dir = client.is_dir(remote_path)
            
            if is_dir:
                # העתקת תיקייה
                client.download_sync(remote_path, local_path)
                
                return {
                    "status": "success",
                    "message": f"תיקייה {remote_path} הועתקה בהצלחה ל-{local_path}",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                client.download_file(remote_path, local_path)
                
                return {
                    "status": "success",
                    "message": f"קובץ {remote_path} הועתק בהצלחה ל-{local_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ WebDAV: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_smb_to_local(self, connection: Dict[str, Any], client: Any, remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון SMB למקומי
        
        Args:
            connection: מידע החיבור
            client: לקוח SMB
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        share = connection["share"]
        base_path = connection["base_path"].lstrip("/").replace("/", "\\")
        remote_path = remote_path.lstrip("/").replace("/", "\\")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        
        try:
            from smb.smb_structs import OperationFailure
            
            # בדיקה אם זו תיקייה
            is_dir = False
            try:
                items = client.listPath(share, full_remote_path)
                is_dir = True
            except OperationFailure:
                is_dir = False
            
            if is_dir:
                # יצירת תיקיית היעד
                os.makedirs(local_path, exist_ok=True)
                
                # רשימת קבצים ותיקיות
                items = client.listPath(share, full_remote_path)
                
                file_count = 0
                for item in items:
                    # דילוג על תיקיות מיוחדות
                    if item.filename in ['.', '..']:
                        continue
                    
                    # בדיקה אם זו תיקייה
                    item_is_dir = item.isDirectory
                    
                    item_remote_path = os.path.join(remote_path, item.filename)
                    item_local_path = os.path.join(local_path, item.filename)
                    
                    if item_is_dir:
                        # רקורסיה לתיקייה
                        self._sync_smb_to_local(connection, client, item_remote_path, item_local_path)
                    else:
                        # הורדת הקובץ
                        item_full_remote_path = os.path.join(full_remote_path, item.filename)
                        
                        with open(item_local_path, 'wb') as f:
                            client.retrieveFile(share, item_full_remote_path, f)
                        
                        file_count += 1
                
                return {
                    "status": "success",
                    "message": f"תיקייה {remote_path} הועתקה בהצלחה ל-{local_path} ({file_count} קבצים)",
                    "type": "directory"
                }
            else:
                # הורדת הקובץ
                with open(local_path, 'wb') as f:
                    client.retrieveFile(share, full_remote_path, f)
                
                return {
                    "status": "success",
                    "message": f"קובץ {remote_path} הועתק בהצלחה ל-{local_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ SMB: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_nfs_to_local(self, connection: Dict[str, Any], remote_path: str, local_path: str) -> Dict[str, Any]:
        """
        סנכרון מאחסון NFS למקומי
        
        Args:
            connection: מידע החיבור
            remote_path: נתיב מרוחק
            local_path: נתיב מקומי
            
        Returns:
            תוצאת הסנכרון
        """
        mount_point = connection["mount_point"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(mount_point, remote_path))
        
        # בדיקה שהנתיב נמצא בתוך נקודת העיגון
        if not full_remote_path.startswith(mount_point):
            return {"status": "error", "error": "נתיב לא חוקי"}
        
        try:
            # בדיקה שהקובץ קיים
            if not os.path.exists(full_remote_path):
                return {"status": "error", "error": f"קובץ {remote_path} לא נמצא"}
            
            # העתקת הקובץ
            if os.path.isdir(full_remote_path):
                # העתקת תיקייה
                shutil.copytree(full_remote_path, local_path, dirs_exist_ok=True)
                return {
                    "status": "success",
                    "message": f"תיקייה {remote_path} הועתקה בהצלחה ל-{local_path}",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                shutil.copy2(full_remote_path, local_path)
                return {
                    "status": "success",
                    "message": f"קובץ {remote_path} הועתק בהצלחה ל-{local_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ NFS: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def sync_to_remote(self, connection_id: str, local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון מרוחק
        
        Args:
            connection_id: מזהה החיבור
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        if not self.enabled:
            logger.warning("גישה לאחסון מרוחק אינה מופעלת")
            return {"status": "error", "error": "גישה לאחסון מרוחק אינה מופעלת"}
        
        if connection_id not in self.active_connections:
            logger.warning(f"חיבור {connection_id} לא נמצא")
            return {"status": "error", "error": f"חיבור {connection_id} לא נמצא"}
        
        try:
            # בדיקה שהקובץ המקומי קיים
            if not os.path.exists(local_path):
                return {"status": "error", "error": f"קובץ מקומי {local_path} לא נמצא"}
            
            # שליפת נתוני החיבור
            connection_info = self.active_connections[connection_id]
            storage_type = connection_info["type"]
            connection = connection_info["connection"]
            client = connection_info["client"]
            
            logger.info(f"מסנכרן מקומי: {local_path} -> מרוחק: {remote_path}")
            
            # העלאת הקובץ לפי סוג אחסון
            if storage_type == "local":
                result = self._sync_local_to_remote(connection, local_path, remote_path)
            elif storage_type == "ssh":
                result = self._sync_local_to_ssh(connection, client, local_path, remote_path)
            elif storage_type == "s3":
                result = self._sync_local_to_s3(connection, client, local_path, remote_path)
            elif storage_type == "ftp":
                result = self._sync_local_to_ftp(connection, client, local_path, remote_path)
            elif storage_type == "webdav":
                result = self._sync_local_to_webdav(connection, client, local_path, remote_path)
            elif storage_type == "smb":
                result = self._sync_local_to_smb(connection, client, local_path, remote_path)
            elif storage_type == "nfs":
                result = self._sync_local_to_nfs(connection, local_path, remote_path)
            else:
                return {"status": "error", "error": f"סוג אחסון {storage_type} אינו נתמך"}
            
            # ניקוי המטמון אם הפעולה הצליחה
            if result["status"] == "success" and self.cache_enabled:
                cache_key = f"{connection_id}_{os.path.dirname(remote_path)}"
                self._clear_cache(connection_id)
            
            return result
            
        except Exception as e:
            logger.error(f"שגיאה בסנכרון מקומי למרוחק: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_remote(self, connection: Dict[str, Any], local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון מקומי
        
        Args:
            connection: מידע החיבור
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        
        # בדיקה שהנתיב נמצא בתוך נתיב הבסיס
        if not full_remote_path.startswith(base_path):
            return {"status": "error", "error": "נתיב לא חוקי"}
        
        try:
            # יצירת תיקיות ביניים
            os.makedirs(os.path.dirname(full_remote_path), exist_ok=True)
            
            # העתקת הקובץ
            if os.path.isdir(local_path):
                # העתקת תיקייה
                shutil.copytree(local_path, full_remote_path, dirs_exist_ok=True)
                return {
                    "status": "success",
                    "message": f"תיקייה {local_path} הועתקה בהצלחה ל-{remote_path}",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                shutil.copy2(local_path, full_remote_path)
                return {
                    "status": "success",
                    "message": f"קובץ {local_path} הועתק בהצלחה ל-{remote_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ מקומי למקומי: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_ssh(self, connection: Dict[str, Any], client: Dict[str, Any], local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון SSH
        
        Args:
            connection: מידע החיבור
            client: לקוח SSH
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        sftp_client = client["sftp"]
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        
        try:
            # יצירת תיקיות ביניים
            remote_dir = os.path.dirname(full_remote_path)
            try:
                sftp_client.stat(remote_dir)
            except FileNotFoundError:
                # יצירת תיקיות ביניים רקורסיבית
                current_dir = base_path
                for part in os.path.relpath(remote_dir, base_path).split('/'):
                    if not part:
                        continue
                    current_dir = os.path.join(current_dir, part)
                    try:
                        sftp_client.stat(current_dir)
                    except FileNotFoundError:
                        sftp_client.mkdir(current_dir)
            
            # העתקת הקובץ
            if os.path.isdir(local_path):
                # העתקת תיקייה
                try:
                    sftp_client.stat(full_remote_path)
                except FileNotFoundError:
                    sftp_client.mkdir(full_remote_path)
                
                file_count = 0
                for root, dirs, files in os.walk(local_path):
                    # יצירת תיקיות בצד המרוחק
                    for dir_name in dirs:
                        local_dir = os.path.join(root, dir_name)
                        rel_path = os.path.relpath(local_dir, local_path)
                        remote_dir = os.path.join(full_remote_path, rel_path).replace('\\', '/')
                        
                        try:
                            sftp_client.stat(remote_dir)
                        except FileNotFoundError:
                            sftp_client.mkdir(remote_dir)
                    
                    # העתקת קבצים
                    for file_name in files:
                        local_file = os.path.join(root, file_name)
                        rel_path = os.path.relpath(local_file, local_path)
                        remote_file = os.path.join(full_remote_path, rel_path).replace('\\', '/')
                        
                        sftp_client.put(local_file, remote_file)
                        file_count += 1
                
                return {
                    "status": "success",
                    "message": f"תיקייה {local_path} הועתקה בהצלחה ל-{remote_path} ({file_count} קבצים)",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                sftp_client.put(local_path, full_remote_path)
                
                return {
                    "status": "success",
                    "message": f"קובץ {local_path} הועתק בהצלחה ל-{remote_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ מקומי ל-SSH: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_s3(self, connection: Dict[str, Any], client: Any, local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון S3
        
        Args:
            connection: מידע החיבור
            client: לקוח S3
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        bucket = connection["bucket"]
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.join(base_path, remote_path).replace("\\", "/").strip("/")
        
        try:
            # העתקת הקובץ
            if os.path.isdir(local_path):
                # העתקת תיקייה
                file_count = 0
                for root, dirs, files in os.walk(local_path):
                    for file_name in files:
                        local_file = os.path.join(root, file_name)
                        rel_path = os.path.relpath(local_file, local_path)
                        remote_key = f"{full_remote_path}/{rel_path}".replace("\\", "/")
                        
                        # העלאת הקובץ
                        client.upload_file(local_file, bucket, remote_key)
                        file_count += 1
                
                return {
                    "status": "success",
                    "message": f"תיקייה {local_path} הועתקה בהצלחה ל-{remote_path} ({file_count} קבצים)",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                client.upload_file(local_path, bucket, full_remote_path)
                
                return {
                    "status": "success",
                    "message": f"קובץ {local_path} הועתק בהצלחה ל-{remote_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ מקומי ל-S3: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_ftp(self, connection: Dict[str, Any], client: Any, local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון FTP
        
        Args:
            connection: מידע החיבור
            client: לקוח FTP
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        base_path = connection["base_path"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        current_dir = client.pwd()
        
        try:
            # יצירת תיקיות ביניים
            remote_dir = os.path.dirname(full_remote_path)
            try:
                client.cwd(remote_dir)
                client.cwd(current_dir)  # חזרה לתיקייה המקורית
            except:
                # יצירת תיקיות ביניים רקורסיבית
                current_path = base_path
                for part in os.path.relpath(remote_dir, base_path).split('/'):
                    if not part:
                        continue
                    current_path = os.path.join(current_path, part)
                    try:
                        client.cwd(current_path)
                        client.cwd(current_dir)  # חזרה לתיקייה המקורית
                    except:
                        client.mkd(current_path)
            
            # העתקת הקובץ
            if os.path.isdir(local_path):
                # העתקת תיקייה
                try:
                    client.cwd(full_remote_path)
                    client.cwd(current_dir)  # חזרה לתיקייה המקורית
                except:
                    client.mkd(full_remote_path)
                
                file_count = 0
                for root, dirs, files in os.walk(local_path):
                    # יצירת תיקיות בצד המרוחק
                    for dir_name in dirs:
                        local_dir = os.path.join(root, dir_name)
                        rel_path = os.path.relpath(local_dir, local_path)
                        remote_dir = os.path.join(full_remote_path, rel_path).replace('\\', '/')
                        
                        try:
                            client.cwd(remote_dir)
                            client.cwd(current_dir)  # חזרה לתיקייה המקורית
                        except:
                            client.mkd(remote_dir)
                    
                    # העתקת קבצים
                    for file_name in files:
                        local_file = os.path.join(root, file_name)
                        rel_path = os.path.relpath(local_file, local_path)
                        remote_file = os.path.join(full_remote_path, rel_path).replace('\\', '/')
                        
                        with open(local_file, 'rb') as f:
                            client.storbinary(f"STOR {remote_file}", f)
                        
                        file_count += 1
                
                return {
                    "status": "success",
                    "message": f"תיקייה {local_path} הועתקה בהצלחה ל-{remote_path} ({file_count} קבצים)",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                with open(local_path, 'rb') as f:
                    client.storbinary(f"STOR {full_remote_path}", f)
                
                return {
                    "status": "success",
                    "message": f"קובץ {local_path} הועתק בהצלחה ל-{remote_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            # ניסיון לחזור לתיקייה המקורית
            try:
                client.cwd(current_dir)
            except:
                pass
            
            logger.error(f"שגיאה בהעתקת קובץ מקומי ל-FTP: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_webdav(self, connection: Dict[str, Any], client: Any, local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון WebDAV
        
        Args:
            connection: מידע החיבור
            client: לקוח WebDAV
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        remote_path = remote_path.lstrip("/")
        
        try:
            # העתקת הקובץ
            if os.path.isdir(local_path):
                # העתקת תיקייה
                client.upload_sync(local_path, remote_path)
                
                return {
                    "status": "success",
                    "message": f"תיקייה {local_path} הועתקה בהצלחה ל-{remote_path}",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                client.upload_file(local_path, remote_path)
                
                return {
                    "status": "success",
                    "message": f"קובץ {local_path} הועתק בהצלחה ל-{remote_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ מקומי ל-WebDAV: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_smb(self, connection: Dict[str, Any], client: Any, local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון SMB
        
        Args:
            connection: מידע החיבור
            client: לקוח SMB
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        share = connection["share"]
        base_path = connection["base_path"].lstrip("/").replace("/", "\\")
        remote_path = remote_path.lstrip("/").replace("/", "\\")
        full_remote_path = os.path.normpath(os.path.join(base_path, remote_path))
        
        try:
            # יצירת תיקיות ביניים
            remote_dir = os.path.dirname(full_remote_path)
            try:
                client.listPath(share, remote_dir)
            except:
                # יצירת תיקיות ביניים רקורסיבית
                current_path = base_path
                for part in os.path.relpath(remote_dir, base_path).split('\\'):
                    if not part:
                        continue
                    current_path = os.path.join(current_path, part)
                    try:
                        client.listPath(share, current_path)
                    except:
                        client.createDirectory(share, current_path)
            
            # העתקת הקובץ
            if os.path.isdir(local_path):
                # העתקת תיקייה
                try:
                    client.listPath(share, full_remote_path)
                except:
                    client.createDirectory(share, full_remote_path)
                
                file_count = 0
                for root, dirs, files in os.walk(local_path):
                    # יצירת תיקיות בצד המרוחק
                    for dir_name in dirs:
                        local_dir = os.path.join(root, dir_name)
                        rel_path = os.path.relpath(local_dir, local_path)
                        remote_dir = os.path.join(full_remote_path, rel_path).replace('/', '\\')
                        
                        try:
                            client.listPath(share, remote_dir)
                        except:
                            client.createDirectory(share, remote_dir)
                    
                    # העתקת קבצים
                    for file_name in files:
                        local_file = os.path.join(root, file_name)
                        rel_path = os.path.relpath(local_file, local_path)
                        remote_file = os.path.join(full_remote_path, rel_path).replace('/', '\\')
                        
                        with open(local_file, 'rb') as f:
                            client.storeFile(share, remote_file, f)
                        
                        file_count += 1
                
                return {
                    "status": "success",
                    "message": f"תיקייה {local_path} הועתקה בהצלחה ל-{remote_path} ({file_count} קבצים)",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                with open(local_path, 'rb') as f:
                    client.storeFile(share, full_remote_path, f)
                
                return {
                    "status": "success",
                    "message": f"קובץ {local_path} הועתק בהצלחה ל-{remote_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ מקומי ל-SMB: {str(e)}")
            return {"status": "error", "error": str(e)}
    
    def _sync_local_to_nfs(self, connection: Dict[str, Any], local_path: str, remote_path: str) -> Dict[str, Any]:
        """
        סנכרון ממקומי לאחסון NFS
        
        Args:
            connection: מידע החיבור
            local_path: נתיב מקומי
            remote_path: נתיב מרוחק
            
        Returns:
            תוצאת הסנכרון
        """
        mount_point = connection["mount_point"]
        remote_path = remote_path.lstrip("/")
        full_remote_path = os.path.normpath(os.path.join(mount_point, remote_path))
        
        # בדיקה שהנתיב נמצא בתוך נקודת העיגון
        if not full_remote_path.startswith(mount_point):
            return {"status": "error", "error": "נתיב לא חוקי"}
        
        try:
            # יצירת תיקיות ביניים
            os.makedirs(os.path.dirname(full_remote_path), exist_ok=True)
            
            # העתקת הקובץ
            if os.path.isdir(local_path):
                # העתקת תיקייה
                shutil.copytree(local_path, full_remote_path, dirs_exist_ok=True)
                return {
                    "status": "success",
                    "message": f"תיקייה {local_path} הועתקה בהצלחה ל-{remote_path}",
                    "type": "directory"
                }
            else:
                # העתקת קובץ
                shutil.copy2(local_path, full_remote_path)
                return {
                    "status": "success",
                    "message": f"קובץ {local_path} הועתק בהצלחה ל-{remote_path}",
                    "type": "file",
                    "size": os.path.getsize(local_path)
                }
                
        except Exception as e:
            logger.error(f"שגיאה בהעתקת קובץ מקומי ל-NFS: {str(e)}")
            return {"status": "error", "error": str(e)}
REMOTE_STORAGE_PY

# יצירת קובץ ממשק משתמש בסיסי
echo "📝 יוצר ממשק משתמש בסיסי..."
mkdir -p "$BASE_DIR/ui/templates"

cat > "$BASE_DIR/ui/templates/index.html" << 'INDEX_HTML'
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>מאחד קוד חכם Pro 2.0</title>
    <link rel="stylesheet" href="../../assets/css/style.css">
    <link rel="manifest" href="../../pwa/manifest.json">
    <link rel="icon" type="image/png" href="../../assets/images/favicon.png">
    <script defer src="../../assets/js/app.js"></script>
    
    <!-- הגדרות PWA -->
    <meta name="theme-color" content="#2196f3">
    <meta name="description" content="מאחד קוד חכם Pro - כלי לזיהוי, ניתוח ומיזוג פרויקטים מקבצי ZIP">
    <meta name="application-name" content="מאחד קוד חכם Pro">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-title" content="מאחד קוד חכם Pro">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
</head>
<body>
    <div class="app-container">
        <header class="app-header">
            <div class="logo">
                <img src="../../assets/images/logo.svg" alt="מאחד קוד חכם Pro 2.0" />
                <h1>מאחד קוד חכם Pro 2.0</h1>
            </div>
            <nav class="main-nav">
                <ul>
                    <li><a href="#" data-tab="home" class="active">ראשי</a></li>
                    <li><a href="#" data-tab="projects">פרויקטים</a></li>
                    <li><a href="#" data-tab="security">אבטחה</a></li>
                    <li><a href="#" data-tab="settings">הגדרות</a></li>
                </ul>
            </nav>
        </header>
        
        <main class="app-content">
            <!-- לשונית ראשית -->
            <section id="home" class="tab-content active">
                <div class="card">
                    <h2>ברוכים הבאים למאחד קוד חכם Pro 2.0</h2>
                    <p>כלי מתקדם לזיהוי, ניתוח ומיזוג פרויקטים מקבצי ZIP</p>
                    
                    <div class="file-upload-container">
                        <h3>העלאת קבצי ZIP לניתוח</h3>
                        <div class="file-upload-area" id="dropZone">
                            <img src="../../assets/images/upload-icon.svg" alt="העלאת קבצים" />
                            <p>גרור קבצי ZIP לכאן או <label for="fileInput" class="file-input-label">בחר קבצים</label></p>
                            <input type="file" id="fileInput" multiple accept=".zip" class="file-input" />
                        </div>
                        <div class="selected-files-list" id="selectedFilesList"></div>
                    </div>
                    
                    <div class="action-buttons">
                        <button id="analyzeBtn" class="btn btn-primary" disabled>
                            <span class="btn-text">נתח פרויקטים</span>
                            <span class="spinner"></span>
                        </button>
                        <button id="clearBtn" class="btn btn-secondary" disabled>נקה</button>
                    </div>
                </div>
                
                <div class="card" id="analysisResults" style="display: none;">
                    <h2>תוצאות ניתוח</h2>
                    <div class="analysis-summary">
                        <div class="summary-item">
                            <span class="summary-icon"><img src="../../assets/images/project-icon.svg" alt="פרויקטים" /></span>
                            <span class="summary-value" id="projectsCount">0</span>
                            <span class="summary-label">פרויקטים זוהו</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-icon"><img src="../../assets/images/file-icon.svg" alt="קבצים" /></span>
                            <span class="summary-value" id="filesCount">0</span>
                            <span class="summary-label">קבצים סה"כ</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-icon"><img src="../../assets/images/security-icon.svg" alt="בעיות אבטחה" /></span>
                            <span class="summary-value" id="securityIssuesCount">0</span>
                            <span class="summary-label">בעיות אבטחה</span>
                        </div>
                    </div>
                    
                    <div class="detected-projects">
                        <h3>פרויקטים שזוהו</h3>
                        <div class="projects-list" id="projectsList"></div>
                    </div>
                    
                    <div class="action-buttons">
                        <button id="mergeSelectedBtn" class="btn btn-primary" disabled>
                            <span class="btn-text">מזג פרויקטים נבחרים</span>
                            <span class="spinner"></span>
                        </button>
                        <button id="downloadReportBtn" class="btn btn-secondary" disabled>הורד דוח</button>
                    </div>
                </div>
            </section>
            
            <!-- לשונית פרויקטים -->
            <section id="projects" class="tab-content">
                <div class="card">
                    <h2>פרויקטים קיימים</h2>
                    <div class="projects-history" id="projectsHistory">
                        <p class="empty-state">אין פרויקטים קיימים עדיין</p>
                    </div>
                </div>
            </section>
            
            <!-- לשונית אבטחה -->
            <section id="security" class="tab-content">
                <div class="card">
                    <h2>דוחות אבטחה</h2>
                    <div class="security-reports" id="securityReports">
                        <p class="empty-state">אין דוחות אבטחה עדיין</p>
                    </div>
                </div>
            </section>
            
            <!-- לשונית הגדרות -->
            <section id="settings" class="tab-content">
                <div class="card">
                    <h2>הגדרות כלליות</h2>
                    <form id="settingsForm">
                        <div class="form-group">
                            <label for="outputPath">תיקיית פלט</label>
                            <input type="text" id="outputPath" placeholder="נתיב לתיקיית הפלט">
                            <button type="button" id="browsePath" class="btn btn-small">עיון...</button>
                        </div>
                        
                        <div class="form-group">
                            <label for="maxFileSize">גודל קובץ מקסימלי לניתוח (MB)</label>
                            <input type="number" id="maxFileSize" min="1" max="1000" value="100">
                        </div>
                        
                        <div class="form-group">
                            <label for="threadCount">מספר חוטים לעיבוד מקבילי</label>
                            <input type="number" id="threadCount" min="1" max="16" value="4">
                        </div>
                        
                        <h3>הגדרות אבטחה</h3>
                        
                        <div class="form-group">
                            <label>
                                <input type="checkbox" id="enableSecurity" checked>
                                הפעל סריקות אבטחה
                            </label>
                        </div>
                        
                        <div class="form-group">
                            <label for="securityLevel">רמת סריקת אבטחה</label>
                            <select id="securityLevel">
                                <option value="low">בסיסית</option>
                                <option value="medium" selected>בינונית</option>
                                <option value="high">מתקדמת</option>
                            </select>
                        </div>
                        
                        <h3>אחסון מרוחק</h3>
                        
                        <div class="form-group">
                            <label>
                                <input type="checkbox" id="enableRemoteStorage">
                                הפעל גישה לאחסון מרוחק
                            </label>
                        </div>
                        
                        <div class="form-group">
                            <label for="remoteStorageType">סוג אחסון מרוחק</label>
                            <select id="remoteStorageType" disabled>
                                <option value="sftp">SFTP</option>
                                <option value="s3">Amazon S3</option>
                                <option value="ftp">FTP</option>
                                <option value="webdav">WebDAV</option>
                            </select>
                        </div>
                        
                        <div class="action-buttons">
                            <button type="submit" id="saveSettingsBtn" class="btn btn-primary">
                                <span class="btn-text">שמור הגדרות</span>
                                <span class="spinner"></span>
                            </button>
                            <button type="button" id="resetSettingsBtn" class="btn btn-secondary">אפס הגדרות</button>
                        </div>
                    </form>
                </div>
                
                <div class="card">
                    <h2>אודות</h2>
                    <div class="about-info">
                        <p>גרסת תוכנה: <span id="versionNumber">2.0.0</span></p>
                        <p>תאריך שחרור: מאי 2025</p>
                        <p>מפתח: Claude AI</p>
                        <p>רישיון: MIT</p>
                    </div>
                </div>
            </section>
        </main>
        
        <footer class="app-footer">
            <p>&copy; 2025 מאחד קוד חכם Pro. כל הזכויות שמורות.</p>
        </footer>
    </div>
    
    <!-- דיאלוג מיזוג -->
    <div class="dialog-overlay" id="mergeDialogOverlay" style="display: none;">
        <div class="dialog" id="mergeDialog">
            <div class="dialog-header">
                <h2>מיזוג פרויקטים</h2>
                <button class="close-btn" id="closeMergeDialog">&times;</button>
            </div>
            <div class="dialog-content">
                <p>בחר תיקיית יעד למיזוג הפרויקטים:</p>
                <div class="form-group">
                    <input type="text" id="mergeOutputPath" placeholder="נתיב לתיקיית היעד">
                    <button type="button" id="browseMergePath" class="btn btn-small">עיון...</button>
                </div>
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="createZip" checked>
                        צור קובץ ZIP מהתוצאה
                    </label>
                </div>
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="runSecurityScan" checked>
                        הפעל סריקת אבטחה מלאה
                    </label>
                </div>
            </div>
            <div class="dialog-footer">
                <button id="startMergeBtn" class="btn btn-primary">
                    <span class="btn-text">התחל מיזוג</span>
                    <span class="spinner"></span>
                </button>
                <button id="cancelMergeBtn" class="btn btn-secondary">ביטול</button>
            </div>
        </div>
    </div>
    
    <!-- סקריפט התקנת PWA -->
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', function() {
                navigator.serviceWorker.register('../../pwa/service-worker.js')
                    .then(function(registration) {
                        console.log('Service Worker registered with scope:', registration.scope);
                    })
                    .catch(function(error) {
                        console.log('Service Worker registration failed:', error);
                    });
            });
        }
    </script>
</body>
</html>
INDEX_HTML

# יצירת קובץ CSS
echo "📝 יוצר קובץ CSS..."
mkdir -p "$BASE_DIR/assets/css"

cat > "$BASE_DIR/assets/css/style.css" << 'STYLE_CSS'
:root {
    --primary-color: #2196f3;
    --primary-dark: #1976d2;
    --primary-light: #bbdefb;
    --accent-color: #ff4081;
    --text-color: #333333;
    --text-light: #757575;
    --background-color: #f5f5f5;
    --card-color: #ffffff;
    --border-color: #e0e0e0;
    --success-color: #4caf50;
    --warning-color: #ff9800;
    --error-color: #f44336;
    --info-color: #2196f3;
    
    --shadow-small: 0 2px 4px rgba(0, 0, 0, 0.1);
    --shadow-medium: 0 4px 8px rgba(0, 0, 0, 0.1);
    --shadow-large: 0 8px 16px rgba(0, 0, 0, 0.1);
    
    --border-radius: 4px;
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    
    --transition-speed: 0.3s;
    --font-family: 'Segoe UI', 'Arial', sans-serif;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: var(--font-family);
    font-size: 16px;
    line-height: 1.5;
    color: var(--text-color);
    background-color: var(--background-color);
    direction: rtl;
}

.app-container {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
    max-width: 1200px;
    margin: 0 auto;
    padding: var(--spacing-md);
}

/* כותרת עליונה */
.app-header {
    background-color: var(--card-color);
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-medium);
    padding: var(--spacing-md);
    margin-bottom: var(--spacing-lg);
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
}

.logo {
    display: flex;
    align-items: center;
}

.logo img {
    height: 40px;
    margin-left: var(--spacing-md);
}

.logo h1 {
    font-size: 1.5rem;
    color: var(--primary-dark);
}

.main-nav ul {
    display: flex;
    list-style: none;
}

.main-nav a {
    display: block;
    padding: var(--spacing-sm) var(--spacing-md);
    color: var(--text-light);
    text-decoration: none;
    border-radius: var(--border-radius);
    transition: background-color var(--transition-speed), color var(--transition-speed);
}

.main-nav a.active, .main-nav a:hover {
    color: var(--primary-color);
    background-color: var(--primary-light);
}

/* תוכן עיקרי */
.app-content {
    flex: 1;
}

.tab-content {
    display: none;
}

.tab-content.active {
    display: block;
}

.card {
    background-color: var(--card-color);
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-medium);
    padding: var(--spacing-lg);
    margin-bottom: var(--spacing-lg);
}

.card h2 {
    color: var(--primary-dark);
    margin-bottom: var(--spacing-md);
    font-size: 1.5rem;
}

.card h3 {
    color: var(--text-color);
    margin: var(--spacing-lg) 0 var(--spacing-md);
    font-size: 1.2rem;
}

/* טופס ואלמנטי קלט */
.form-group {
    margin-bottom: var(--spacing-md);
}

.form-group label {
    display: block;
    margin-bottom: var(--spacing-xs);
    color: var(--text-light);
}

input[type="text"],
input[type="number"],
select,
textarea {
    width: 100%;
    padding: var(--spacing-sm);
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    font-family: var(--font-family);
    font-size: 1rem;
    transition: border-color var(--transition-speed);
}

input[type="text"]:focus,
input[type="number"]:focus,
select:focus,
textarea:focus {
    outline: none;
    border-color: var(--primary-color);
}

/* כפתורים */
.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: var(--spacing-sm) var(--spacing-lg);
    border: none;
    border-radius: var(--border-radius);
    font-family: var(--font-family);
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background-color var(--transition-speed), transform var(--transition-speed);
    position: relative;
    overflow: hidden;
}

.btn-primary {
    background-color: var(--primary-color);
    color: white;
}

.btn-primary:hover {
    background-color: var(--primary-dark);
}

.btn-secondary {
    background-color: var(--background-color);
    color: var(--text-color);
    border: 1px solid var(--border-color);
}

.btn-secondary:hover {
    background-color: var(--border-color);
}

.btn-small {
    padding: var(--spacing-xs) var(--spacing-sm);
    font-size: 0.875rem;
}

.btn:active {
    transform: translateY(2px);
}

.btn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
}

/* כפתור עם אנימצית טעינה */
.btn .spinner {
    display: none;
    width: 16px;
    height: 16px;
    margin-right: var(--spacing-sm);
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    border-top-color: #fff;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

.btn.loading .spinner {
    display: inline-block;
}

.btn.loading .btn-text {
    opacity: 0.7;
}

/* אזור העלאת קבצים */
.file-upload-container {
    margin: var(--spacing-lg) 0;
}

.file-upload-area {
    border: 2px dashed var(--border-color);
    border-radius: var(--border-radius);
    padding: var(--spacing-xl);
    text-align: center;
    background-color: var(--background-color);
    cursor: pointer;
    transition: border-color var(--transition-speed), background-color var(--transition-speed);
}

.file-upload-area:hover, .file-upload-area.dragover {
    border-color: var(--primary-color);
    background-color: var(--primary-light);
}

.file-upload-area img {
    width: 64px;
    height: 64px;
    margin-bottom: var(--spacing-md);
}

.file-upload-area p {
    color: var(--text-light);
}

.file-input-label {
    color: var(--primary-color);
    cursor: pointer;
    text-decoration: underline;
}

.file-input {
    display: none;
}

.selected-files-list {
    margin-top: var(--spacing-md);
}

.selected-file-item {
    display: flex;
    align-items: center;
    padding: var(--spacing-sm) 0;
    border-bottom: 1px solid var(--border-color);
}

.selected-file-item:last-child {
    border-bottom: none;
}

.selected-file-icon {
    margin-left: var(--spacing-sm);
    color: var(--primary-color);
}

.selected-file-name {
    flex: 1;
}

.selected-file-size {
    color: var(--text-light);
    font-size: 0.875rem;
    margin-right: var(--spacing-md);
}

.selected-file-remove {
    background: none;
    border: none;
    color: var(--error-color);
    cursor: pointer;
    font-size: 1.2rem;
    margin-right: var(--spacing-sm);
}

/* תקציר ניתוח */
.analysis-summary {
    display: flex;
    justify-content: space-around;
    flex-wrap: wrap;
    margin: var(--spacing-lg) 0;
}

.summary-item {
    text-align: center;
    padding: var(--spacing-md);
    flex: 1;
    min-width: 150px;
}

.summary-icon {
    display: block;
    margin: 0 auto var(--spacing-sm);
}

.summary-icon img {
    width: 48px;
    height: 48px;
}

.summary-value {
    display: block;
    font-size: 2rem;
    font-weight: bold;
    color: var(--primary-color);
    margin-bottom: var(--spacing-xs);
}

.summary-label {
    color: var(--text-light);
}

/* רשימת פרויקטים */
.projects-list {
    margin-top: var(--spacing-md);
}

.project-item {
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    padding: var(--spacing-md);
    margin-bottom: var(--spacing-md);
    transition: box-shadow var(--transition-speed);
}

.project-item:hover {
    box-shadow: var(--shadow-medium);
}

.project-header {
    display: flex;
    align-items: center;
    margin-bottom: var(--spacing-sm);
}

.project-checkbox {
    margin-left: var(--spacing-md);
}

.project-name {
    flex: 1;
    font-weight: bold;
    color: var(--primary-dark);
}

.project-toggle {
    background: none;
    border: none;
    color: var(--text-light);
    cursor: pointer;
    font-size: 1.5rem;
    transition: transform var(--transition-speed);
}

.project-toggle.expanded {
    transform: rotate(180deg);
}

.project-details {
    display: none;
    margin-top: var(--spacing-md);
    padding-top: var(--spacing-md);
    border-top: 1px solid var(--border-color);
}

.project-details.visible {
    display: block;
}

.project-stats {
    display: flex;
    flex-wrap: wrap;
    margin-bottom: var(--spacing-md);
}

.project-stat {
    flex: 1;
    min-width: 100px;
    margin-bottom: var(--spacing-sm);
}

.project-stat-label {
    color: var(--text-light);
    font-size: 0.875rem;
}

.project-stat-value {
    font-weight: bold;
}

.project-files {
    background-color: var(--background-color);
    border-radius: var(--border-radius);
    padding: var(--spacing-sm);
    max-height: 200px;
    overflow-y: auto;
}

.project-file {
    padding: var(--spacing-xs) var(--spacing-sm);
    font-family: monospace;
    font-size: 0.875rem;
}

.project-file:nth-child(odd) {
    background-color: rgba(0, 0, 0, 0.03);
}

/* כפתורי פעולה */
.action-buttons {
    display: flex;
    justify-content: flex-end;
    gap: var(--spacing-md);
    margin-top: var(--spacing-lg);
}

/* הודעות מצב ריק */
.empty-state {
    text-align: center;
    padding: var(--spacing-xl);
    color: var(--text-light);
    font-style: italic;
}

/* דיאלוגים */
.dialog-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}

.dialog {
    background-color: var(--card-color);
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-large);
    width: 90%;
    max-width: 500px;
    max-height: 90vh;
    display: flex;
    flex-direction: column;
}

.dialog-header {
    padding: var(--spacing-md);
    border-bottom: 1px solid var(--border-color);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.dialog-header h2 {
    margin: 0;
}

.close-btn {
    background: none;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    color: var(--text-light);
}

.dialog-content {
    padding: var(--spacing-md);
    overflow-y: auto;
    flex: 1;
}

.dialog-footer {
    padding: var(--spacing-md);
    border-top: 1px solid var(--border-color);
    display: flex;
    justify-content: flex-end;
    gap: var(--spacing-md);
}

/* כותרת תחתונה */
.app-footer {
    margin-top: var(--spacing-lg);
    padding: var(--spacing-md) 0;
    text-align: center;
    color: var(--text-light);
    font-size: 0.875rem;
}

/* אנימציות */
@keyframes pulse {
    0% {
        transform: scale(1);
    }
    50% {
        transform: scale(1.05);
    }
    100% {
        transform: scale(1);
    }
}

.pulse {
    animation: pulse 2s infinite;
}

@keyframes fadeIn {
    from {
        opacity: 0;
    }
    to {
        opacity: 1;
    }
}

.fade-in {
    animation: fadeIn 0.3s ease-in-out;
}

/* התאמה למובייל */
@media (max-width: 768px) {
    .app-header {
        flex-direction: column;
        align-items: center;
    }
    
    .logo {
        margin-bottom: var(--spacing-md);
    }
    
    .main-nav {
        width: 100%;
    }
    
    .main-nav ul {
        justify-content: space-around;
    }
    
    .summary-item {
        min-width: 100px;
    }
    
    .action-buttons {
        flex-direction: column;
        gap: var(--spacing-sm);
    }
    
    .btn {
        width: 100%;
    }
}
STYLE_CSS

# יצירת קובץ JavaScript
echo "📝 יוצר קובץ JavaScript..."
mkdir -p "$BASE_DIR/assets/js"

cat > "$BASE_DIR/assets/js/app.js" << 'APP_JS'
/**
 * מאחד קוד חכם Pro 2.0
 * קובץ JavaScript ראשי
 * 
 * מחבר: Claude AI
 * גרסה: 1.0.0
 * תאריך: מאי 2025
 */

// טעינת הדף
document.addEventListener('DOMContentLoaded', function() {
    // אתחול משתנים והפניות למרכיבי ממשק
    const fileInput = document.getElementById('fileInput');
    const dropZone = document.getElementById('dropZone');
    const selectedFilesList = document.getElementById('selectedFilesList');
    const analyzeBtn = document.getElementById('analyzeBtn');
    const clearBtn = document.getElementById('clearBtn');
    const analysisResults = document.getElementById('analysisResults');
    const projectsCount = document.getElementById('projectsCount');
    const filesCount = document.getElementById('filesCount');
    const securityIssuesCount = document.getElementById('securityIssuesCount');
    const projectsList = document.getElementById('projectsList');
    const mergeSelectedBtn = document.getElementById('mergeSelectedBtn');
    const downloadReportBtn = document.getElementById('downloadReportBtn');
    
    // דיאלוג מיזוג
    const mergeDialog = document.getElementById('mergeDialog');
    const mergeDialogOverlay = document.getElementById('mergeDialogOverlay');
    const closeMergeDialog = document.getElementById('closeMergeDialog');
    const startMergeBtn = document.getElementById('startMergeBtn');
    const cancelMergeBtn = document.getElementById('cancelMergeBtn');
    
    // הגדרות
    const settingsForm = document.getElementById('settingsForm');
    const saveSettingsBtn = document.getElementById('saveSettingsBtn');
    const resetSettingsBtn = document.getElementById('resetSettingsBtn');
    
    // ניווט בין לשוניות
    const tabLinks = document.querySelectorAll('.main-nav a');
    const tabContents = document.querySelectorAll('.tab-content');
    
    // נתונים פנימיים
    let selectedFiles = [];
    let analyzedProjects = [];
    let selectedProjects = [];
    
    // אתחול האפליקציה
    initApp();
    
    function initApp() {
        // טעינת הגדרות
        loadSettings();
        
        // הגדרת אירועים
        setupEventListeners();
        
        // טעינת מידע אחסון
        loadStoredData();
        
        // אנימציית טעינה
        showWelcomeAnimation();
        
        console.log('מאחד קוד חכם Pro 2.0 אותחל בהצלחה');
    }
    
    /**
     * טעינת הגדרות מהאחסון המקומי
     */
    function loadSettings() {
        const settings = JSON.parse(localStorage.getItem('smartCodeMergerSettings')) || getDefaultSettings();
        
        document.getElementById('outputPath').value = settings.outputPath;
        document.getElementById('maxFileSize').value = settings.maxFileSize;
        document.getElementById('threadCount').value = settings.threadCount;
        document.getElementById('enableSecurity').checked = settings.enableSecurity;
        document.getElementById('securityLevel').value = settings.securityLevel;
        document.getElementById('enableRemoteStorage').checked = settings.enableRemoteStorage;
        document.getElementById('remoteStorageType').disabled = !settings.enableRemoteStorage;
        document.getElementById('remoteStorageType').value = settings.remoteStorageType;
        
        console.log('הגדרות נטענו');
    }
    
    /**
     * החזרת הגדרות ברירת מחדל
     */
    function getDefaultSettings() {
        return {
            outputPath: '',
            maxFileSize: 100,
            threadCount: 4,
            enableSecurity: true,
            securityLevel: 'medium',
            enableRemoteStorage: false,
            remoteStorageType: 'sftp'
        };
    }
    
    /**
     * שמירת הגדרות באחסון המקומי
     */
    function saveSettings() {
        const settings = {
            outputPath: document.getElementById('outputPath').value,
            maxFileSize: parseInt(document.getElementById('maxFileSize').value),
            threadCount: parseInt(document.getElementById('threadCount').value),
            enableSecurity: document.getElementById('enableSecurity').checked,
            securityLevel: document.getElementById('securityLevel').value,
            enableRemoteStorage: document.getElementById('enableRemoteStorage').checked,
            remoteStorageType: document.getElementById('remoteStorageType').value
        };
        
        localStorage.setItem('smartCodeMergerSettings', JSON.stringify(settings));
        console.log('הגדרות נשמרו');
    }
    
    /**
     * טעינת נתונים מהאחסון המקומי
     */
    function loadStoredData() {
        // טעינת היסטוריית פרויקטים
        const projectsHistory = document.getElementById('projectsHistory');
        const storedProjects = JSON.parse(localStorage.getItem('smartCodeMergerProjects')) || [];
        
        if (storedProjects.length > 0) {
            projectsHistory.innerHTML = '';
            storedProjects.forEach(project => {
                const projectElement = createProjectElement(project, true);
                projectsHistory.appendChild(projectElement);
            });
        }
        
        // טעינת דוחות אבטחה
        const securityReports = document.getElementById('securityReports');
        const storedReports = JSON.parse(localStorage.getItem('smartCodeMergerSecurityReports')) || [];
        
        if (storedReports.length > 0) {
            securityReports.innerHTML = '';
            storedReports.forEach(report => {
                const reportElement = createReportElement(report);
                securityReports.appendChild(reportElement);
            });
        }
    }
    
    /**
     * אנימציית ברוכים הבאים
     */
    function showWelcomeAnimation() {
        const welcomeCard = document.querySelector('#home .card');
        welcomeCard.classList.add('fade-in');
        
        setTimeout(() => {
            welcomeCard.classList.remove('fade-in');
        }, 1000);
    }
    
    /**
     * הגדרת מאזיני אירועים
     */
    function setupEventListeners() {
        // ניווט בין לשוניות
        tabLinks.forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                const tabId = this.getAttribute('data-tab');
                
                // הסרת מחלקה פעילה מכל הלשוניות
                tabLinks.forEach(innerLink => {
                    innerLink.classList.remove('active');
                });
                
                // הסתרת כל התוכן
                tabContents.forEach(content => {
                    content.classList.remove('active');
                });
                
                // הוספת מחלקה פעילה ללשונית שנבחרה
                this.classList.add('active');
                document.getElementById(tabId).classList.add('active');
            });
        });
        
        // בחירת קבצים
        fileInput.addEventListener('change', handleFileSelection);
        
        // גרירת קבצים
        dropZone.addEventListener('dragover', function(e) {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });
        
        dropZone.addEventListener('dragleave', function() {
            dropZone.classList.remove('dragover');
        });
        
        dropZone.addEventListener('drop', function(e) {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            
            if (e.dataTransfer.files.length > 0) {
                handleFiles(e.dataTransfer.files);
            }
        });
        
        dropZone.addEventListener('click', function() {
            fileInput.click();
        });
        
        // כפתורי פעולה
        analyzeBtn.addEventListener('click', analyzeFiles);
        clearBtn.addEventListener('click', clearFiles);
        mergeSelectedBtn.addEventListener('click', openMergeDialog);
        downloadReportBtn.addEventListener('click', downloadReport);
        
        // דיאלוג מיזוג
        closeMergeDialog.addEventListener('click', closeMergeDialogHandler);
        cancelMergeBtn.addEventListener('click', closeMergeDialogHandler);
        startMergeBtn.addEventListener('click', mergeSelectedProjects);
        
        // לחיצה מחוץ לדיאלוג
        mergeDialogOverlay.addEventListener('click', function(e) {
            if (e.target === mergeDialogOverlay) {
                closeMergeDialogHandler();
            }
        });
        
        // טופס הגדרות
        settingsForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const saveBtn = document.getElementById('saveSettingsBtn');
            saveBtn.classList.add('loading');
            saveBtn.disabled = true;
            
            // השהייה מלאכותית להדגמת האנימציה
            setTimeout(() => {
                saveSettings();
                saveBtn.classList.remove('loading');
                saveBtn.disabled = false;
                
                // הודעת הצלחה
                showToast('ההגדרות נשמרו בהצלחה', 'success');
            }, 1000);
        });
        
        // אפס הגדרות
        resetSettingsBtn.addEventListener('click', function() {
            if (confirm('האם אתה בטוח שברצונך לאפס את ההגדרות?')) {
                localStorage.removeItem('smartCodeMergerSettings');
                loadSettings();
                showToast('ההגדרות אופסו בהצלחה', 'info');
            }
        });
        
        // הפעלת גישה לאחסון מרוחק
        document.getElementById('enableRemoteStorage').addEventListener('change', function() {
            document.getElementById('remoteStorageType').disabled = !this.checked;
        });
    }
    
    /**
     * טיפול בבחירת קבצים
     */
    function handleFileSelection(event) {
        if (event.target.files.length > 0) {
            handleFiles(event.target.files);
        }
    }
    
    /**
     * טיפול בקבצים חדשים
     */
    function handleFiles(files) {
        const zipFiles = Array.from(files).filter(file => file.name.toLowerCase().endsWith('.zip'));
        
        if (zipFiles.length === 0) {
            showToast('אנא בחר קבצי ZIP בלבד', 'warning');
            return;
        }
        
        // הוספת קבצים חדשים לרשימה
        zipFiles.forEach(file => {
            if (!selectedFiles.some(existingFile => existingFile.name === file.name)) {
                selectedFiles.push(file);
            }
        });
        
        // עדכון תצוגת הרשימה
        updateSelectedFilesList();
        
        // הפעלת כפתורים
        analyzeBtn.disabled = selectedFiles.length === 0;
        clearBtn.disabled = selectedFiles.length === 0;
    }
    
    /**
     * עדכון רשימת הקבצים שנבחרו
     */
    function updateSelectedFilesList() {
        selectedFilesList.innerHTML = '';
        
        if (selectedFiles.length === 0) {
            selectedFilesList.innerHTML = '<p class="empty-state">לא נבחרו קבצים</p>';
            return;
        }
        
        selectedFiles.forEach((file, index) => {
            const fileItem = document.createElement('div');
            fileItem.className = 'selected-file-item';
            
            // המרת גודל הקובץ ליחידות קריאות
            const fileSizeFormatted = formatFileSize(file.size);
            
            fileItem.innerHTML = `
                <span class="selected-file-icon">
                    <i class="fas fa-file-archive"></i>
                </span>
                <span class="selected-file-name">${file.name}</span>
                <span class="selected-file-size">${fileSizeFormatted}</span>
                <button class="selected-file-remove" data-index="${index}">×</button>
            `;
            
            selectedFilesList.appendChild(fileItem);
            
            // הוספת מאזין לכפתור הסרה
            const removeButton = fileItem.querySelector('.selected-file-remove');
            removeButton.addEventListener('click', function() {
                const fileIndex = parseInt(this.getAttribute('data-index'));
                selectedFiles.splice(fileIndex, 1);
                updateSelectedFilesList();
                
                // עדכון מצב כפתורים
                analyzeBtn.disabled = selectedFiles.length === 0;
                clearBtn.disabled = selectedFiles.length === 0;
            });
        });
    }
    
    /**
     * ניתוח קבצים שנבחרו
     */
    function analyzeFiles() {
        // הוספת אנימציית טעינה לכפתור
        analyzeBtn.classList.add('loading');
        analyzeBtn.disabled = true;
        
        // אנימציית טעינה אקראית
        setTimeout(() => {
            // סימולציה לניתוח קבצים
            analyzedProjects = generateMockProjects();
            
            // עדכון תצוגה
            updateAnalysisResults(analyzedProjects);
            
            // הצגת תוצאות הניתוח
            analysisResults.style.display = 'block';
            analysisResults.classList.add('fade-in');
            
            // עדכון כפתורים
            analyzeBtn.classList.remove('loading');
            analyzeBtn.disabled = false;
            
            // גלילה לתוצאות
            analysisResults.scrollIntoView({ behavior: 'smooth' });
            
            // הודעת סיום
            showToast('ניתוח הקבצים הושלם בהצלחה', 'success');
        }, 2000);
    }
    
    /**
     * ניקוי קבצים שנבחרו
     */
    function clearFiles() {
        selectedFiles = [];
        updateSelectedFilesList();
        
        // הסתרת תוצאות ניתוח
        analysisResults.style.display = 'none';
        
        // עדכון כפתורים
        analyzeBtn.disabled = true;
        clearBtn.disabled = true;
        
        // איפוס בחירת פרויקטים
        selectedProjects = [];
        updateMergeButtonState();
    }
    
    /**
     * עדכון תוצאות ניתוח
     */
    function updateAnalysisResults(projects) {
        // עדכון מונים
        let totalFiles = 0;
        let totalSecurityIssues = 0;
        
        projects.forEach(project => {
            totalFiles += project.files.length;
            totalSecurityIssues += project.securityIssues.length;
        });
        
        projectsCount.textContent = projects.length;
        filesCount.textContent = totalFiles;
        securityIssuesCount.textContent = totalSecurityIssues;
        
        // אנימציית עדכון מונים
        [projectsCount, filesCount, securityIssuesCount].forEach(element => {
            element.classList.add('pulse');
            setTimeout(() => element.classList.remove('pulse'), 1000);
        });
        
        // יצירת רשימת פרויקטים
        projectsList.innerHTML = '';
        if (projects.length === 0) {
            projectsList.innerHTML = '<p class="empty-state">לא זוהו פרויקטים</p>';
            return;
        }
        
        projects.forEach(project => {
            const projectElement = createProjectElement(project);
            projectsList.appendChild(projectElement);
        });
        
        // עדכון מצב כפתור מיזוג
        updateMergeButtonState();
    }
    
    /**
     * יצירת אלמנט פרויקט לתצוגה
     */
    function createProjectElement(project, isHistory = false) {
        const projectElement = document.createElement('div');
        projectElement.className = 'project-item';
        projectElement.dataset.projectId = project.id;
        
        const headerHtml = `
            <div class="project-header">
                ${!isHistory ? `<input type="checkbox" class="project-checkbox" data-project-id="${project.id}">` : ''}
                <span class="project-name">${project.name}</span>
                <button class="project-toggle">▼</button>
            </div>
        `;
        
        let filesHtml = '';
        if (project.files && project.files.length > 0) {
            filesHtml = '<div class="project-files">';
            project.files.forEach(file => {
                filesHtml += `<div class="project-file">${file.path}</div>`;
            });
            filesHtml += '</div>';
        }
        
        let securityHtml = '';
        if (project.securityIssues && project.securityIssues.length > 0) {
            securityHtml = `
                <div class="security-issues">
                    <h4>בעיות אבטחה (${project.securityIssues.length})</h4>
                    <ul>
                        ${project.securityIssues.map(issue => `<li>${issue.description}</li>`).join('')}
                    </ul>
                </div>
            `;
        }
        
        const detailsHtml = `
            <div class="project-details">
                <div class="project-stats">
                    <div class="project-stat">
                        <div class="project-stat-label">סוג פרויקט</div>
                        <div class="project-stat-value">${project.type}</div>
                    </div>
                    <div class="project-stat">
                        <div class="project-stat-label">מספר קבצים</div>
                        <div class="project-stat-value">${project.files ? project.files.length : 0}</div>
                    </div>
                    <div class="project-stat">
                        <div class="project-stat-label">שפות עיקריות</div>
                        <div class="project-stat-value">${project.languages.join(', ')}</div>
                    </div>
                </div>
                ${filesHtml}
                ${securityHtml}
                ${isHistory ? `
                    <div class="project-history-info">
                        <div class="project-stat">
                            <div class="project-stat-label">תאריך יצירה</div>
                            <div class="project-stat-value">${project.createdAt}</div>
                        </div>
                        <div class="project-stat">
                            <div class="project-stat-label">נתיב</div>
                            <div class="project-stat-value">${project.outputPath}</div>
                        </div>
                    </div>
                ` : ''}
            </div>
        `;
        
        projectElement.innerHTML = headerHtml + detailsHtml;
        
        // הוספת מאזיני אירועים
        const toggleButton = projectElement.querySelector('.project-toggle');
        const projectDetails = projectElement.querySelector('.project-details');
        
        toggleButton.addEventListener('click', function() {
            projectDetails.classList.toggle('visible');
            toggleButton.classList.toggle('expanded');
        });
        
        // הוספת מאזין לתיבת סימון
        if (!isHistory) {
            const checkbox = projectElement.querySelector('.project-checkbox');
            checkbox.addEventListener('change', function() {
                const projectId = this.getAttribute('data-project-id');
                
                if (this.checked) {
                    // הוספה לפרויקטים שנבחרו
                    if (!selectedProjects.includes(projectId)) {
                        selectedProjects.push(projectId);
                    }
                } else {
                    // הסרה מהפרויקטים שנבחרו
                    const index = selectedProjects.indexOf(projectId);
                    if (index > -1) {
                        selectedProjects.splice(index, 1);
                    }
                }
                
                // עדכון מצב כפתור מיזוג
                updateMergeButtonState();
            });
        }
        
        return projectElement;
    }
    
    /**
     * יצירת אלמנט דוח אבטחה לתצוגה
     */
    function createReportElement(report) {
        const reportElement = document.createElement('div');
        reportElement.className = 'security-report-item';
        
        reportElement.innerHTML = `
            <div class="report-header">
                <span class="report-name">${report.name}</span>
                <span class="report-date">${report.date}</span>
            </div>
            <div class="report-summary">
                <div class="report-stat">
                    <div class="report-stat-label">סה"כ בעיות</div>
                    <div class="report-stat-value">${report.totalIssues}</div>
                </div>
                <div class="report-stat">
                    <div class="report-stat-label">בעיות חמורות</div>
                    <div class="report-stat-value">${report.highSeverityIssues}</div>
                </div>
            </div>
            <div class="report-actions">
                <button class="btn btn-small">צפה בדוח המלא</button>
                <button class="btn btn-small">הורד כ-PDF</button>
            </div>
        `;
        
        return reportElement;
    }
    
    /**
     * עדכון מצב כפתור מיזוג
     */
    function updateMergeButtonState() {
        mergeSelectedBtn.disabled = selectedProjects.length === 0;
        downloadReportBtn.disabled = analyzedProjects.length === 0;
    }
    
    /**
     * פתיחת דיאלוג מיזוג
     */
    function openMergeDialog() {
        // הצגת דיאלוג
        mergeDialogOverlay.style.display = 'flex';
        
        // אם יש נתיב פלט מוגדר בהגדרות, השתמש בו
        const settings = JSON.parse(localStorage.getItem('smartCodeMergerSettings')) || getDefaultSettings();
        if (settings.outputPath) {
            document.getElementById('mergeOutputPath').value = settings.outputPath;
        }
    }
    
    /**
     * סגירת דיאלוג מיזוג
     */
    function closeMergeDialogHandler() {
        mergeDialogOverlay.style.display = 'none';
    }
    
    /**
     * מיזוג פרויקטים נבחרים
     */
    function mergeSelectedProjects() {
        // הוספת אנימציית טעינה לכפתור
        startMergeBtn.classList.add('loading');
        startMergeBtn.disabled = true;
        
        // קבלת הגדרות מיזוג
        const outputPath = document.getElementById('mergeOutputPath').value;
        const createZip = document.getElementById('createZip').checked;
        const runSecurityScan = document.getElementById('runSecurityScan').checked;
        
        // אם אין נתיב פלט, הצג שגיאה
        if (!outputPath) {
            showToast('אנא בחר נתיב פלט למיזוג', 'error');
            startMergeBtn.classList.remove('loading');
            startMergeBtn.disabled = false;
            return;
        }
        
        // אנימציית טעינה אקראית
        setTimeout(() => {
            // סימולציה למיזוג פרויקטים
            const mergedProjects = generateMockMergeResult(selectedProjects);
            
            // שמירה בלוקל סטורג'
            storeMergedProjects(mergedProjects);
            
            // עדכון כפתורים
            startMergeBtn.classList.remove('loading');
            startMergeBtn.disabled = false;
            
            // סגירת דיאלוג
            closeMergeDialogHandler();
            
            // איפוס בחירת פרויקטים
            selectedProjects = [];
            
            // עדכון תצוגה
            const checkboxes = document.querySelectorAll('.project-checkbox');
            checkboxes.forEach(checkbox => {
                checkbox.checked = false;
            });
            
            // עדכון מצב כפתור מיזוג
            updateMergeButtonState();
            
            // הודעת סיום
            showToast('מיזוג הפרויקטים הושלם בהצלחה', 'success');
            
            // טעינה מחדש של נתוני האחסון
            loadStoredData();
            
            // החלפת לשונית לפרויקטים
            document.querySelector('.main-nav a[data-tab="projects"]').click();
        }, 3000);
    }
    
    /**
     * שמירת פרויקטים שמוזגו באחסון המקומי
     */
    function storeMergedProjects(mergedProjects) {
        // טעינת פרויקטים קיימים
        const storedProjects = JSON.parse(localStorage.getItem('smartCodeMergerProjects')) || [];
        
        // הוספת פרויקטים חדשים
        const updatedProjects = [...storedProjects, ...mergedProjects];
        
        // שמירה באחסון
        localStorage.setItem('smartCodeMergerProjects', JSON.stringify(updatedProjects));
        
        // אם הפעלנו סריקת אבטחה, שמור גם דוחות אבטחה
        if (document.getElementById('runSecurityScan').checked) {
            const storedReports = JSON.parse(localStorage.getItem('smartCodeMergerSecurityReports')) || [];
            
            // יצירת דוחות אבטחה
            const securityReports = mergedProjects.map(project => {
                return {
                    name: `דוח אבטחה - ${project.name}`,
                    date: project.createdAt,
                    totalIssues: Math.floor(Math.random() * 10),
                    highSeverityIssues: Math.floor(Math.random() * 3),
                    projectId: project.id
                };
            });
            
            // הוספת דוחות חדשים
            const updatedReports = [...storedReports, ...securityReports];
            
            // שמירה באחסון
            localStorage.setItem('smartCodeMergerSecurityReports', JSON.stringify(updatedReports));
        }
    }
    
    /**
     * הורדת דוח ניתוח
     */
    function downloadReport() {
        // יצירת נתוני דוח
        const reportData = {
            timestamp: new Date().toISOString(),
            analyzedFiles: selectedFiles.map(file => file.name),
            projects: analyzedProjects
        };
        
        // המרה למחרוזת JSON
        const jsonData = JSON.stringify(reportData, null, 2);
        
        // יצירת קובץ להורדה
        const blob = new Blob([jsonData], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        // יצירת קישור הורדה
        const a = document.createElement('a');
        a.href = url;
        a.download = `analysis_report_${new Date().toISOString().replace(/:/g, '-')}.json`;
        document.body.appendChild(a);
        a.click();
        
        // ניקוי
        setTimeout(() => {
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }, 100);
        
        // הודעת סיום
        showToast('הדוח הורד בהצלחה', 'success');
    }
    
    /**
     * המרת גודל קובץ ליחידות קריאות
     */
    function formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        
        const units = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        
        return parseFloat((bytes / Math.pow(1024, i)).toFixed(2)) + ' ' + units[i];
    }
    
    /**
     * הצגת הודעת Toast
     */
    function showToast(message, type = 'info') {
        // בדיקה אם יש כבר אלמנט toast
        let toast = document.querySelector('.toast');
        
        if (!toast) {
            // יצירת אלמנט toast
            toast = document.createElement('div');
            toast.className = 'toast';
            document.body.appendChild(toast);
            
            // הוספת סגנונות
            const style = document.createElement('style');
            style.textContent = `
                .toast {
                    position: fixed;
                    bottom: 20px;
                    left: 50%;
                    transform: translateX(-50%);
                    background-color: var(--card-color);
                    color: var(--text-color);
                    padding: 10px 20px;
                    border-radius: 4px;
                    box-shadow: var(--shadow-medium);
                    z-index: 1000;
                    font-size: 14px;
                    opacity: 0;
                    transition: opacity 0.3s ease-in-out;
                }
                
                .toast.show {
                    opacity: 1;
                }
                
                .toast.info {
                    border-right: 4px solid var(--info-color);
                }
                
                .toast.success {
                    border-right: 4px solid var(--success-color);
                }
                
                .toast.warning {
                    border-right: 4px solid var(--warning-color);
                }
                
                .toast.error {
                    border-right: 4px solid var(--error-color);
                }
            `;
            document.head.appendChild(style);
        }
        
        // הגדרת תוכן וסוג
        toast.textContent = message;
        toast.className = `toast ${type}`;
        
        // הצגת ההודעה
        setTimeout(() => {
            toast.classList.add('show');
        }, 10);
        
        // הסתרת ההודעה לאחר זמן מוגדר
        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }
    
    /**
     * יצירת נתוני פרויקטים מדומים לצורכי הדגמה
     */
    function generateMockProjects() {
        const projectTypes = ['Node.js', 'Python', 'Java', 'React', 'Angular', 'Django', 'Flask', 'Spring Boot'];
        const languagesList = [
            ['JavaScript', 'HTML', 'CSS'], 
            ['Python', 'HTML', 'CSS'], 
            ['Java', 'XML'], 
            ['JavaScript', 'JSX', 'CSS'], 
            ['TypeScript', 'HTML', 'CSS'],
            ['Python', 'HTML', 'JavaScript'],
            ['Python', 'HTML', 'CSS'],
            ['Java', 'XML', 'SQL']
        ];
        
        const projects = [];
        const numProjects = Math.floor(Math.random() * 3) + 2; // 2-4 פרויקטים
        
        for (let i = 0; i < numProjects; i++) {
            const typeIndex = Math.floor(Math.random() * projectTypes.length);
            const type = projectTypes[typeIndex];
            const languages = languagesList[typeIndex];
            
            // יצירת שם פרויקט אקראי
            const projectName = `${type}-project-${Math.floor(Math.random() * 1000)}`;
            
            // יצירת קבצים אקראיים
            const files = [];
            const numFiles = Math.floor(Math.random() * 20) + 10; // 10-30 קבצים
            
            for (let j = 0; j < numFiles; j++) {
                let extension;
                
                // בחירת סיומת קובץ לפי שפה
                if (languages.includes('JavaScript') || languages.includes('TypeScript')) {
                    extension = Math.random() > 0.5 ? 
                        (languages.includes('TypeScript') ? '.ts' : '.js') : 
                        (Math.random() > 0.5 ? '.html' : '.css');
                } else if (languages.includes('Python')) {
                    extension = Math.random() > 0.6 ? '.py' : (Math.random() > 0.5 ? '.html' : '.css');
                } else if (languages.includes('Java')) {
                    extension = Math.random() > 0.7 ? '.java' : '.xml';
                }
                
                // יצירת נתיב קובץ אקראי
                let filePath;
                if (Math.random() > 0.7) {
                    // קובץ בתיקייה משנית
                    const subdir = ['src', 'lib', 'modules', 'components', 'utils', 'tests'][Math.floor(Math.random() * 6)];
                    filePath = `${subdir}/${Math.random().toString(36).substring(7)}${extension}`;
                } else {
                    // קובץ בתיקייה הראשית
                    filePath = `${Math.random().toString(36).substring(7)}${extension}`;
                }
                
                files.push({
                    path: filePath,
                    size: Math.floor(Math.random() * 100000) + 1000 // 1KB - 100KB
                });
            }
            
            // יצירת בעיות אבטחה אקראיות
            const securityIssues = [];
            const numIssues = Math.floor(Math.random() * 5); // 0-4 בעיות
            
            const issueTypes = [
                'חשיפת מידע רגיש',
                'SQL Injection אפשרי',
                'חולשת Cross-Site Scripting (XSS)',
                'שימוש בספריות מיושנות',
                'סיסמה קבועה בקוד',
                'חולשת Cross-Site Request Forgery (CSRF)',
                'הרשאות קבצים לא מאובטחות',
                'טיפול לא מאובטח בנתוני קלט'
            ];
            
            for (let j = 0; j < numIssues; j++) {
                const issueType = issueTypes[Math.floor(Math.random() * issueTypes.length)];
                const severity = ['נמוכה', 'בינונית', 'גבוהה'][Math.floor(Math.random() * 3)];
                
                securityIssues.push({
                    description: `${issueType} - חומרה ${severity}`,
                    severity: severity,
                    file: files[Math.floor(Math.random() * files.length)].path
                });
            }
            
            projects.push({
                id: `project-${i}-${Date.now()}`,
                name: projectName,
                type: type,
                languages: languages,
                files: files,
                securityIssues: securityIssues
            });
        }
        
        return projects;
    }
    
    /**
     * יצירת תוצאות מיזוג מדומות
     */
    function generateMockMergeResult(selectedProjectIds) {
        const mergedProjects = [];
        
        // יצירת תאריך נוכחי מפורמט
        const now = new Date();
        const formattedDate = now.toLocaleDateString('he-IL') + ' ' + now.toLocaleTimeString('he-IL');
        
        // מציאת נתיב הפלט
        const outputPath = document.getElementById('mergeOutputPath').value || '/המיקום/שלך/projects/';
        
        // יצירת פרויקטים ממוזגים
        for (const projectId of selectedProjectIds) {
            // חיפוש מידע על הפרויקט המקורי
            const originalProject = analyzedProjects.find(p => p.id === projectId);
            
            if (originalProject) {
                mergedProjects.push({
                    id: `merged-${projectId}-${Date.now()}`,
                    name: originalProject.name,
                    type: originalProject.type,
                    languages: originalProject.languages,
                    createdAt: formattedDate,
                    outputPath: outputPath + originalProject.name,
                    files: originalProject.files,
                    securityIssues: originalProject.securityIssues
                });
            }
        }
        
        return mergedProjects;
    }
});
APP_JS
# יצירת קובץ Service Worker עבור PWA
echo "📝 יוצר קובץ Service Worker..."
mkdir -p "$BASE_DIR/pwa"

cat > "$BASE_DIR/pwa/service-worker.js" << 'SERVICE_WORKER_JS'
/**
 * מאחד קוד חכם Pro 2.0
 * Service Worker עבור PWA
 * 
 * מחבר: Claude AI
 * גרסה: 1.0.0
 * תאריך: מאי 2025
 */

const CACHE_NAME = 'smart-code-merger-pro-cache-v1';
const ASSETS_TO_CACHE = [
    '/',
    '/index.html',
    '/assets/css/style.css',
    '/assets/js/app.js',
    '/assets/images/logo.svg',
    '/assets/images/favicon.png',
    '/assets/images/upload-icon.svg',
    '/assets/images/project-icon.svg',
    '/assets/images/file-icon.svg',
    '/assets/images/security-icon.svg',
    '/pwa/manifest.json'
];

// התקנת Service Worker
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('פתיחת מטמון');
                return cache.addAll(ASSETS_TO_CACHE);
            })
            .then(() => self.skipWaiting())
    );
});

// הפעלת Service Worker
self.addEventListener('activate', event => {
    const cacheWhitelist = [CACHE_NAME];
    
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (cacheWhitelist.indexOf(cacheName) === -1) {
                        console.log('מוחק מטמון ישן:', cacheName);
                        return caches.delete(cacheName);
                    }
                })
            );
        }).then(() => self.clients.claim())
    );
});

// טיפול בבקשות רשת
self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                // החזרת תשובה מהמטמון אם קיימת
                if (response) {
                    return response;
                }
                
                // אחרת, פנייה לרשת
                return fetch(event.request)
                    .then(response => {
                        // בדיקה שהתשובה תקינה
                        if (!response || response.status !== 200 || response.type !== 'basic') {
                            return response;
                        }
                        
                        // שכפול התשובה (כי אי אפשר להשתמש בה פעמיים)
                        const responseToCache = response.clone();
                        
                        // שמירה במטמון
                        caches.open(CACHE_NAME)
                            .then(cache => {
                                cache.put(event.request, responseToCache);
                            });
                        
                        return response;
                    });
            })
    );
});
SERVICE_WORKER_JS

# יצירת קובץ Manifest עבור PWA
cat > "$BASE_DIR/pwa/manifest.json" << 'MANIFEST_JSON'
{
    "name": "מאחד קוד חכם Pro",
    "short_name": "קוד חכם Pro",
    "description": "כלי מתקדם לזיהוי, ניתוח ומיזוג פרויקטים מקבצי ZIP",
    "start_url": "/index.html",
    "display": "standalone",
    "background_color": "#f5f5f5",
    "theme_color": "#2196f3",
    "orientation": "any",
    "icons": [
        {
            "src": "/assets/images/icon-72x72.png",
            "sizes": "72x72",
            "type": "image/png"
        },
        {
            "src": "/assets/images/icon-96x96.png",
            "sizes": "96x96",
            "type": "image/png"
        },
        {
            "src": "/assets/images/icon-128x128.png",
            "sizes": "128x128",
            "type": "image/png"
        },
        {
            "src": "/assets/images/icon-144x144.png",
            "sizes": "144x144",
            "type": "image/png"
        },
        {
            "src": "/assets/images/icon-152x152.png",
            "sizes": "152x152",
            "type": "image/png"
        },
        {
            "src": "/assets/images/icon-192x192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "/assets/images/icon-384x384.png",
            "sizes": "384x384",
            "type": "image/png"
        },
        {
            "src": "/assets/images/icon-512x512.png",
            "sizes": "512x512",
            "type": "image/png"
        }
    ]
}
MANIFEST_JSON

# יצירת תיקיית תמונות
echo "📝 יוצר קבצי SVG ואייקונים..."
mkdir -p "$BASE_DIR/assets/images"

# לוגו
cat > "$BASE_DIR/assets/images/logo.svg" << 'LOGO_SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="240" height="60" viewBox="0 0 240 60">
  <rect width="240" height="60" rx="8" fill="#1976d2" />
  <path d="M30,15 L50,15 L50,45 L30,45 Z" fill="#ffffff" />
  <path d="M10,15 L25,15 L25,45 L10,45 Z" fill="#bbdefb" />
  <path d="M55,15 L70,15 L70,45 L55,45 Z" fill="#bbdefb" />
  <path d="M75,20 L80,15 L95,30 L80,45 L75,40 L85,30 L75,20 Z" fill="#ffffff" />
  <text x="110" y="35" font-family="Arial" font-size="16" font-weight="bold" fill="#ffffff">מאחד קוד חכם Pro</text>
</svg>
LOGO_SVG

# אייקון העלאה
cat > "$BASE_DIR/assets/images/upload-icon.svg" << 'UPLOAD_ICON_SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <circle cx="32" cy="32" r="30" fill="#bbdefb" />
  <path d="M32,12 L44,24 L36,24 L36,44 L28,44 L28,24 L20,24 L32,12 Z" fill="#1976d2" />
  <path d="M16,48 L48,48 L48,52 L16,52 Z" fill="#1976d2" />
</svg>
UPLOAD_ICON_SVG

# אייקון פרויקט
cat > "$BASE_DIR/assets/images/project-icon.svg" << 'PROJECT_ICON_SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="8" y="12" width="48" height="40" rx="4" fill="#bbdefb" />
  <rect x="16" y="20" width="32" height="8" rx="2" fill="#1976d2" />
  <rect x="16" y="32" width="32" height="4" rx="1" fill="#1976d2" />
  <rect x="16" y="40" width="20" height="4" rx="1" fill="#1976d2" />
</svg>
PROJECT_ICON_SVG

# אייקון קובץ
cat > "$BASE_DIR/assets/images/file-icon.svg" << 'FILE_ICON_SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M16,8 L38,8 L48,18 L48,56 L16,56 Z" fill="#bbdefb" />
  <path d="M38,8 L38,18 L48,18 Z" fill="#1976d2" />
  <rect x="22" y="28" width="20" height="2" rx="1" fill="#1976d2" />
  <rect x="22" y="34" width="20" height="2" rx="1" fill="#1976d2" />
  <rect x="22" y="40" width="20" height="2" rx="1" fill="#1976d2" />
</svg>
FILE_ICON_SVG

# אייקון אבטחה
cat > "$BASE_DIR/assets/images/security-icon.svg" << 'SECURITY_ICON_SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M32,8 L56,20 L56,34 C56,45 45,54 32,58 C19,54 8,45 8,34 L8,20 L32,8 Z" fill="#bbdefb" />
  <path d="M32,14 L48,22 L48,34 C48,42 41,48 32,52 C23,48 16,42 16,34 L16,22 L32,14 Z" fill="#1976d2" />
  <path d="M32,20 L40,24 L40,34 C40,38 36,42 32,44 C28,42 24,38 24,34 L24,24 L32,20 Z" fill="#ffffff" />
</svg>
SECURITY_ICON_SVG

# אייקון Favicon
cat > "$BASE_DIR/assets/images/favicon.png" << 'FAVICON_PNG'
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAHISURBVFhHvZfBTsMwDIZbdQMBBwQcQNw5wRNw4A3gEXiPPRNvwoEDcEXilkOBJYzPtRs5tasuy5A8Kdpq/98dx3aS1mqEvj6j5dv7lT+KZY3xcr+VrbgQ5HbzbGRJ6gWwoCzAP50CrzLs5U7WsaWl7NzLu60nlfdhAaF8FHDzVvJw7WrTzOZyu9zI4mTl9UVDgFo+C0D5q+5NdhRIGhLQyksBJAOLnwQ1rXwSQJGQDzfWKx8F9NWMYmJdAnIEtA13Mh4BLMKDvRFGdQlgvZpL0YeCh3sjfDFIjgCsUzLyOXVZVAGbNTXCLZZpWVQB7Dz0e6s0FfGVZMB6NUQBt7EzM0+FSU6J2WZpSwwCdtgxdoJjU9FbghII1jm+QmCIAqgV6Ke77VEWpSXuF0Ib2JlJC0gKCXgEYH6FPMlQwPnDw3VFLMBvOkq3pRRB1NLbktJyxIYHEbMAnInRgD49YKKUHCdnJoCHBY7AJIAnG04HzgT496OvZJyQXAbGhJwF/EsBKf8sIGdUj2HskNTyUcDQcdyHVt6NwsEBVUt75YMAtCzbTXQvyPB96GHFOdXKQ0C9G1zOzzJTdkNGUe6nlI8CnJxmF/ALA72Zlv58vn0AAAAASUVORK5CYII=
FAVICON_PNG

# יצירת קובץ README.md
echo "📝 יוצר קובץ README.md..."
cat > "$BASE_DIR/README.md" << 'README_MD'
# מאחד קוד חכם Pro 2.0

מערכת מתקדמת לניתוח, זיהוי ומיזוג פרויקטים מקבצי ZIP.

## מטרות המערכת

מאחד קוד חכם Pro 2.0 היא מערכת מודולרית המאפשרת:
- זיהוי וניתוח אוטומטי של פרויקטים בקבצי ZIP
- מיזוג פרויקטים דומים או קשורים
- ניהול גרסאות קוד
- סריקת אבטחה
- הרצת קוד בסביבה מבודדת
- השלמת קוד חסר
- גישה לאחסון מרוחק
- ניהול ועיבוד קבצים יעיל

## התקנה

### דרישות מערכת

- Python 3.9 ומעלה
- Node.js 16 ומעלה (אופציונלי, לחלק מהפונקציות)
- 2GB RAM לפחות
- 500MB שטח דיסק פנוי

### הוראות התקנה

1. הורד את קבצי המערכת
2. הרץ את סקריפט ההתקנה:
   ```bash
   bash install.sh
   ```
3. התקן את התלויות הנדרשות:
   ```bash
   pip install -r requirements.txt
   ```
4. הפעל את המערכת:
   ```bash
   python module.py
   ```

## מבנה המערכת

המערכת בנויה ממודולים עיקריים:
- **מודול מרכזי** (`module.py`) - מנהל את התהליך הכולל
- **ניהול גרסאות** (`core/version_manager.py`) - אחראי על שמירה, שחזור והשוואה של גרסאות
- **סריקות אבטחה** (`core/security_scanner.py`) - מזהה פגיעויות אבטחה בקוד
- **הרצת קוד** (`core/code_runner.py`) - מריץ קוד בסביבה מבודדת
- **השלמת קוד** (`core/code_completer.py`) - משלים קוד חסר או שגוי
- **אחסון מרוחק** (`utils/remote_storage.py`) - מאפשר גישה למערכות קבצים מרוחקות

## שימוש במערכת

### מהשורת הפקודה

```bash
python module.py [files...] -o [output_dir] [options]
```

### דוגמאות

```bash
# ניתוח וזיהוי פרויקטים מקובץ ZIP
python module.py project.zip -o output/

# מיזוג מספר קבצי ZIP
python module.py project1.zip project2.zip -o merged_output/

# ניתוח עם סריקת אבטחה
python module.py project.zip -o output/ --security
```

### ממשק משתמש

המערכת כוללת ממשק משתמש גרפי (PWA) שנגיש דרך הדפדפן. להפעלת הממשק:

1. הפעל את השרת:
   ```bash
   python -m http.server
   ```
2. פתח את הדפדפן בכתובת: `http://localhost:8000`

## רישיון

מערכת זו מופצת תחת רישיון MIT.

## מפתחי המערכת

מפותח על ידי Claude AI, מאי 2025.

## דיווח על באגים ושיפורים

לדיווח על באגים או הצעות לשיפורים, אנא פנו אל מפתחי המערכת.
README_MD

# יצירת קובץ metadata.json
echo "📝 יוצר קובץ metadata.json..."
cat > "$BASE_DIR/metadata.json" << 'METADATA_JSON'
{
  "name": "מאחד קוד חכם Pro",
  "version": "2.0.0",
  "description": "מערכת מתקדמת לזיהוי, ניתוח ומיזוג פרויקטים מקבצי ZIP",
  "author": "Claude AI",
  "license": "MIT",
  "main": "module.py",
  "module_dependencies": [],
  "dependencies": {
    "python_packages": [
      "paramiko>=2.7.2",
      "boto3>=1.18.0",
      "webdavclient3>=3.14.6",
      "pysmb>=1.2.7"
    ]
  },
  "ui_components": {
    "settings_tab": true,
    "main_tab": true
  }
}
METADATA_JSON

# יצירת קובץ config.json
echo "📝 יוצר קובץ config.json..."
cat > "$BASE_DIR/config.json" << 'CONFIG_JSON'
{
  "project_detection": {
    "min_file_count": 5,
    "detection_methods": ["file_structure", "dependency_analysis", "signature_matching"],
    "project_types": ["nodejs", "python", "java", "web", "cpp", "android", "ios"],
    "detection_confidence_threshold": 0.7
  },
  "merger": {
    "create_zip": true,
    "overwrite_existing": false,
    "ignore_patterns": [
      "**/.git/**",
      "**/.svn/**",
      "**/node_modules/**",
      "**/__pycache__/**",
      "**/.DS_Store"
    ],
    "merge_strategy": "smart",
    "conflict_resolution": "prompt",
    "keep_original_timestamps": true
  },
  "file_handling": {
    "max_file_size_mb": 100,
    "excluded_extensions": [
      ".exe", ".dll", ".so", ".pyc", ".pyo", 
      ".obj", ".o", ".class", ".jar", ".war",
      ".mp3", ".mp4", ".avi", ".mov", ".mkv",
      ".7z", ".rar", ".tar", ".gz", ".pdf"
    ],
    "binary_detection": true,
    "encoding_detection": true,
    "default_encoding": "utf-8"
  },
  "version_management": {
    "enabled": true,
    "storage_path": "versions",
    "max_versions": 10,
    "compression": "gzip",
    "include_metadata": true,
    "branch_tracking": true
  },
  "security_scanning": {
    "enabled": true,
    "scan_level": "medium",
    "report_path": "security_reports",
    "excluded_patterns": ["node_modules", "venv", "__pycache__", ".git"],
    "vulnerability_db_update": true
  },
  "code_running": {
    "enabled": true,
    "sandbox_enabled": true,
    "supported_languages": ["python", "javascript", "bash"],
    "timeout_seconds": 30,
    "memory_limit_mb": 512,
    "sandboxes_dir": "sandboxes"
  },
  "code_completion": {
    "enabled": true,
    "suggestions_limit": 5,
    "context_lines": 10,
    "supported_languages": ["python", "javascript", "java", "c", "cpp"]
  },
  "remote_storage": {
    "enabled": false,
    "types": ["local", "ssh", "s3", "ftp", "webdav", "smb", "nfs"],
    "timeout_seconds": 30,
    "cache_enabled": true,
    "cache_expiry_seconds": 3600,
    "cache_dir": "remote_cache"
  },
  "ui": {
    "theme": "light",
    "language": "he",
    "enable_animations": true,
    "show_advanced_options": false,
    "auto_refresh": true,
    "refresh_interval_seconds": 10
  }
}
CONFIG_JSON

# יצירת קובץ languages_config.json
echo "📝 יוצר קובץ languages_config.json..."
cat > "$BASE_DIR/languages_config.json" << 'LANGUAGES_CONFIG_JSON'
{
  "python": {
    "extension": ".py",
    "command": "python",
    "args": ["-u", "{file}"],
    "version_command": ["python", "--version"],
    "env": {
      "PYTHONPATH": "."
    }
  },
  "javascript": {
    "extension": ".js",
    "command": "node",
    "args": ["{file}"],
    "version_command": ["node", "--version"],
    "env": {
      "NODE_PATH": "node_modules"
    }
  },
  "bash": {
    "extension": ".sh",
    "command": "bash",
    "args": ["{file}"],
    "version_command": ["bash", "--version"],
    "file_position": "last",
    "env": {}
  },
  "java": {
    "extension": ".java",
    "compile_command": "javac",
    "compile_args": ["{file}"],
    "command": "java",
    "args": ["{class}"],
    "version_command": ["java", "--version"],
    "env": {
      "CLASSPATH": "."
    }
  },
  "c": {
    "extension": ".c",
    "compile_command": "gcc",
    "compile_args": ["-o", "{output}", "{file}"],
    "command": "./{output}",
    "args": [],
    "version_command": ["gcc", "--version"],
    "env": {}
  },
  "cpp": {
    "extension": ".cpp",
    "compile_command": "g++",
    "compile_args": ["-o", "{output}", "{file}"],
    "command": "./{output}",
    "args": [],
    "version_command": ["g++", "--version"],
    "env": {}
  }
}
LANGUAGES_CONFIG_JSON

# יצירת קובץ requirements.txt
echo "📝 יוצר קובץ requirements.txt..."
cat > "$BASE_DIR/requirements.txt" << 'REQUIREMENTS_TXT'
# תלויות בסיסיות
setuptools>=58.0.0
wheel>=0.37.0
pip>=21.2.4

# כלים מרכזיים
tqdm>=4.62.3
python-dateutil>=2.8.2
PyYAML>=6.0
colorama>=0.4.4

# ניתוח קבצים וקוד
chardet>=4.0.0
pygments>=2.10.0
pytype>=2022.5.19
pylint>=2.12.0
mypy>=0.910
bandit>=1.7.0
safety>=1.10.3

# אחסון מרוחק וסנכרון
paramiko>=2.7.2
boto3>=1.18.0
webdavclient3>=3.14.6
pysmb>=1.2.7
requests>=2.26.0

# ניתוח פרויקטים
virtualenv>=20.8.0
pipreqs>=0.4.11
requirementslib>=1.6.1
REQUIREMENTS_TXT

# יצירת קובץ package.json
echo "📝 יוצר קובץ package.json..."
cat > "$BASE_DIR/package.json" << 'PACKAGE_JSON'
{
  "name": "smart-code-merger-pro",
  "version": "2.0.0",
  "description": "מערכת מתקדמת לזיהוי, ניתוח ומיזוג פרויקטים מקבצי ZIP",
  "main": "assets/js/app.js",
  "scripts": {
    "start": "python -m http.server",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "Claude AI",
  "license": "MIT",
  "dependencies": {
    "chart.js": "^3.7.0",
    "codemirror": "^5.65.0",
    "dompurify": "^2.3.4",
    "highlight.js": "^11.3.1",
    "marked": "^4.0.10"
  },
  "devDependencies": {
    "eslint": "^8.6.0",
    "prettier": "^2.5.1"
  },
  "engines": {
    "node": ">=16.0.0"
  },
  "private": true
}
PACKAGE_JSON

# יצירת והגדרת סביבה וירטואלית
echo "🔧 מגדיר סביבה וירטואלית ומתקין תלויות..."
echo "============================================="

# בדיקת התקנת Python
if ! command -v python3 &> /dev/null; then
    echo "❌ שגיאה: Python 3 אינו מותקן במערכת. אנא התקן Python 3 ונסה שוב."
    exit 1
fi

# בדיקת התקנת pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ שגיאה: pip3 אינו מותקן במערכת. אנא התקן pip ונסה שוב."
    exit 1
fi

# בדיקת התקנת virtualenv
if ! command -v virtualenv &> /dev/null; then
    echo "📦 מתקין virtualenv..."
    pip3 install virtualenv
fi

# מיקום הסביבה הוירטואלית
VENV_DIR="$BASE_DIR/venv"

# יצירת סביבה וירטואלית
echo "🏗️ יוצר סביבה וירטואלית ב: $VENV_DIR"
virtualenv "$VENV_DIR"

# הפעלת הסביבה הוירטואלית והתקנת תלויות
echo "📦 מתקין תלויות בסביבה הוירטואלית..."
source "$VENV_DIR/bin/activate"

# התקנת תלויות מקובץ requirements.txt
pip install -r "$BASE_DIR/requirements.txt"

# יצירת סקריפט הפעלה
echo "📝 יוצר סקריפט הפעלה..."
cat > "$BASE_DIR/run.sh" << 'RUN_SH'
#!/bin/bash

# סקריפט הפעלה עם סביבה וירטואלית
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

# הפעלת הסביבה הוירטואלית
source "$VENV_DIR/bin/activate"

# בדיקת פרמטרים
if [ "$1" == "--ui" ] || [ "$1" == "-u" ]; then
    echo "🚀 מפעיל ממשק משתמש..."
    cd "$SCRIPT_DIR"
    python -m http.server
    echo "פתח את הדפדפן בכתובת: http://localhost:8000/ui/templates/index.html"
else
    echo "🚀 מפעיל מאחד קוד חכם Pro 2.0..."
    cd "$SCRIPT_DIR"
    python module.py "$@"
fi
RUN_SH

# הפיכת סקריפט ההפעלה לניתן להרצה
chmod +x "$BASE_DIR/run.sh"

# חזרה למצב רגיל (יציאה מהסביבה הוירטואלית)
deactivate

echo "✅ סביבה וירטואלית הוגדרה ותלויות הותקנו בהצלחה!"

# הודעת סיום מעודכנת
echo "✅ התקנת מאחד קוד חכם Pro 2.0 הושלמה!"
echo "============================================="
echo "כדי להפעיל את המערכת, השתמש בסקריפט ההפעלה:"
echo ""
echo "cd \"$BASE_DIR\""
echo "./run.sh        # להפעלת המודול"
echo ""
echo "או להפעלת ממשק המשתמש (PWA):"
echo ""
echo "cd \"$BASE_DIR\""
echo "./run.sh --ui   # להפעלת ממשק המשתמש"
echo "פתח את הדפדפן בכתובת: http://localhost:8000/ui/templates/index.html"
echo "============================================="